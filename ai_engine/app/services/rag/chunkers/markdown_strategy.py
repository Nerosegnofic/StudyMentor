from uuid import UUID
from langchain_text_splitters import MarkdownHeaderTextSplitter, RecursiveCharacterTextSplitter
from app.services.rag.chunkers.base import DocumentChunkerStrategy

class MarkdownRecursiveChunkerStrategy(DocumentChunkerStrategy):
    def chunk(self, full_text: str, document_id: UUID) -> list:
        headers_to_split_on = [
            ("#", "Unit"),
            ("##", "Concept"),
            ("###", "Lesson")
        ]
        markdown_splitter = MarkdownHeaderTextSplitter(
            headers_to_split_on=headers_to_split_on,
            strip_headers=False 
        )
        lesson_chunks = markdown_splitter.split_text(full_text)
        
        text_splitter = RecursiveCharacterTextSplitter(
            chunk_size=800,
            chunk_overlap=200,
            separators=["\n\n", "\n", ".", " ", ""]
        )
        langchain_docs = text_splitter.split_documents(lesson_chunks)
        
        for doc in langchain_docs:
            doc.metadata["document_id"] = str(document_id)
            
        return langchain_docs
