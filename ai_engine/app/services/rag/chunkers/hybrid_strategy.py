from uuid import UUID
from langchain_experimental.text_splitter import SemanticChunker
from langchain_text_splitters import MarkdownHeaderTextSplitter
from app.services.rag.chunkers.base import DocumentChunkerStrategy
from app.services.rag.processors import ChunkClassifier
from app.core.embeddings import RateLimitedCohereEmbeddings
from app.core.config import settings
from langchain_core.documents import Document

class HybridMarkdownSemanticStrategy(DocumentChunkerStrategy):
    """
    Advanced Chunker:
    1. Markdown Header Split (Preserves Structure)
    2. Semantic Split (AI-powered concept grouping)
    """
    
    def __init__(self):
        self.embeddings = RateLimitedCohereEmbeddings(
            cohere_api_key=settings.COHERE_API_KEY,
            model=settings.COHERE_EMBEDDING_MODEL
        )
        # We lower the threshold (70 -> 50) to make it MORE likely to split
        self.semantic_splitter = SemanticChunker(
            self.embeddings, 
            breakpoint_threshold_type="percentile",
            breakpoint_threshold_amount=50 
        )

    def chunk(self, full_text: str, document_id: UUID) -> list:
        print(f"--- DEBUG: Starting chunking for {document_id} ---", flush=True)
        print(f"--- DEBUG: Input text length: {len(full_text)} characters ---", flush=True)

        headers_to_split_on = [("#", "h1"), ("##", "h2"), ("###", "h3")]
        md_splitter = MarkdownHeaderTextSplitter(headers_to_split_on, strip_headers=False)
        md_sections = md_splitter.split_text(full_text)
        
        print(f"--- DEBUG: Markdown split into {len(md_sections)} sections ---", flush=True)
        
        if not md_sections:
            print("--- DEBUG: No headers found. Using raw text as single section. ---", flush=True)
            md_sections = [Document(page_content=full_text, metadata={})]

        final_chunks = []
        
        # BATCH PROCESSING (Avoids 'Batch 1/1' spam)
        try:
            print(f"--- DEBUG: Sending {len(md_sections)} sections to Semantic Chunker ---", flush=True)
            all_concept_chunks = self.semantic_splitter.split_documents(md_sections)
            print(f"--- DEBUG: Semantic Chunker produced {len(all_concept_chunks)} chunks ---", flush=True)
        except Exception as e:
            print(f"--- DEBUG: Semantic Chunker FAILED: {e} ---", flush=True)
            all_concept_chunks = md_sections

        # FALLBACK: If AI returned 0 chunks but input was not empty, use the original sections
        if len(all_concept_chunks) == 0 and len(full_text) > 0:
            print("--- DEBUG: Semantic Chunker returned 0. Falling back to raw sections. ---", flush=True)
            all_concept_chunks = md_sections

        for chunk in all_concept_chunks:
            # Classify (Substantive vs Structural)
            classification = ChunkClassifier.classify(chunk.page_content)
            chunk.metadata.update(classification)
            chunk.metadata["document_id"] = str(document_id)
            final_chunks.append(chunk)
                
        print(f"--- DEBUG: Final chunk count: {len(final_chunks)} ---", flush=True)
        return final_chunks
