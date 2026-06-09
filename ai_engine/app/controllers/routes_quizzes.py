from datetime import datetime
from fastapi import APIRouter, HTTPException, Depends, Request
from sqlalchemy.orm import Session
from app.models.schemas import (
    GenerateQuizRequest,
    GenerateQuizResponse,
    QuestionSchema,
    QuizSubmissionRequest,
    QuizSubmissionResponse,
)
from app.models.domain.quiz import QuizSession as QuizSessionModel
from app.core.rate_limit import limiter
from app.core.config import settings
from app.services.rag.retrieval import retrieve_context_for_topics
from app.services.rag.generation.context import GeneratorContext
from app.services.rag.generation.gemini_strategy import GeminiStrategy
from app.services.quiz.quiz_bank_service import build_quiz_from_bank
from app.core.database import get_db
from app.core.auth import get_current_user
from app.core.exceptions import LLMGenerationError, QuizBankInsufficientError, InsufficientContextError
from app.repositories import (
    get_all_student_skill_states,
    get_student_skill_state,
    get_priority_subject,
    get_subject_by_id,
    get_skills_by_subject_id,
    get_skills_by_names,
    create_quiz_session,
    upsert_student_subject_profile_last_quizzed,
    save_questions,
    get_quiz_session_by_id,
    get_question_by_id,
    save_question_response,
    get_active_quiz_session,
    get_questions_for_session,
)
from app.services.quiz.builder import build_quiz_payload
from app.services.evaluation.bkt_engine import BKTEngine
from app.services.gamification import GamificationService
from app.models.domain import Question, QuestionResponse

DIFFICULTY_LABELS = {1: "Very Easy", 2: "Easy", 3: "Medium", 4: "Hard", 5: "Very Hard"}

router = APIRouter(prefix="/quizzes", tags=["Quizzes"])

generator_context = GeneratorContext(strategy=GeminiStrategy())
bkt_engine = BKTEngine()
gamification_service = GamificationService()


@router.post("/generate", response_model=GenerateQuizResponse)
@limiter.limit(settings.QUIZ_GENERATE_RATE_LIMIT)
async def generate_quiz(
    request_body: GenerateQuizRequest,
    request: Request,
    db: Session = Depends(get_db),
    student_uid: str = Depends(get_current_user),
):
    try:
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

        # ------------------------------------------------------------------ #
        # Step 0.5: Quiz Cache Check (Cross-Device Reuse)
        # Before calling the LLM, check if there's already an unsubmitted
        # session for this student + subject. If so, return it directly — no
        # LLM call, no rate limit consumed. This ensures that opening the app
        # on a second device returns the same quiz as the first device.
        # ------------------------------------------------------------------ #
        active_session = get_active_quiz_session(db, student_uid, target_subject_id)
        if active_session:
            if active_session.total_questions == request_body.total_questions:
                cached_questions = get_questions_for_session(db, active_session.session_id)
                # Only reuse the session if its questions are still available (not yet scrubbed)
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
            else:
                print(
                    f"[QuizCache] Closing stale active session {active_session.session_id} "
                    f"due to count mismatch (expected {request_body.total_questions}, got {active_session.total_questions})",
                    flush=True,
                )
                active_session.end_time = datetime.utcnow()
                db.commit()

        # ------------------------------------------------------------------ #
        # Step 1: Get the student's BKT mastery profile
        # ------------------------------------------------------------------ #
        student_profile = get_all_student_skill_states(db, student_uid)

        if not student_profile:
            all_skills = get_skills_by_subject_id(db, target_subject_id)
            student_profile = {skill.name: 0.01 for skill in all_skills}

        if not student_profile:
            student_profile = {"General Math": 0.01}

        # ------------------------------------------------------------------ #
        # Step 2: Build quiz payload via BKT allocator
        # ------------------------------------------------------------------ #
        payload = build_quiz_payload(student_profile, request_body.total_questions)
        if not payload:
            raise HTTPException(status_code=400, detail="Could not allocate questions based on profile.")

        instruction_lines = []
        all_topics = []
        for cfg in payload:
            label = DIFFICULTY_LABELS.get(cfg["difficulty"], "Medium")
            instruction_lines.append(
                f"- Topic: {cfg['skill']} | Difficulty: {cfg['difficulty']} ({label}) | Questions: {cfg['count']}"
            )
            all_topics.append(cfg["skill"])

        topic_instructions = "\n".join(instruction_lines)

        # ------------------------------------------------------------------ #
        # Step 3: Create Quiz Session (needed for both LLM and bank paths)
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
            # Step 4a: PGVector retrieval (subject-scoped, tenant-isolated)
            context = retrieve_context_for_topics(
                all_topics,
                k=10,
                firebase_uid=student_uid,
                subject_id=target_subject_id,
            )

            # Step 4b: LLM structured generation
            response = generator_context.execute_generation(
                topic_instructions=topic_instructions,
                total_count=request_body.total_questions,
                context=context,
            )

            for q in response.questions:
                skill_id = skill_name_to_id.get(q.topic, 1)
                db_questions.append(Question(
                    question_id=q.question_id,
                    skill_id=skill_id,
                    session_id=quiz_session.session_id,
                    text_content=q.question_text,
                    options=q.options,
                    correct_answer=q.correct_answer,
                    difficulty=q.difficulty,
                    source_enum="AI",
                    explanation=q.explanation,
                    hints=q.hints,
                ))

        except (LLMGenerationError, InsufficientContextError) as llm_err:
            # Step 4c: Bank fallback — use the student's previously answered questions
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
            except QuizBankInsufficientError:
                # Step 4d: Hard fallback — nothing we can do
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

        return GenerateQuizResponse(
            quiz_session_id=str(quiz_session.session_id),
            selected_subject_id=target_subject_id,
            selected_subject_name=target_subject_name,
            quiz_title=response.quiz_title if quiz_source == "FRESH" else f"اختبار {target_subject_name}",
            questions=return_questions,
            quiz_source=quiz_source,
        )

    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/submit", response_model=QuizSubmissionResponse)
async def submit_quiz(
    request: QuizSubmissionRequest,
    db: Session = Depends(get_db),
    student_uid: str = Depends(get_current_user),
):
    try:
        total_submitted = len(request.answers)
        if total_submitted == 0:
            raise HTTPException(status_code=400, detail="Answers list cannot be empty.")

        # G21: Pessimistic row lock
        quiz_session = (
            db.query(QuizSessionModel)
            .filter_by(session_id=request.quiz_session_id)
            .with_for_update()
            .first()
        )

        if not quiz_session:
            raise HTTPException(status_code=404, detail="Quiz session not found.")

        if quiz_session.end_time is not None:
            raise HTTPException(status_code=409, detail="This quiz has already been submitted.")

        if quiz_session.student_uid != student_uid:
            raise HTTPException(status_code=403, detail="You are not allowed to submit this quiz.")

        # G22a: Answer count guard — reject if submission count doesn't match session
        if total_submitted != quiz_session.total_questions:
            raise HTTPException(
                status_code=400,
                detail=(
                    f"Expected {quiz_session.total_questions} answers "
                    f"but received {total_submitted}."
                )
            )

        # G22b: Pre-load valid question IDs for this session to enable cross-session check
        session_question_ids = {
            str(q.question_id)
            for q in get_questions_for_session(db, quiz_session.session_id)
        }

        triggered_punishment = False
        correct_answers = 0
        total_time_ms = 0

        for ans in request.answers:
            # G22c: Cross-session guard — reject answers referencing foreign questions
            if ans.question_id not in session_question_ids:
                raise HTTPException(
                    status_code=400,
                    detail=f"Question {ans.question_id} does not belong to this quiz session."
                )

            db_question = get_question_by_id(db, ans.question_id)
            if not db_question:
                continue

            is_correct = (ans.selected_option == db_question.correct_answer)
            if is_correct:
                correct_answers += 1

            db_response = QuestionResponse(
                question_id=db_question.question_id,
                student_uid=student_uid,
                selected_option=ans.selected_option,
                is_correct=is_correct,
                time_taken_ms=ans.time_taken_ms,
                hints_used=ans.hints_used,  # Already clamped [0,3] by schema validator
            )
            save_question_response(db, db_response)
            db_question.submitted_at = datetime.utcnow()
            total_time_ms += ans.time_taken_ms

            difficulty = db_question.difficulty
            skill_name = db_question.skill.name if db_question.skill else "General Math"
            skill_state = get_student_skill_state(db, student_uid, skill_name)

            # G23: Skip BKT mastery progression for suspiciously fast correct answers.
            # A correct answer in under 2 seconds almost certainly wasn't genuine comprehension.
            if is_correct and ans.time_taken_ms < settings.MINIMUM_GENUINE_TIME_MS:
                print(
                    f"[BKT] Skipping mastery update for question {ans.question_id}: "
                    f"correct answer in {ans.time_taken_ms}ms (threshold={settings.MINIMUM_GENUINE_TIME_MS}ms).",
                    flush=True,
                )
                triggered_punishment = True
                # Still increment spam count but skip the Bayesian update
                quiz_session.consecutive_spam_clicks = (quiz_session.consecutive_spam_clicks or 0) + 1
                skill_state.attempts += 1
                continue

            punished, new_spam_count = bkt_engine.update_mastery(
                skill_state=skill_state,
                skill_name=skill_name,
                difficulty=difficulty,
                correct=is_correct,
                response_time=ans.time_taken_ms / 1000.0,
                hints_used=ans.hints_used,
                current_session_spam_count=quiz_session.consecutive_spam_clicks if quiz_session else 0,
            )
            if quiz_session:
                quiz_session.consecutive_spam_clicks = new_spam_count

            if punished:
                triggered_punishment = True

        score = (correct_answers / total_submitted) * 100
        if quiz_session:
            quiz_session.score = score
            quiz_session.end_time = datetime.utcnow()

        # ── Gamification rewards ──────────────────────────────────────
        rewards = gamification_service.process_quiz_rewards(
            db,
            student_uid,
            quiz_session.session_id,
            correct_answers=correct_answers,
            total_questions=total_submitted,
            total_time_ms=total_time_ms,
            quiz_context=quiz_session.quiz_context or "VOLUNTARY",
            client_local_date=request.client_local_date,
        )

        db.commit()

        if score >= 85:
            feedback = "ممتاز! لقد أبليت بلاءً حسناً."
        elif score >= 50:
            feedback = "جيد، ولكن يمكنك التحسن بمزيد من الممارسة."
        else:
            feedback = "لا تقلق، استمر في المحاولة وسوف تنجح."

        if triggered_punishment:
            feedback += " 🛑 تبدو أنك كنت تجيب بسرعة كبيرة جداً. يرجى أخذ الوقت الكافي للتفكير في المرة القادمة!"

        return QuizSubmissionResponse(
            score=score,
            total_questions=total_submitted,
            feedback=feedback,
            rewards=rewards,
        )

    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))