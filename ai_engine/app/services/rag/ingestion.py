import os
import tempfile
from uuid import UUID

from app.services.rag.parsers.context import ParserContext
from app.services.rag.parsers.llama_strategy import LlamaParseStrategy
from app.services.rag.chunkers.context import ChunkerContext
from app.services.rag.chunkers.markdown_strategy import MarkdownRecursiveChunkerStrategy
from app.repositories.vector_repo import save_chunks_to_pgvector
from app.repositories import save_skills_from_mastery_data
from app.services.rag.processors.objective_extractor import extract_all_objectives
from app.services.rag.processors.mastery_refiner import refine_mastery_points
from app.services.rag.preprocessors import preprocess_parsed_text
from app.core.database import SessionLocal

parser_context = ParserContext(strategy=LlamaParseStrategy())
chunker_context = ChunkerContext(strategy=MarkdownRecursiveChunkerStrategy())

def process_and_ingest_document(document_id: UUID, file_content: bytes, filename: str, subject_id: int = 1):
    """
    Orchestrates the RAG ingestion pipeline:
    1. Parse PDF -> Markdown
    2. Preprocess text (clean noise)
    3. Extract Mastery Points via regex
    4. Chunk -> LangChain docs
    5. Store -> PGVector + Mastery Points DB
    """
    suffix = os.path.splitext(filename)[1]
    db = SessionLocal()
    try:
        with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as temp_file:
            temp_file.write(file_content)
            temp_file_path = temp_file.name

        try:
            # Step 1: Parse
            full_text = parser_context.execute_parse(document_id, temp_file_path)
            
            # Step 2: Preprocess text to clean artifacts
            cleaned_text = preprocess_parsed_text(full_text)
            
            # Step 3: Extract Mastery Points (regex-based, zero API cost)
            raw_mastery_data = extract_all_objectives(cleaned_text)
            
            # Step 4: Chunk
            langchain_docs = chunker_context.execute_chunking(cleaned_text, document_id)
            
            # Step 5: Store Vector Embeddings
            save_chunks_to_pgvector(langchain_docs, document_id)
            
            # Step 6a: Populate Skills from raw regex extraction
            if raw_mastery_data:
                save_skills_from_mastery_data(db, raw_mastery_data, subject_id=subject_id)
            
            # Step 6b: Refine via Gemini LLM — overwrite skills with better granularity
            if raw_mastery_data:
                refined_mastery_data = refine_mastery_points(raw_mastery_data, cleaned_text)
                # Only save if refinement produced different data (not a fallback)
                if refined_mastery_data is not raw_mastery_data:
                    save_skills_from_mastery_data(db, refined_mastery_data, subject_id=subject_id)
                
        finally:
            if os.path.exists(temp_file_path):
                os.remove(temp_file_path)
    finally:
        db.close()

# Expose public interface
__all__ = ["process_and_ingest_document"]
