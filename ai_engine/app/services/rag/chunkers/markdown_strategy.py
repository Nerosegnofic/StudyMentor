from uuid import UUID
from langchain_text_splitters import MarkdownHeaderTextSplitter, RecursiveCharacterTextSplitter
from app.services.rag.chunkers.base import DocumentChunkerStrategy
from app.services.rag.processors import (
    ChunkClassifier,
    detect_chunk_role,
    extract_context_names,
    SequentialContextTracker,
)

class MarkdownRecursiveChunkerStrategy(DocumentChunkerStrategy):
    """
    Enhanced Markdown chunker with Content-Based Metadata and Parent-Child tagging.
    
    Pipeline:
        1. Split by Markdown headers (structure-aware, but we don't trust depth).
        2. Sub-split large sections with RecursiveCharacterTextSplitter.
        3. Classify each chunk (substantive vs structural).
        4. Detect chunk role from CONTENT (exercise, example, rule, etc.).
        5. Track sequential context (parent unit, concept, lesson).
    """
    def chunk(self, full_text: str, document_id: UUID) -> list:
        headers_to_split_on = [("#", "h1"), ("##", "h2"), ("###", "h3")]
        
        # 1. Split by Headers
        md_splitter = MarkdownHeaderTextSplitter(headers_to_split_on, strip_headers=False)
        md_chunks = md_splitter.split_text(full_text)
        
        # 2. Recursive fallback for large sections
        recursive_splitter = RecursiveCharacterTextSplitter(
            chunk_size=2000,
            chunk_overlap=200,
            separators=["\n\n", "\n", "۔", ".", "،", ",", " ", ""]
        )
        
        # 3. Sub-split and flatten
        all_sub_chunks = []
        for chunk in md_chunks:
            sub_chunks = recursive_splitter.split_documents([chunk])
            all_sub_chunks.extend(sub_chunks)
        
        # 4. Sequential context tracking + role detection + classification
        tracker = SequentialContextTracker()
        final_chunks = []
        
        for chunk in all_sub_chunks:
            text = chunk.page_content
            
            # a) Detect role from content (ignores header depth)
            role = detect_chunk_role(text)
            
            # b) Extract names (unit, concept, lesson) if this chunk is a header
            context_names = extract_context_names(text)
            
            # c) Update tracker and get inherited parent context
            parent_context = tracker.update_and_tag(role, context_names)
            
            # d) Classify (substantive vs structural)
            classification = ChunkClassifier.classify(text)
            
            # e) Merge all metadata
            chunk.metadata.update(classification)
            chunk.metadata.update(parent_context)
            chunk.metadata["document_id"] = str(document_id)
            
            final_chunks.append(chunk)
        
        # Summary stats
        roles = {}
        for c in final_chunks:
            r = c.metadata.get('chunk_role', 'unknown')
            roles[r] = roles.get(r, 0) + 1
        print(f"[{document_id}] Chunking complete: {len(final_chunks)} chunks.", flush=True)
        print(f"[{document_id}] Role breakdown: {roles}", flush=True)
                
        return final_chunks
