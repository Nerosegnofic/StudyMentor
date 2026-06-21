import glob
import os
import tempfile
from uuid import UUID

from app.services.rag.parsers.context import ParserContext
from app.services.rag.parsers.llama_strategy import LlamaParseStrategy
from app.services.rag.chunkers.context import ChunkerContext
from app.services.rag.chunkers.markdown_strategy import MarkdownRecursiveChunkerStrategy
from app.repositories.vector_repo import save_chunks_to_pgvector
from app.repositories import save_skills_from_mastery_data, document_repo
from app.services.rag.processors.objective_extractor import extract_all_objectives
from app.services.rag.processors.mastery_refiner import extract_skills_with_llm, refine_mastery_points
from app.services.rag.processors.language_detector import (
    detect_language,
    dominant_language,
    guess_language_from_subject_name,
)
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

            # Step 1: Parse (two-pass, content-verified).
            # Pass 1 uses the subject-name language guess; the parser's no-translate
            # prompts mean a wrong guess can only lower OCR quality, never flip the
            # language. We then verify against the parsed content and re-parse ONCE in
            # the correct mode when the guess was clearly wrong (this owns the cost of
            # the extra LlamaParse call here, in the orchestrator, not in the parser).
            document_repo.set_stage(db, document_id, "parsing")
            initial_lang = guess_language_from_subject_name(subject_name)
            full_text = parser_context.execute_parse(document_id, temp_file_path, language=initial_lang)

            detected_lang = dominant_language(full_text, threshold=0.70)
            if detected_lang and detected_lang != initial_lang:
                print(
                    f"[{document_id}] Pass-1 language guess '{initial_lang}' conflicts with "
                    f"detected '{detected_lang}'. Re-parsing once in '{detected_lang}' mode...",
                    flush=True,
                )
                corrected = parser_context.execute_parse(document_id, temp_file_path, language=detected_lang)
                if corrected.strip():
                    full_text = corrected

            # Optional: to read from cache instead of re-parsing
            # with open(f"debug_output/{document_id}_parsed.md", "r", encoding="utf-8") as f:
            #     full_text = f.read()

            # Step 2: Preprocess text to clean artifacts
            cleaned_text = preprocess_parsed_text(full_text)

            # Record the authoritative content language for downstream quiz generation.
            document_language = detect_language(cleaned_text)
            document_repo.set_detected_metadata(db, document_id, language=document_language)
            
            # DEBUG DUMP 1: Parsed & Cleaned Text
            with open(f"{debug_prefix}_parsed.md", "w", encoding="utf-8") as f:
                f.write(cleaned_text)

            # Step 3: Extract Mastery Points (regex-based, zero API cost)
            document_repo.set_stage(db, document_id, "analyzing")
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


            # Step 5: Extract skills. PRIMARY = LLM reads the full cleaned markdown
            # (general across any subject/language). FALLBACK = regex output refined
            # by the LLM, used only when the primary path is unavailable / fails.
            mastery_source = "llm"
            final_mastery_data, detected_subject = extract_skills_with_llm(cleaned_text)
            if not final_mastery_data:
                mastery_source = "regex"
                detected_subject = None  # regex fallback can't classify the subject
                final_mastery_data = (
                    refine_mastery_points(raw_mastery_data, cleaned_text)
                    if raw_mastery_data else []
                )

            # Persist the content-classified subject (a hint; used downstream alongside
            # the parent's label). Only the primary LLM path produces it.
            if detected_subject:
                document_repo.set_detected_metadata(db, document_id, subject=detected_subject)

            skill_count = sum(len(e.get("objectives", [])) for e in final_mastery_data)
            print(f"[{document_id}] Skill extraction source={mastery_source}, "
                  f"{skill_count} skills across {len(final_mastery_data)} groups.", flush=True)

            # DEBUG DUMP 4: Final Skills
            if final_mastery_data:
                with open(f"{debug_prefix}_refined_skills.json", "w", encoding="utf-8") as f:
                    json.dump(final_mastery_data, f, indent=4, ensure_ascii=False)

            # Step 6: Tag chunks with skill_names from mastery data (for precision retrieval)
            # Build a lesson → skill_names mapping from the extracted mastery data.
            active_mastery_data = final_mastery_data
            if active_mastery_data:
                lesson_to_skills = {}
                for entry in active_mastery_data:
                    lesson = entry.get("lesson", "")
                    skills = entry.get("objectives", [])
                    if lesson and skills:
                        skill_names = [str(s) for s in skills]
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
            document_repo.set_stage(db, document_id, "building_skills")
            save_chunks_to_pgvector(langchain_docs, document_id, firebase_uid=firebase_uid, subject_id=subject_id)

            # Step 8: Save skills to DB
            if final_mastery_data:
                save_skills_from_mastery_data(db, final_mastery_data, subject_id=subject_id)

            # Mark the upload as fully ingested (clear the in-flight stage).
            document_repo.set_stage(db, document_id, None)
            document_repo.set_status(db, document_id, "ready")

        except Exception as e:
            print(f"[{document_id}] Ingestion failed: {e}", flush=True)
            try:
                document_repo.set_status(db, document_id, "failed")
            except Exception:
                pass  # status update is best-effort; don't mask the original error
            raise
        finally:
            if os.path.exists(temp_file_path):
                os.remove(temp_file_path)
    finally:
        db.close()


def ingest_then_warm(
    document_id: UUID,
    file_content: bytes,
    filename: str,
    subject_id: int = 1,
    firebase_uid: str = None,
    subject_name: str = "",
) -> None:
    """
    Background-task entrypoint: run the ingestion pipeline, then — only on success —
    pre-warm the just-ingested subject's first quiz.

    This keeps `process_and_ingest_document` single-responsibility (PDF → curriculum +
    skills): it is run untouched, and the "after a subject becomes ready" hook lives
    here in the orchestrator. We warm ONLY the subject that just became ready — its
    subject_id is known, so there's no need to fan out to other subjects (those are
    already warm, or get warmed by their own trigger). `warm_first_quiz_for_subject`
    opens/closes its own short-lived session (the request session is gone by now) and is
    best-effort — it never raises. If ingestion fails it raises, so the warm is skipped.
    """
    process_and_ingest_document(
        document_id=document_id,
        file_content=file_content,
        filename=filename,
        subject_id=subject_id,
        firebase_uid=firebase_uid,
        subject_name=subject_name,
    )

    # Imported lazily to avoid a circular import (quiz layer imports repositories that
    # would otherwise pull this module in at import time).
    from app.services.quiz.quiz_generation_service import warm_first_quiz_for_subject

    warm_first_quiz_for_subject(firebase_uid, subject_id)


def delete_debug_artifacts(document_id: UUID) -> None:
    """
    Best-effort removal of a document's on-disk debug dumps (test-only artifacts).
    Never raises — a missing file/directory is fine.
    """
    try:
        for path in glob.glob(f"debug_output/{document_id}_*"):
            try:
                os.remove(path)
            except OSError:
                pass
    except Exception:
        pass


# Expose public interface
__all__ = ["process_and_ingest_document", "delete_debug_artifacts"]
