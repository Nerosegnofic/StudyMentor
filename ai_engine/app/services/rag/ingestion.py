import os
import tempfile
from uuid import UUID

from app.services.rag.parsers.context import ParserContext
from app.services.rag.parsers.llama_strategy import LlamaParseStrategy
from app.services.rag.chunkers.context import ChunkerContext
from app.services.rag.chunkers.markdown_strategy import MarkdownRecursiveChunkerStrategy
from app.services.rag.store import save_chunks_to_pgvector, delete_document_embeddings

parser_context = ParserContext(strategy=LlamaParseStrategy())
chunker_context = ChunkerContext(strategy=MarkdownRecursiveChunkerStrategy())

def process_and_ingest_document(document_id: UUID, file_content: bytes, filename: str):
    """
    Orchestrates the RAG ingestion pipeline:
    1. Saves temp PDF
    2. Parsers -> extracts Markdown
    3. Chunkers -> splits Markdown into LangChain docs
    4. Store -> saves docs to PGVector
    """
    suffix = os.path.splitext(filename)[1]
    with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as temp_file:
        temp_file.write(file_content)
        temp_file_path = temp_file.name

    try:
        # Step 1: Parse
        full_text = parser_context.execute_parse(document_id, temp_file_path)
        
        # Step 2: Chunk
        langchain_docs = chunker_context.execute_chunking(full_text, document_id)
        
        # Step 3: Store
        save_chunks_to_pgvector(langchain_docs, document_id)
            
    finally:
        if os.path.exists(temp_file_path):
            os.remove(temp_file_path)

# Expose delete_document_embeddings at the package root level
__all__ = ["process_and_ingest_document", "delete_document_embeddings"]
