import os
import tempfile
import re
from uuid import UUID

from app.services.rag.parsers.context import ParserContext
from app.services.rag.parsers.llama_strategy import LlamaParseStrategy
from app.services.rag.chunkers.context import ChunkerContext
from app.services.rag.chunkers.semantic_strategy import SemanticChunkerStrategy
from app.services.rag.chunkers.hybrid_strategy import HybridMarkdownSemanticStrategy
from app.services.rag.chunkers.basic_strategy import BasicRecursiveChunkerStrategy
from app.services.rag.chunkers.markdown_strategy import MarkdownRecursiveChunkerStrategy
from app.services.rag.store import save_chunks_to_pgvector, delete_document_embeddings, clear_all_embeddings

parser_context = ParserContext(strategy=LlamaParseStrategy())
chunker_context = ChunkerContext(strategy=MarkdownRecursiveChunkerStrategy())

def preprocess_parsed_text(text: str) -> str:
    cleaned_lines = []
    # Patterns for noise (page numbers, standalone figure labels)
    noise_patterns = [
        re.compile(r'^#+\s*\d+\s*$'), 
        re.compile(r'^#+\s*(Figure|Fig|Table)\s*\d*', re.IGNORECASE)
    ]
    
    for line in text.split('\n'):
        stripped = line.strip()
        if stripped.startswith('#') and any(p.match(stripped) for p in noise_patterns):
            cleaned_lines.append(stripped.lstrip('#').strip()) # Demote to plain text
        else:
            cleaned_lines.append(line) # PRESERVE real headers
    return '\n'.join(cleaned_lines)

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
        # full_text = parser_context.execute_parse(document_id, temp_file_path)

        document_id = UUID("a5977ed0-601b-4490-9473-43696d49dfe2")
        with open("debug_a5977ed0-601b-4490-9473-43696d49dfe2.md", "r", encoding="utf-8") as f:
            cleaned_text = f.read()

        # Preprocess text to clean artifacts
        # cleaned_text = preprocess_parsed_text(full_text)
        
        # with open(f"debug_{document_id}.md", "w", encoding="utf-8") as f:
        #     f.write(cleaned_text)

        clear_all_embeddings()
            
        # Step 2: Chunk
        langchain_docs = chunker_context.execute_chunking(cleaned_text, document_id)
        
        # Step 3: Store
        save_chunks_to_pgvector(langchain_docs, document_id)
            
    finally:
        if os.path.exists(temp_file_path):
            os.remove(temp_file_path)

# Expose delete_document_embeddings at the package root level
__all__ = ["process_and_ingest_document", "delete_document_embeddings"]
