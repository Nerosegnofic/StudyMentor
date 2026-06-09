#!/usr/bin/env python3
"""
CLI tool to run the curriculum PDF ingestion pipeline manually.
Displays console logs for parsing, preprocessing, objective extraction, chunking, and LLM refinement.
"""
import os
import sys
import argparse
import uuid

# Add current folder to sys.path for app module imports
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

# Load environmental variables from config
from app.core.config import settings

def main():
    parser = argparse.ArgumentParser(description="Ingest curriculum PDF textbook into StudyMentor RAG database.")
    parser.add_argument("pdf_path", help="Path to the PDF file on your computer.")
    parser.add_argument("--subject", required=True, help="Name of the subject (e.g., 'Math', 'Science').")
    parser.add_argument("--student-uid", required=True, help="Firebase student UID to link this curriculum to.")
    
    args = parser.parse_args()
    
    if not os.path.exists(args.pdf_path):
        print(f"Error: File '{args.pdf_path}' does not exist.")
        sys.exit(1)
        
    print("=" * 60)
    print("           STUDYMENTOR CURRICULUM INGESTION CLI           ")
    print("=" * 60)
    print(f"File:    {args.pdf_path}")
    print(f"Subject: {args.subject}")
    print(f"Student: {args.student_uid}")
    print("-" * 60)
    
    # Import pipeline elements
    from app.core.database import SessionLocal
    from app.models.domain.curriculum import Subject as SubjectModel
    from app.services.rag.parsers.context import ParserContext
    from app.services.rag.parsers.llama_strategy import LlamaParseStrategy
    from app.services.rag.chunkers.context import ChunkerContext
    from app.services.rag.chunkers.markdown_strategy import MarkdownRecursiveChunkerStrategy
    from app.repositories.vector_repo import save_chunks_to_pgvector
    from app.repositories import save_skills_from_mastery_data
    from app.services.rag.processors.objective_extractor import extract_all_objectives
    from app.services.rag.processors.mastery_refiner import refine_mastery_points
    from app.services.rag.preprocessors import preprocess_parsed_text
    
    db = SessionLocal()
    document_id = uuid.uuid4()
    
    try:
        # Step 0: Ensure Subject exists in database
        print("[1/7] Checking database subject records...")
        subject = db.query(SubjectModel).filter(
            SubjectModel.name == args.subject,
            SubjectModel.student_uid == args.student_uid
        ).first()
        
        if not subject:
            print(f" -> Subject '{args.subject}' not found for student. Creating new entry...")
            subject = SubjectModel(name=args.subject, student_uid=args.student_uid, is_global=False)
            db.add(subject)
            db.commit()
            db.refresh(subject)
        print(f" -> Done. Subject ID: {subject.subject_id}")
        print("-" * 40)
        
        # Step 1: Parse PDF
        print("[2/7] Sending PDF to LlamaParse (converting layout to Markdown)...")
        parser_context = ParserContext(strategy=LlamaParseStrategy())
        raw_markdown = parser_context.execute_parse(document_id, args.pdf_path)
        print(f" -> Success. Extracted {len(raw_markdown)} characters of raw Markdown.")
        print("-" * 40)
        
        # Step 2: Preprocess text
        print("[3/7] Cleaning text and removing layout noise...")
        cleaned_text = preprocess_parsed_text(raw_markdown)
        print(" -> Done.")
        print("-" * 40)
        
        # Step 3: Regex Objective Extraction
        print("[4/7] Extracting raw objectives and lessons using regular expressions...")
        raw_mastery_data = extract_all_objectives(cleaned_text)
        print(f" -> Found {len(raw_mastery_data)} raw curriculum nodes.")
        for item in raw_mastery_data:
            print(f"    • Unit: {item.get('unit_title', 'General')}")
            for lesson in item.get('lessons', []):
                print(f"      - Lesson: {lesson.get('lesson_title')}")
                for skill in lesson.get('skills', []):
                    print(f"        * Skill: {skill}")
        print("-" * 40)
        
        # Step 4: Chunking
        print("[5/7] Chunking text into semantically recursive Markdown documents...")
        chunker_context = ChunkerContext(strategy=MarkdownRecursiveChunkerStrategy())
        langchain_docs = chunker_context.execute_chunking(cleaned_text, document_id)
        print(f" -> Generated {len(langchain_docs)} text chunks.")
        print("-" * 40)
        
        # Step 5: Save Vector Embeddings
        print("[6/7] Generating Cohere vector embeddings and saving to PGVector...")
        save_chunks_to_pgvector(
            langchain_docs, 
            document_id, 
            firebase_uid=args.student_uid, 
            subject_id=subject.subject_id
        )
        print(" -> Chunks successfully stored in PostgreSQL.")
        print("-" * 40)
        
        # Step 6: Refine Mastery Points using Gemini LLM
        print("[7/7] Refining curriculum objectives using Gemini LLM to compile granular skills...")
        if raw_mastery_data:
            refined_mastery_data = refine_mastery_points(raw_mastery_data, cleaned_text)
            
            if refined_mastery_data:
                print(f" -> Success! LLM generated {len(refined_mastery_data)} refined nodes.")
                for item in refined_mastery_data:
                    print(f"    • Unit: {item.get('unit_title')}")
                    for lesson in item.get('lessons', []):
                        print(f"      - Lesson: {lesson.get('lesson_title')}")
                        for skill in lesson.get('skills', []):
                            print(f"        * Refined Skill: {skill}")
                
                print(" -> Saving refined skills to DB...")
                save_skills_from_mastery_data(db, refined_mastery_data, subject_id=subject.subject_id)
            else:
                print(" -> LLM Refinement skipped or failed. Falling back to raw regex objectives...")
                save_skills_from_mastery_data(db, raw_mastery_data, subject_id=subject.subject_id)
        else:
            print(" -> No raw objectives found. Skipping refinement.")
            
        print("=" * 60)
        print("                 INGESTION PIPELINE COMPLETE!             ")
        print("=" * 60)
        
    except Exception as e:
        print(f"\n[!] Critical Error: Ingestion failed: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
    finally:
        db.close()

if __name__ == "__main__":
    main()
