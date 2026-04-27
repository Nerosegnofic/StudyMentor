import os
import tempfile
import re
from typing import List, Dict
from uuid import UUID

from app.services.rag.parsers.context import ParserContext
from app.services.rag.parsers.llama_strategy import LlamaParseStrategy
from app.services.rag.chunkers.context import ChunkerContext
from app.services.rag.chunkers.markdown_strategy import MarkdownRecursiveChunkerStrategy
from app.services.rag.store import save_chunks_to_pgvector, save_mastery_points, delete_document_embeddings, clear_all_embeddings
from app.services.rag.processors.objective_extractor import extract_all_objectives

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
    1. Parse PDF -> Markdown
    2. Preprocess text (clean noise)
    3. Extract Mastery Points via regex
    4. Chunk -> LangChain docs
    5. Store -> PGVector + Mastery Points DB
    """
    suffix = os.path.splitext(filename)[1]
    with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as temp_file:
        temp_file.write(file_content)
        temp_file_path = temp_file.name

    try:
        # Step 1: Parse
        full_text = parser_context.execute_parse(document_id, temp_file_path)
        
        # For local debugging:
        # document_id = UUID("a5977ed0-601b-4490-9473-43696d49dfe2")
        # with open(f"debug_{document_id}.md", "r", encoding="utf-8") as f:
        #     cleaned_text = f.read()
        
        # Preprocess text to clean artifacts
        cleaned_text = preprocess_parsed_text(full_text)
        
        with open(f"debug_{document_id}.md", "w", encoding="utf-8") as f:
            f.write(cleaned_text)

        # Step 3: Extract Mastery Points (regex-based, zero API cost)
        mastery_data = extract_all_objectives(cleaned_text)
        
        # Step 4: Clear old data and re-ingest
        clear_all_embeddings()
        
        # Step 5: Chunk
        langchain_docs = chunker_context.execute_chunking(cleaned_text, document_id)
        
        # Step 6: Store Vector Embeddings
        save_chunks_to_pgvector(langchain_docs, document_id)
        
        # Step 7: Store Mastery Points
        if mastery_data:
            save_mastery_points(mastery_data, document_id)
            
    finally:
        if os.path.exists(temp_file_path):
            os.remove(temp_file_path)

# Expose delete_document_embeddings at the package root level
__all__ = ["process_and_ingest_document", "delete_document_embeddings"]
