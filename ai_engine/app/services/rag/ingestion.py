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
from app.services.rag.processors.mastery_refiner import refine_mastery_points

parser_context = ParserContext(strategy=LlamaParseStrategy())
chunker_context = ChunkerContext(strategy=MarkdownRecursiveChunkerStrategy())

def preprocess_parsed_text(text: str) -> str:
    cleaned_lines = []
    # Patterns for noise (page numbers, standalone figure labels)
    noise_patterns = [
        re.compile(r'^#+\s*\d+\s*$'), 
        re.compile(r'^#+\s*(Figure|Fig|Table)\s*\d*', re.IGNORECASE)
    ]
    # Footer patterns: "123 | الدرس الأول: ..." or "الدرس الأول: ... 45"
    footer_patterns = [
        # Page number before pipe: "79 | الدرس الخامس: ..."
        re.compile(r'^\d{1,3}\s*\|\s*الدرس.+$'),
        # Page number at end of line after lesson ref: "الدرس الثالث: ... 73"
        re.compile(r'^الدرس.+\s+\d{1,3}\s*$'),
    ]
    
    for line in text.split('\n'):
        stripped = line.strip()
        if stripped.startswith('#') and any(p.match(stripped) for p in noise_patterns):
            cleaned_lines.append(stripped.lstrip('#').strip()) # Demote to plain text
        elif any(p.match(stripped) for p in footer_patterns):
            cleaned_lines.append('')  # Remove footer lines entirely
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
        # full_text = parser_context.execute_parse(document_id, temp_file_path)
        
        # For local debugging:
        document_id = UUID("7d44415d-1f5a-404e-aaac-4850e62923a1")

        with open(f"debug_{document_id}.md", "r", encoding="utf-8") as f:
            full_text = f.read()
            
        document_id = UUID("8d44415d-1f5a-404e-aaac-4850e62923a1")
        
        # Preprocess text to clean artifacts
        cleaned_text = preprocess_parsed_text(full_text)
        
        with open(f"debug_{document_id}.md", "w", encoding="utf-8") as f:
            f.write(cleaned_text)

        # Step 3: Extract Mastery Points (regex-based, zero API cost)
        raw_mastery_data = extract_all_objectives(cleaned_text)
        
        # Step 4: Clear old data and re-ingest
        clear_all_embeddings()
        
        # Step 5: Chunk
        langchain_docs = chunker_context.execute_chunking(cleaned_text, document_id)
        
        # Step 6: Store Vector Embeddings
        save_chunks_to_pgvector(langchain_docs, document_id)
        
        # Step 7a: Store Raw Mastery Points (regex-extracted, always available)
        if raw_mastery_data:
            save_mastery_points(raw_mastery_data, document_id, source="regex")
        
        # Step 7b: Refine via Gemini LLM and store refined points
        if raw_mastery_data:
            refined_mastery_data = refine_mastery_points(raw_mastery_data, cleaned_text)
            # Only save if refinement produced different data (not a fallback)
            if refined_mastery_data is not raw_mastery_data:
                save_mastery_points(refined_mastery_data, document_id, source="llm_refined")
            
    finally:
        if os.path.exists(temp_file_path):
            os.remove(temp_file_path)

# Expose delete_document_embeddings at the package root level
__all__ = ["process_and_ingest_document", "delete_document_embeddings"]
