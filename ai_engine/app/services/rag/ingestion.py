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
    firebase_uid: str = None,
    subject_name: str = "",
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
            import json
            os.makedirs("debug_output", exist_ok=True)
            debug_prefix = f"debug_output/{document_id}"

            full_text = parser_context.execute_parse(document_id, temp_file_path, subject_name=subject_name)

            # Optional: to read from cache instead of re-parsing
            # with open(f"debug_output/{document_id}_parsed.md", "r", encoding="utf-8") as f:
            #     full_text = f.read()
            
            # Step 2: Preprocess text to clean artifacts
            cleaned_text = preprocess_parsed_text(full_text)
            
            # DEBUG DUMP 1: Parsed & Cleaned Text
            with open(f"{debug_prefix}_parsed.md", "w", encoding="utf-8") as f:
                f.write(cleaned_text)

            # Step 3: Extract Mastery Points (regex-based, zero API cost)
            raw_mastery_data = extract_all_objectives(cleaned_text)

            # DEBUG DUMP 2: Raw Skills
            with open(f"{debug_prefix}_raw_skills.json", "w", encoding="utf-8") as f:
                json.dump(raw_mastery_data, f, indent=4, ensure_ascii=False)
            
            # Step 4: Chunk
            langchain_docs = chunker_context.execute_chunking(cleaned_text, document_id)
            
            # DEBUG DUMP 3: Chunks
            with open(f"{debug_prefix}_chunks.json", "w", encoding="utf-8") as f:
                chunks_dump = [{"page_content": d.page_content, "metadata": d.metadata} for d in langchain_docs]
                json.dump(chunks_dump, f, indent=4, ensure_ascii=False)


            # Step 5: Refine mastery points via Gemini LLM (needed before tagging and saving)
            refined_mastery_data = None
            if raw_mastery_data:
                refined_mastery_data = refine_mastery_points(raw_mastery_data, cleaned_text)
            
            # DEBUG DUMP 4: Refined Skills
            if refined_mastery_data:
                with open(f"{debug_prefix}_refined_skills.json", "w", encoding="utf-8") as f:
                    json.dump(refined_mastery_data, f, indent=4, ensure_ascii=False)

            # Step 6: Tag chunks with skill_names from mastery data (for precision retrieval)
            # Build a lesson → skill_names mapping from refined (or raw) mastery data
            active_mastery_data = refined_mastery_data if refined_mastery_data else raw_mastery_data
            if active_mastery_data:
                lesson_to_skills = {}
                for entry in active_mastery_data:
                    lesson = entry.get("lesson_name", "") or entry.get("lesson", "")
                    skills = entry.get("skills", [])
                    if lesson and skills:
                        skill_names = [s["name"] if isinstance(s, dict) else str(s) for s in skills]
                        lesson_to_skills[lesson] = skill_names

                # Tag each chunk with its lesson's skills
                tagged_count = 0
                for chunk in langchain_docs:
                    parent_lesson = chunk.metadata.get("parent_lesson", "")
                    if parent_lesson:
                        for lesson_key, skill_list in lesson_to_skills.items():
                            if lesson_key in parent_lesson or parent_lesson in lesson_key:
                                chunk.metadata["skill_names"] = skill_list
                                tagged_count += 1
                                break
                if tagged_count > 0:
                    print(f"[{document_id}] Tagged {tagged_count}/{len(langchain_docs)} chunks with skill_names.", flush=True)

            # Step 7: Store Vector Embeddings
            save_chunks_to_pgvector(langchain_docs, document_id, firebase_uid=firebase_uid, subject_id=subject_id)
            
            # Step 8: Save skills to DB
            if raw_mastery_data:
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
