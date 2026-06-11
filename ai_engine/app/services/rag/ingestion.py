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
        print("=" * 60, flush=True)
        print(f"[INGESTION START] Ingesting document: {filename} (ID: {document_id})", flush=True)
        print(f" -> Subject ID: {subject_id} | Student UID: {firebase_uid}", flush=True)
        print("=" * 60, flush=True)

        with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as temp_file:
            temp_file.write(file_content)
            temp_file_path = temp_file.name

        try:
            # Step 1: Parse PDF
            print(f"[1/6] Sending PDF to LlamaParse (converting layout to Markdown)...", flush=True)
            full_text = parser_context.execute_parse(document_id, temp_file_path, subject_name=subject_name)
            print(f" -> Success. Extracted {len(full_text)} characters of raw Markdown.", flush=True)
            
            # Step 2: Preprocess text
            print(f"[2/6] Cleaning text and removing layout noise...", flush=True)
            cleaned_text = preprocess_parsed_text(full_text)
            print(f" -> Cleaned text size: {len(cleaned_text)} characters.", flush=True)

            # Step 3: Regex Objective Extraction
            print(f"[3/6] Extracting raw curriculum objectives using regular expressions...", flush=True)
            raw_mastery_data = extract_all_objectives(cleaned_text)
            print(f" -> Found {len(raw_mastery_data)} raw units/lessons.", flush=True)
            for item in raw_mastery_data:
                print(f"    - Unit: {item.get('unit_title', 'General')}", flush=True)
                for lesson in item.get('lessons', []):
                    print(f"      - Lesson: {lesson.get('lesson_title')}", flush=True)
            
            # Step 4: Chunking
            print(f"[4/6] Chunking text into semantically recursive Markdown documents...", flush=True)
            langchain_docs = chunker_context.execute_chunking(cleaned_text, document_id)
            print(f" -> Generated {len(langchain_docs)} chunks.", flush=True)

            # Step 5: Refine via Gemini LLM (before pgvector so chunks can be tagged)
            print(f"[5/6] Refining objectives using Gemini LLM to compile granular skills...", flush=True)
            refined_mastery_data = None
            if raw_mastery_data:
                refined_mastery_data = refine_mastery_points(raw_mastery_data, cleaned_text)

            # Tag chunks with skill_names from mastery data (improves RAG precision)
            active_mastery_data = refined_mastery_data if refined_mastery_data else raw_mastery_data
            if active_mastery_data:
                lesson_to_skills = {}
                for entry in active_mastery_data:
                    lesson = entry.get("lesson_name", "") or entry.get("lesson", "")
                    skills = entry.get("skills", [])
                    if lesson and skills:
                        skill_names = [s["name"] if isinstance(s, dict) else str(s) for s in skills]
                        lesson_to_skills[lesson] = skill_names

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

            # Step 6: Save Vector Embeddings (with skill-tagged chunks)
            print(f"[6/6] Generating Cohere vector embeddings and saving to PGVector...", flush=True)
            save_chunks_to_pgvector(langchain_docs, document_id, firebase_uid=firebase_uid, subject_id=subject_id)
            print(" -> Chunks successfully saved to database.", flush=True)

            if raw_mastery_data:
                # Only save if refinement produced different data (not a fallback)
                if refined_mastery_data:
                    print(f" -> Success! Gemini generated {len(refined_mastery_data)} refined items.", flush=True)
                    for item in refined_mastery_data:
                        print(f"    - Unit: {item.get('unit_title')}", flush=True)
                        for lesson in item.get('lessons', []):
                            print(f"      - Lesson: {lesson.get('lesson_title')}", flush=True)
                            for skill in lesson.get('skills', []):
                                print(f"        * Skill: {skill}", flush=True)
                    
                    print(" -> Saving refined skills to PostgreSQL...", flush=True)
                    save_skills_from_mastery_data(db, refined_mastery_data, subject_id=subject_id)
                else:
                    print(" -> Gemini refinement failed or returned empty. Saving raw objectives...", flush=True)
                    save_skills_from_mastery_data(db, raw_mastery_data, subject_id=subject_id)
            else:
                print(" -> No raw objectives extracted. Ingestion complete.", flush=True)

            print("=" * 60, flush=True)
            print(f"[INGESTION SUCCESS] Document {filename} ingested successfully!", flush=True)
            print("=" * 60, flush=True)
                
        finally:
            if os.path.exists(temp_file_path):
                os.remove(temp_file_path)
    finally:
        db.close()

# Expose public interface
__all__ = ["process_and_ingest_document"]
