from fastapi import HTTPException
from sqlalchemy.orm import Session

from app.models.schemas import GenerateQuizRequest, GenerateQuizResponse, QuestionSchema
from app.models.domain import Question
from app.repositories import (
    get_priority_subject,
    get_subject_by_id,
    get_active_quiz_session,
    get_questions_for_session,
    get_skills_by_names,
    create_quiz_session,
    upsert_student_subject_profile_last_quizzed,
    save_questions,
)
from app.services.quiz.builder import build_quiz_payload
from app.services.rag.retrieval import retrieve_context_for_quiz
from app.services.rag.generation.context import GeneratorContext
from app.services.rag.generation.gemini_strategy import GeminiStrategy
from app.services.quiz.quiz_bank_service import build_quiz_from_bank
from app.core.exceptions import LLMGenerationError, QuizBankInsufficientError, InsufficientContextError
from app.services.quiz.quiz_utils import (
    generate_variance_block,
    get_recent_question_fingerprints,
    shuffle_question_options,
    build_difficulty_map,
    filter_mismatched_questions,
)

DIFFICULTY_LABELS = {1: "Very Easy", 2: "Easy", 3: "Medium", 4: "Hard", 5: "Very Hard"}

GRADE_LABELS = {
    1: "1st", 2: "2nd", 3: "3rd", 4: "4th", 5: "5th", 6: "6th",
    7: "7th", 8: "8th", 9: "9th", 10: "10th", 11: "11th", 12: "12th",
}

generator_context = GeneratorContext(strategy=GeminiStrategy())


def generate_quiz_for_student(
    db: Session,
    request_body: GenerateQuizRequest,
    student_uid: str,
) -> GenerateQuizResponse:
    # ------------------------------------------------------------------ #
    # Step 0: Determine the Subject
    # ------------------------------------------------------------------ #
    if request_body.subject_id is None:
        subject = get_priority_subject(db, student_uid)
        if not subject:
            raise HTTPException(
                status_code=404,
                detail="No subjects with skills found. Please upload curriculum documents first."
            )
    else:
        subject = get_subject_by_id(db, request_body.subject_id)
        if not subject:
            raise HTTPException(
                status_code=404,
                detail=f"Subject with ID {request_body.subject_id} not found."
            )

    target_subject_id = subject.subject_id
    target_subject_name = subject.name

    # Resolve grade label for prompt (e.g., 5 → "5th")
    student_grade_label = GRADE_LABELS.get(request_body.student_grade, f"{request_body.student_grade}th")

    # ------------------------------------------------------------------ #
    # Step 0.5: Quiz Cache Check (Cross-Device Reuse)
    # ------------------------------------------------------------------ #
    active_session = get_active_quiz_session(db, student_uid, target_subject_id)
    if active_session:
        cached_questions = get_questions_for_session(db, active_session.session_id)
        if cached_questions and all(q.text_content is not None for q in cached_questions):
            print(
                f"[QuizCache] Returning cached session {active_session.session_id} "
                f"for student={student_uid}, subject_id={target_subject_id}",
                flush=True,
            )
            question_schemas = [
                QuestionSchema(
                    question_id=str(q.question_id),
                    topic=q.skill.name if q.skill else "General",
                    question_text=q.text_content,
                    options=q.options,
                    correct_answer=q.correct_answer,
                    explanation=q.explanation or "",
                    difficulty=int(q.difficulty),
                    hints=q.hints or [],
                )
                for q in cached_questions
            ]
            return GenerateQuizResponse(
                quiz_session_id=str(active_session.session_id),
                selected_subject_id=target_subject_id,
                selected_subject_name=target_subject_name,
                quiz_title=f"اختبار {target_subject_name}",
                questions=question_schemas,
                quiz_source="CACHED",
            )

    # ------------------------------------------------------------------ #
    # Step 1+2: Build quiz payload via Ordered Frontier + SRS
    # ------------------------------------------------------------------ #
    payload = build_quiz_payload(
        db, student_uid, target_subject_id,
        request_body.total_questions, request_body.student_grade
    )
    if not payload:
        raise HTTPException(
            status_code=400,
            detail="Could not allocate questions. No skills found for this subject."
        )

    instruction_lines = []
    all_topics = []
    for cfg in payload:
        label = DIFFICULTY_LABELS.get(cfg["difficulty"], "Medium")
        zone_tag = cfg.get('zone', 'frontier').upper()
        instruction_lines.append(
            f"- Topic: {cfg['skill']} | Difficulty: {cfg['difficulty']} ({label}) "
            f"| Questions: {cfg['count']} | Zone: {zone_tag}"
        )
        all_topics.append(cfg["skill"])

    topic_instructions = "\n".join(instruction_lines)
    difficulty_map = build_difficulty_map(payload)

    # ------------------------------------------------------------------ #
    # Step 3: Create Quiz Session
    # ------------------------------------------------------------------ #
    quiz_session = create_quiz_session(db, student_uid, target_subject_id, request_body.total_questions)
    upsert_student_subject_profile_last_quizzed(db, student_uid, target_subject_id)

    skills_used = get_skills_by_names(db, all_topics)
    skill_name_to_id = {s.name: s.skill_id for s in skills_used}

    # ------------------------------------------------------------------ #
    # Step 4: Try LLM generation → fallback to bank → fallback to 503
    # ------------------------------------------------------------------ #
    quiz_source = "FRESH"
    db_questions = []

    try:
        context = retrieve_context_for_quiz(
            payload,
            k=15,
            firebase_uid=student_uid,
            subject_id=target_subject_id,
        )

        variance_block = generate_variance_block()

        recent_fps = get_recent_question_fingerprints(db, student_uid, target_subject_id)
        if recent_fps:
            avoidance_instructions = (
                "\n\n⚠️ PREVIOUSLY ASKED QUESTIONS (DO NOT REPEAT):\n"
                + "\n".join(f'  - "{fp}..."' for fp in list(recent_fps)[:15])
                + "\n\nGenerate COMPLETELY DIFFERENT questions with different numbers, names, and scenarios."
            )
            context = context + avoidance_instructions

        try:
            import os
            os.makedirs("debug_output", exist_ok=True)
            debug_path = f"debug_output/quiz_generation_{quiz_session.session_id}.txt"
            with open(debug_path, "w", encoding="utf-8") as f:
                f.write("==================================================\n")
                f.write("QUIZ GENERATION DEBUG REPORT\n")
                f.write("==================================================\n\n")

                f.write("1. SKILLS PICKED FOR QUIZ\n")
                f.write("-" * 50 + "\n")
                for idx, skill in enumerate(all_topics, 1):
                    f.write(f"  {idx}. {skill}\n")
                f.write("\n")

                f.write("2. PAYLOAD DETAILS & MASTERY LEVELS\n")
                f.write("-" * 50 + "\n")
                for cfg in payload:
                    skill_name = cfg['skill']
                    mastery = cfg.get('mastery', 'N/A')
                    zone = cfg.get('zone', 'unknown')
                    f.write(f"  • Skill: {skill_name}\n")
                    f.write(f"    - Zone: {zone}\n")
                    f.write(f"    - Requested Difficulty: {cfg['difficulty']}\n")
                    f.write(f"    - Question Count: {cfg['count']}\n")
                    f.write(f"    - Current Mastery Level: {mastery}\n\n")

                f.write("3. FETCHED CHUNKS (RAG Context)\n")
                f.write("-" * 50 + "\n")
                if not context:
                    f.write("  [No chunks fetched]\n")
                else:
                    f.write(f"{context}\n\n")

        except Exception as e:
            print(f"[Debug] Failed to write to {debug_path}: {e}")

        response = generator_context.execute_generation(
            topic_instructions=topic_instructions,
            total_count=request_body.total_questions,
            context=context,
            student_grade=student_grade_label,
            variance_block=variance_block,
        )

        accepted_questions, dropped_count = filter_mismatched_questions(
            response.questions, difficulty_map, tolerance=1
        )
        total_generated = len(response.questions)
        mismatch_ratio = dropped_count / total_generated if total_generated > 0 else 0.0

        if mismatch_ratio > 0.20:
            print(
                f"[DifficultyGuard] {mismatch_ratio:.0%} of questions mismatched "
                f"({dropped_count}/{total_generated}). Retrying LLM generation...",
                flush=True,
            )
            response = generator_context.execute_generation(
                topic_instructions=topic_instructions,
                total_count=request_body.total_questions,
                context=context,
                student_grade=student_grade_label,
                variance_block=variance_block,
            )
            accepted_questions, dropped_count = filter_mismatched_questions(
                response.questions, difficulty_map, tolerance=1
            )
            if dropped_count > 0:
                print(
                    f"[DifficultyGuard] Retry still dropped {dropped_count} mismatched questions. Proceeding.",
                    flush=True,
                )

        for q in accepted_questions:
            shuffled = shuffle_question_options(q)
            skill_id = skill_name_to_id.get(shuffled.topic, 1)
            db_questions.append(Question(
                question_id=shuffled.question_id,
                skill_id=skill_id,
                session_id=quiz_session.session_id,
                text_content=shuffled.question_text,
                options=shuffled.options,
                correct_answer=shuffled.correct_answer,
                difficulty=shuffled.difficulty,
                source_enum="AI",
                explanation=shuffled.explanation,
                hints=shuffled.hints,
            ))

    except (LLMGenerationError, InsufficientContextError) as llm_err:
        print(f"[QuizGenerate] LLM/context failed: {llm_err}. Attempting quiz bank fallback.", flush=True)
        try:
            db_questions = build_quiz_from_bank(
                db=db,
                student_uid=student_uid,
                subject_id=target_subject_id,
                quiz_payload=payload,
                new_session_id=quiz_session.session_id,
            )
            quiz_source = "BANK"
            # It's better not to use the response object if fallback succeeds
            # so we'll construct the quiz_title safely later
        except QuizBankInsufficientError:
            db.rollback()
            raise HTTPException(
                status_code=503,
                detail=(
                    "خدمة توليد الاختبارات غير متاحة مؤقتاً. "
                    "يرجى المحاولة مرة أخرى لاحقاً."
                )
            )

    # ------------------------------------------------------------------ #
    # Step 5: Persist and return
    # ------------------------------------------------------------------ #
    quiz_session.total_questions = len(db_questions)
    save_questions(db, db_questions)
    db.commit()

    return_questions = []
    for q in db_questions:
        skill_name = next(
            (name for name, sid in skill_name_to_id.items() if sid == q.skill_id),
            "General"
        )
        return_questions.append(QuestionSchema(
            question_id=str(q.question_id),
            topic=skill_name,
            question_text=q.text_content,
            options=q.options,
            correct_answer=q.correct_answer,
            explanation=q.explanation or "",
            difficulty=int(q.difficulty),
            hints=q.hints or [],
        ))

    # In Python, if we hit the bank fallback we won't have `response.quiz_title`
    # So we should conditionally assign it
    quiz_title = f"اختبار {target_subject_name}"
    if quiz_source == "FRESH" and 'response' in locals():
        quiz_title = response.quiz_title

    return GenerateQuizResponse(
        quiz_session_id=str(quiz_session.session_id),
        selected_subject_id=target_subject_id,
        selected_subject_name=target_subject_name,
        quiz_title=quiz_title,
        questions=return_questions,
        quiz_source=quiz_source,
    )
