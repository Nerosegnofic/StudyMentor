from uuid import UUID
from langchain_text_splitters import MarkdownHeaderTextSplitter, RecursiveCharacterTextSplitter
from app.core.config import settings
from app.services.rag.chunkers.base import DocumentChunkerStrategy
from app.services.rag.processors import (
    ChunkClassifier,
    detect_chunk_role,
    extract_context_names,
    is_garbage_chunk,
    SequentialContextTracker,
)

class MarkdownRecursiveChunkerStrategy(DocumentChunkerStrategy):
    """
    Enhanced Markdown chunker with Content-Based Metadata and Parent-Child tagging.
    
    Pipeline:
        1. Split by Markdown headers (structure-aware, but we don't trust depth).
        2. Sub-split large sections with RecursiveCharacterTextSplitter.
        3. Merge adjacent small chunks to prevent context fragmentation.
        4. Classify each chunk (substantive vs structural).
        5. Detect chunk role from CONTENT (exercise, example, rule, etc.).
        6. Track sequential context (parent unit, concept, lesson).
        7. Filter garbage chunks (CamScanner artifacts, orphaned headers).
    """
    # Minimum number of characters for a chunk to stand on its own.
    # Smaller chunks get merged with the next chunk. Sourced from config (default 350)
    # so it stays tunable alongside the other chunking sizes; behavior is unchanged.
    MIN_CHUNK_SIZE = settings.CHUNK_MIN_SIZE

    def chunk(self, full_text: str, document_id: UUID) -> list:
        headers_to_split_on = [("#", "h1"), ("##", "h2"), ("###", "h3")]
        
        # 1. Split by Headers
        md_splitter = MarkdownHeaderTextSplitter(headers_to_split_on, strip_headers=False)
        md_chunks = md_splitter.split_text(full_text)
        
        # 2. Recursive fallback for large sections.
        #    Generic content uses plain prose separators. Exercise/example sections
        #    use an ITEM-AWARE splitter (P2): a worked example or numbered exercise
        #    must not be cut between a question and its answer. We prefer item
        #    boundaries (numbered/bulleted items, "مثال"/"Example", "تمرين"/"Exercise")
        #    as split points, falling back to prose separators only if a single item
        #    is still too big. These sections also get more headroom so a long worked
        #    example stays intact. detect_chunk_role runs BEFORE splitting here so it
        #    can protect boundaries, not just label them after the fact.
        recursive_splitter = RecursiveCharacterTextSplitter(
            chunk_size=settings.CHUNK_SIZE,
            chunk_overlap=settings.CHUNK_OVERLAP,
            separators=["\n\n", "\n", "۔", ".", "،", ",", " ", ""]
        )
        item_aware_splitter = RecursiveCharacterTextSplitter(
            chunk_size=settings.EXERCISE_CHUNK_SIZE,
            chunk_overlap=settings.CHUNK_OVERLAP,
            separators=[
                # Item boundaries first (regex): keep each problem/example whole.
                r"\n#+\s*(?:مثال|تمرين|Example|Exercise)\s*\(?\s*\d*",  # headed items
                r"\n\s*(?:مثال|تمرين|Example|Exercise)\s*\(?\s*\d+",     # inline items
                r"\n\s*\d+\s*[.)\-]\s",                                  # 1.  2)  3-
                r"\n\s*[-*•]\s",                                          # bullets
                # Then generic prose separators as fallback (escaped: literal under
                # regex mode, so "." stays a period and doesn't match any char).
                "\n\n", "\n", "۔", r"\.", "،", ",", " ", "",
            ],
            is_separator_regex=True,
        )

        # 3. Sub-split and flatten. Pick the splitter by the section's content role.
        all_sub_chunks = []
        for chunk in md_chunks:
            role = detect_chunk_role(chunk.page_content)
            splitter = item_aware_splitter if role in ('exercise', 'example') else recursive_splitter
            sub_chunks = splitter.split_documents([chunk])
            all_sub_chunks.extend(sub_chunks)
        
        # 4. Merge adjacent small chunks to prevent context fragmentation.
        #    A 40-char chunk like "### الدرس الثاني: المتغيرات" alone is too
        #    short for meaningful embedding. Merging it with the next chunk
        #    preserves context locality and improves retrieval quality.
        #
        #    BOUNDARY GUARD: never merge ACROSS a lesson/unit boundary. If the
        #    incoming chunk is itself a lesson_header/unit_header, flush the
        #    accumulator and start fresh — even when it's still under
        #    MIN_CHUNK_SIZE. A tiny orphaned header chunk is the lesser evil vs.
        #    a chunk straddling two lessons (which would mis-tag parent_lesson and
        #    cross-contaminate retrieval). The signal is the content-derived
        #    ROLE, not raw h1/h2 presence: real books have many non-boundary
        #    h1/h2 headers ("# نشاط 2", "# ابدأ", "## الأهداف") that must NOT
        #    trigger a flush, or every lesson would shatter into fragments.
        merged_chunks = []
        accumulator = None
        for chunk in all_sub_chunks:
            if accumulator is None:
                accumulator = chunk
                continue

            is_boundary = detect_chunk_role(chunk.page_content) in ('lesson_header', 'unit_header')
            combined_len = len(accumulator.page_content) + len(chunk.page_content)
            if (not is_boundary
                    and len(accumulator.page_content) < self.MIN_CHUNK_SIZE
                    and combined_len <= settings.CHUNK_MERGE_MAX_SIZE):
                # Merge: combine text, keep metadata from the first chunk
                accumulator.page_content = accumulator.page_content + "\n\n" + chunk.page_content
                # Inherit any new header metadata from the merged chunk
                for key in ('h1', 'h2', 'h3'):
                    if key in chunk.metadata and key not in accumulator.metadata:
                        accumulator.metadata[key] = chunk.metadata[key]
            else:
                merged_chunks.append(accumulator)
                accumulator = chunk
        if accumulator is not None:
            merged_chunks.append(accumulator)
        
        merge_count = len(all_sub_chunks) - len(merged_chunks)
        if merge_count > 0:
            print(f"[{document_id}] Merged {merge_count} small chunks ({len(all_sub_chunks)} → {len(merged_chunks)}).", flush=True)
        
        # 5. Sequential context tracking + role detection + classification
        tracker = SequentialContextTracker()
        final_chunks = []
        garbage_count = 0
        
        for chunk in merged_chunks:
            text = chunk.page_content
            
            # a) Classify first to get word_count
            classification = ChunkClassifier.classify(text)
            word_count = classification.get('word_count', 0)
            
            # b) Filter garbage chunks
            if is_garbage_chunk(text, word_count):
                garbage_count += 1
                continue
            
            # c) Detect role from content (ignores header depth)
            role = detect_chunk_role(text)
            
            # d) Extract names (unit, concept, lesson) if this chunk is a header
            context_names = extract_context_names(text)
            
            # e) Pass markdown headers as fallback for lesson detection
            md_headers = {
                k: v for k, v in chunk.metadata.items()
                if k in ('h1', 'h2', 'h3')
            }
            
            # f) Update tracker and get inherited parent context
            parent_context = tracker.update_and_tag(role, context_names, md_headers)
            
            # g) Merge all metadata
            chunk.metadata.update(classification)
            chunk.metadata.update(parent_context)
            chunk.metadata["document_id"] = str(document_id)
            
            final_chunks.append(chunk)
        
        # Summary stats
        roles = {}
        for c in final_chunks:
            r = c.metadata.get('chunk_role', 'unknown')
            roles[r] = roles.get(r, 0) + 1
        print(f"[{document_id}] Chunking complete: {len(final_chunks)} chunks ({garbage_count} garbage filtered).", flush=True)
        print(f"[{document_id}] Role breakdown: {roles}", flush=True)
                
        return final_chunks
