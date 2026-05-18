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

def process_and_ingest_document(
    document_id: UUID, 
    file_content: bytes, 
    filename: str, 
    subject_id: int = 1,
    firebase_uid: str = None
):
    """
    Orchestrates the RAG ingestion pipeline:
    1. Parse PDF -> Markdown
    2. Preprocess text (clean noise)
    3. Extract Mastery Points via regex
    4. Chunk -> LangChain docs
    5. Store -> PGVector + Mastery Points DB

    - `firebase_uid`: If provided, tags the vector embeddings with user ownership.
    """
    suffix = os.path.splitext(filename)[1]
    db = SessionLocal()
    try:
        with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as temp_file:
            temp_file.write(file_content)
            temp_file_path = temp_file.name

        try:
            # DEBUG: DUMP FILES
            # import json
            # os.makedirs("debug_output", exist_ok=True)
            # debug_prefix = f"debug_output/{document_id}"

            full_text = parser_context.execute_parse(document_id, temp_file_path)

            # with open("debug_output/c3e44b6c-ad89-40c9-af83-4935cfcd9da9_parsed.md", "r", encoding="utf-8") as f:
            #     full_text = f.read()
            
            # Step 2: Preprocess text to clean artifacts
            cleaned_text = preprocess_parsed_text(full_text)
            
            # DEBUG DUMP 1: Parsed & Cleaned Text
            # with open(f"{debug_prefix}_parsed.md", "w", encoding="utf-8") as f:
            #     f.write(cleaned_text)

            # Step 3: Extract Mastery Points (regex-based, zero API cost)
            raw_mastery_data = extract_all_objectives(cleaned_text)

            # DEBUG DUMP 2: Raw Skills
            # with open(f"{debug_prefix}_raw_skills.json", "w", encoding="utf-8") as f:
            #     json.dump(raw_mastery_data, f, indent=4, ensure_ascii=False)
            
            # Step 4: Chunk
            langchain_docs = chunker_context.execute_chunking(cleaned_text, document_id)
            
            # DEBUG DUMP 3: Chunks
            # with open(f"{debug_prefix}_chunks.json", "w", encoding="utf-8") as f:
            #     chunks_dump = [{"page_content": d.page_content, "metadata": d.metadata} for d in langchain_docs]
            #     json.dump(chunks_dump, f, indent=4, ensure_ascii=False)

            # Step 5: Store Vector Embeddings
            save_chunks_to_pgvector(langchain_docs, document_id, firebase_uid=firebase_uid, subject_id=subject_id)
            
            # Step 6: Refine via Gemini LLM — overwrite skills with better granularity
            if raw_mastery_data:
                refined_mastery_data = refine_mastery_points(raw_mastery_data, cleaned_text)
                
                # DEBUG DUMP 4: Refined Skills
                # with open(f"{debug_prefix}_refined_skills.json", "w", encoding="utf-8") as f:
                #     json.dump(refined_mastery_data, f, indent=4, ensure_ascii=False)
                
                # Only save if refinement produced different data (not a fallback)
                if refined_mastery_data:
                    save_skills_from_mastery_data(db, refined_mastery_data, subject_id=subject_id)
                else:
                    save_skills_from_mastery_data(db, raw_mastery_data, subject_id=subject_id)
                
        finally:
            if os.path.exists(temp_file_path):
                os.remove(temp_file_path)
    finally:
        db.close()

# Expose public interface
__all__ = ["process_and_ingest_document"]
