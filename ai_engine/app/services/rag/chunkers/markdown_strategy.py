from uuid import UUID
from langchain_text_splitters import MarkdownHeaderTextSplitter, RecursiveCharacterTextSplitter
from app.services.rag.chunkers.base import DocumentChunkerStrategy
from app.services.rag.chunkers.classifier import ChunkClassifier

class MarkdownRecursiveChunkerStrategy(DocumentChunkerStrategy):
    """
    A strategy that first splits by Markdown headers (H1, H2, H3) to maintain context,
    then sub-splits large sections using a recursive character splitter.
    Finally, it classifies each chunk as 'substantive' or 'structural' for better RAG.
    """
    def chunk(self, full_text: str, document_id: UUID) -> list:
        headers_to_split_on = [("#", "h1"), ("##", "h2"), ("###", "h3")]
        
        # 1. Split by Headers
        md_splitter = MarkdownHeaderTextSplitter(headers_to_split_on, strip_headers=False)
        md_chunks = md_splitter.split_text(full_text)
        
        # 2. Recursive fallback for large sections
        # Increased chunk_size to 1500 to keep more instructional context together
        recursive_splitter = RecursiveCharacterTextSplitter(
            chunk_size=2000,
            chunk_overlap=200,
            separators=["\n\n", "\n", "۔", ".", "،", ",", " ", ""]
        )
        
        final_chunks = []
        for chunk in md_chunks:
            # Sub-split large markdown sections
            sub_chunks = recursive_splitter.split_documents([chunk])
            
            # 3. Enrich each chunk with Generic Classification Metadata
            for sub_chunk in sub_chunks:
                classification = ChunkClassifier.classify(sub_chunk.page_content)
                sub_chunk.metadata.update(classification)
                final_chunks.append(sub_chunk)
                
        return final_chunks
