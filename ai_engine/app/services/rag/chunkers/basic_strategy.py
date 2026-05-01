from uuid import UUID
from langchain_core.documents import Document
from langchain_text_splitters import RecursiveCharacterTextSplitter
from app.services.rag.chunkers.base import DocumentChunkerStrategy

class BasicRecursiveChunkerStrategy(DocumentChunkerStrategy):
    """
    Fallback chunker for flat text lacking Markdown headers.
    """
    def chunk(self, full_text: str, document_id: UUID) -> list:
        text_splitter = RecursiveCharacterTextSplitter(
            chunk_size=800,
            chunk_overlap=200,
            separators=["\n\n", "\n", ".", " ", ""]
        )
        # Create a single Langchain document from string before splitting
        doc = Document(page_content=full_text, metadata={"document_id": str(document_id)})
        langchain_docs = text_splitter.split_documents([doc])
        return langchain_docs
