import sys
import os
import json
from datetime import datetime

# Allow running from the repo root
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app.core.database import SessionLocal
from app.core.auth import init_firebase
from app.models.domain.gamification import StudentGamification
from app.models.domain.curriculum import Subject
from app.repositories.analytics_repo import get_all_student_skill_states
from app.repositories.skill_repo import get_skills_by_subject_id
from app.services.quiz.builder import build_quiz_payload
from app.services.rag.retrieval import retrieve_context_for_topics
from app.services.rag.generation import GeneratorContext
from app.services.rag.generation.gemini_strategy import GeminiStrategy
from app.core.exceptions import LLMGenerationError, InsufficientContextError

def main():
    print("==================================================")
    print("        STUDYMENTOR QUIZ GENERATION CLI          ")
    print("==================================================")
    
    # 1. Initialize Firebase and Session
    print("\n[1/5] Initializing database session & Firebase...")
    try:
        init_firebase()
    except Exception as e:
        print(f"Warning: Firebase Admin init warning: {e}")
        
    db = SessionLocal()
    
    # 2. Select Student
    print("\n[2/5] Fetching students from database...")
    students = db.query(StudentGamification).all()
    if not students:
        print("No students found in the database. Using fallback/test student UID: 'test-student-uid'")
        student_uid = "test-student-uid"
    else:
        print("Available Students:")
        for idx, s in enumerate(students):
            print(f"  {idx + 1}. UID: {s.student_uid} | XP: {s.xp_total} | Coins: {s.coins_total}")
        
        choice = input(f"\nSelect a student (1-{len(students)}) [Default: 1]: ").strip()
        if choice.isdigit() and 1 <= int(choice) <= len(students):
            student_uid = students[int(choice) - 1].student_uid
        else:
            student_uid = students[0].student_uid
            
    print(f"Selected Student UID: {student_uid}")

    # 3. Select Subject
    print("\n[3/5] Fetching subjects...")
    subjects = db.query(Subject).all()
    if not subjects:
        print("Error: No subjects found in the database. Please upload/ingest curriculum documents first.")
        sys.exit(1)
        
    print("Available Subjects:")
    for idx, sub in enumerate(subjects):
        print(f"  {idx + 1}. ID: {sub.subject_id} | Name: {sub.name}")
        
    choice = input(f"\nSelect a subject (1-{len(subjects)}) [Default: 1]: ").strip()
    if choice.isdigit() and 1 <= int(choice) <= len(subjects):
        selected_subject = subjects[int(choice) - 1]
    else:
        selected_subject = subjects[0]
        
    print(f"Selected Subject: {selected_subject.name} (ID: {selected_subject.subject_id})")

    # Ask for total questions
    questions_input = input("\nEnter number of questions to generate [Default: 5]: ").strip()
    total_questions = int(questions_input) if questions_input.isdigit() else 5

    # Select Strategy
    print("\nSelect Generator Strategy:")
    print("  1. Gemini (Default - gemini-2.5-flash)")
    print("  2. Cohere (command-r-08-2024)")
    strategy_choice = input("Select strategy (1-2) [Default: 1]: ").strip()
    if strategy_choice == "2":
        from app.services.rag.generation.cohere_strategy import CohereStrategy
        strategy = CohereStrategy()
        strategy_name = "Cohere"
    else:
        strategy = GeminiStrategy()
        strategy_name = "Gemini"

    # 4. Allocate topics based on BKT
    print("\n[4/5] Running Bayesian Knowledge Tracing (BKT) topic allocation...")
    student_profile = get_all_student_skill_states(db, student_uid)
    if not student_profile:
        print("No BKT skill states found for this student. Fetching all skills under this subject...")
        all_skills = get_skills_by_subject_id(db, selected_subject.subject_id)
        student_profile = {skill.name: 0.01 for skill in all_skills}
        
    if not student_profile:
        print("No skills defined in this subject yet. Please ingest curriculum.")
        sys.exit(1)
        
    payload = build_quiz_payload(student_profile, total_questions)
    if not payload:
        print("Error: Could not allocate questions based on profile.")
        sys.exit(1)
        
    print("\nAllocated Topics:")
    instruction_lines = []
    all_topics = []
    DIFFICULTY_LABELS = {1: "Very Easy", 2: "Easy", 3: "Medium", 4: "Hard", 5: "Very Hard"}
    for cfg in payload:
        label = DIFFICULTY_LABELS.get(cfg["difficulty"], "Medium")
        line = f"- Topic: {cfg['skill']} | Difficulty: {cfg['difficulty']} ({label}) | Count: {cfg['count']}"
        print(line)
        instruction_lines.append(line)
        all_topics.append(cfg["skill"])
        
    topic_instructions = "\n".join(instruction_lines)

    # 5. RAG Retrieval & LLM Generation
    print("\n[5/5] Invoking PGVector RAG retrieval & LLM generation...")
    try:
        # RAG Context Retrieval
        print("  -> Retrieving textbook chunks for topics from PGVector...")
        context = retrieve_context_for_topics(
            all_topics,
            k=10,
            firebase_uid=student_uid,
            subject_id=selected_subject.subject_id,
        )
        print(f"  -> Successfully retrieved context ({len(context)} chars).")
        
        # LLM Generation
        print(f"  -> Generating questions using {strategy_name} Strategy (watch output below)...")
        generator_context = GeneratorContext(strategy=strategy)
        response = generator_context.execute_generation(
            topic_instructions=topic_instructions,
            total_count=total_questions,
            context=context,
        )
        
        print("\n==================================================")
        print("          GENERATED QUIZ QUESTIONS                ")
        print("==================================================")
        for idx, q in enumerate(response.questions):
            print(f"\nQ{idx + 1}: {q.question_text}")
            print(f"Topic: {q.topic} | Difficulty: {q.difficulty}")
            print("Options:")
            for opt_key, opt_val in q.options.items():
                print(f"  [{opt_key}] {opt_val}")
            print(f"Correct Answer: {q.correct_answer}")
            print(f"Explanation: {q.explanation}")
            if q.hints:
                print(f"Hints: {q.hints}")
                
    except InsufficientContextError as ice:
        print(f"\n[Error] Context retrieval failed: {ice}")
        print("Please ensure you have uploaded and ingested curriculum PDFs for this subject!")
    except LLMGenerationError as lge:
        print(f"\n[Error] LLM Generation failed: {lge}")
    except Exception as e:
        print(f"\n[Error] An unexpected error occurred: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    main()
