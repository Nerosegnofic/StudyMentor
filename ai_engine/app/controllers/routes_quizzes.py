import random
import string
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
from app.services.rag.retrieval import retrieve_context_for_quiz
from app.services.rag.generation.context import GeneratorContext
from app.services.rag.generation.gemini_strategy import GeminiStrategy
from app.services.quiz.quiz_bank_service import build_quiz_from_bank
from app.core.database import get_db
from app.core.auth import get_current_user
from app.core.exceptions import LLMGenerationError, QuizBankInsufficientError, InsufficientContextError
from app.repositories import (
    get_student_skill_state,
    get_priority_subject,
    get_subject_by_id,
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
from app.models.domain import Question, QuestionResponse

DIFFICULTY_LABELS = {1: "Very Easy", 2: "Easy", 3: "Medium", 4: "Hard", 5: "Very Hard"}

# Map ordinal grade numbers to English ordinal suffixes for the prompt
GRADE_LABELS = {
    1: "1st", 2: "2nd", 3: "3rd", 4: "4th", 5: "5th", 6: "6th",
    7: "7th", 8: "8th", 9: "9th", 10: "10th", 11: "11th", 12: "12th",
}

router = APIRouter(prefix="/quizzes", tags=["Quizzes"])

generator_context = GeneratorContext(strategy=GeminiStrategy())
bkt_engine = BKTEngine()


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _generate_variance_block() -> str:
    """
    Generate a unique variance seed and question format requirements
    for each quiz generation call. This forces the LLM to produce diverse
    questions instead of deterministic repeats for identical inputs.
    """
    seed = ''.join(random.choices(string.ascii_uppercase + string.digits, k=8))
    formats = random.sample([
        "word problem with a real-world Egyptian scenario",
        "fill-in-the-blank calculation",
        "error detection (find the mistake in this solution)",
        "comparison between two values",
        "multi-step reasoning chain",
        "true/false with justification converted to MCQ",
    ], k=3)
    return (
        f"\n\nVARIANCE SEED: {seed}\n"
        "For this specific generation, you MUST use at least these question formats:\n"
        + "\n".join(f"  - {f}" for f in formats)
        + "\n\nDo NOT reuse numbers from any examples in the context. "
        "Generate fresh, novel numerical values for every question. "
        "Use Egyptian names (أحمد, فاطمة, يوسف, مريم, نور, عمر) and Egyptian contexts "
        "(المدرسة, السوق, الحديقة, المكتبة, الملعب) in word problems."
    )


def _get_recent_question_fingerprints(
    db: Session,
    student_uid: str,
    subject_id: int,
    limit: int = 50,
) -> set:
    """
    Get fingerprints (first 80 chars) of recently generated questions
    for a specific student + subject, to prevent the LLM from repeating
    questions across quiz sessions.

    Scoped to ``subject_id`` so Math dedup fingerprints don't bleed into
    Arabic or Science quizzes (and vice versa).
    """
    recent_session_ids = (
        db.query(QuizSessionModel.session_id)
        .filter(
            QuizSessionModel.student_uid == student_uid,
            QuizSessionModel.subject_id == subject_id,
        )
        .order_by(QuizSessionModel.start_time.desc())
        .limit(10)
        .all()
    )
    if not recent_session_ids:
        return set()

    session_ids = [s.session_id for s in recent_session_ids]
    recent_questions = (
        db.query(Question.text_content)
        .filter(Question.session_id.in_(session_ids))
        .limit(limit)
        .all()
    )
    return {
        q.text_content[:80].strip()
        for q in recent_questions
        if q.text_content
    }

def _shuffle_question_options(question_schema: QuestionSchema) -> QuestionSchema:
    """
    Shuffle the options of a question in-place and keep correct_answer consistent.
    This is the definitive server-side fix for LLM positional bias (always putting
    the correct answer first).
    """
    options = list(question_schema.options)
    random.shuffle(options)
    # correct_answer is a value, not a position — it stays the same string
    return QuestionSchema(
        question_id=question_schema.question_id,
        topic=question_schema.topic,
        question_text=question_schema.question_text,
        options=options,
        correct_answer=question_schema.correct_answer,
        explanation=question_schema.explanation,
        difficulty=question_schema.difficulty,
        hints=question_schema.hints,
    )


def _build_difficulty_map(payload: list) -> dict:
    """
    Build a mapping from skill name → requested difficulty from the BKT payload.
    Used for post-generation difficulty mismatch detection.
    """
    return {cfg["skill"]: cfg["difficulty"] for cfg in payload}


def _filter_mismatched_questions(
    questions: list,
    difficulty_map: dict,
    tolerance: int = 1,
) -> tuple:
    """
    Filters out questions whose difficulty doesn't match what was requested (±tolerance).
    
    Returns:
        (accepted_questions, dropped_count)
    """
    accepted = []
    dropped = 0
    for q in questions:
        requested_diff = difficulty_map.get(q.topic)
        if requested_diff is not None and abs(q.difficulty - requested_diff) > tolerance:
            print(
                f"[DifficultyGuard] Dropping question for topic='{q.topic}': "
                f"requested difficulty={requested_diff}, got={q.difficulty}",
                flush=True,
            )
            dropped += 1
        else:
            accepted.append(q)
    return accepted, dropped


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

        # Resolve grade label for prompt (e.g., 5 → "5th")
        student_grade_label = GRADE_LABELS.get(request_body.student_grade, f"{request_body.student_grade}th")

        # ------------------------------------------------------------------ #
        # Step 0.5: Quiz Cache Check (Cross-Device Reuse)
        # Before calling the LLM, check if there's already an unsubmitted
        # session for this student + subject. If so, return it directly — no
        # LLM call, no rate limit consumed. This ensures that opening the app
        # on a second device returns the same quiz as the first device.
        # ------------------------------------------------------------------ #
        active_session = get_active_quiz_session(db, student_uid, target_subject_id)
        if active_session:
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
        difficulty_map = _build_difficulty_map(payload)

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
            # Step 4a: Zone-aware PGVector retrieval (MMR + zone budgets)
            context = retrieve_context_for_quiz(
                payload,
                k=15,
                firebase_uid=student_uid,
                subject_id=target_subject_id,
            )

            # Step 4a.5: Inject variance seed and question dedup avoidance
            variance_block = _generate_variance_block()

            recent_fps = _get_recent_question_fingerprints(db, student_uid, target_subject_id)
            if recent_fps:
                avoidance_instructions = (
                    "\n\n⚠️ PREVIOUSLY ASKED QUESTIONS (DO NOT REPEAT):\n"
                    + "\n".join(f'  - "{fp}..."' for fp in list(recent_fps)[:15])
                    + "\n\nGenerate COMPLETELY DIFFERENT questions with different numbers, names, and scenarios."
                )
                context = context + avoidance_instructions

            # Debug output injection - Formatted readable report
            try:
                with open("debug_output.txt", "w", encoding="utf-8") as f:
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
                print(f"[Debug] Failed to write debug_output.txt: {e}")

            # Step 4b: LLM structured generation (with variance seed)
            response = generator_context.execute_generation(
                topic_instructions=topic_instructions,
                total_count=request_body.total_questions,
                context=context,
                student_grade=student_grade_label,
                variance_block=variance_block,
            )

            # Step 4c: Difficulty mismatch guardrail
            # Drop questions that don't match the requested difficulty (±1 tolerance).
            # If >20% are mismatched, retry once before falling through.
            accepted_questions, dropped_count = _filter_mismatched_questions(
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
                # Retry once
                response = generator_context.execute_generation(
                    topic_instructions=topic_instructions,
                    total_count=request_body.total_questions,
                    context=context,
                    student_grade=student_grade_label,
                    variance_block=variance_block,
                )
                accepted_questions, dropped_count = _filter_mismatched_questions(
                    response.questions, difficulty_map, tolerance=1
                )
                if dropped_count > 0:
                    print(
                        f"[DifficultyGuard] Retry still dropped {dropped_count} mismatched questions. Proceeding.",
                        flush=True,
                    )

            # Step 4d: Shuffle options & build DB questions
            for q in accepted_questions:
                shuffled = _shuffle_question_options(q)
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
            # Step 4e: Bank fallback — use the student's previously answered questions
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
                # Step 4f: Hard fallback — nothing we can do
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
        # Update session total_questions to reflect actual count after filtering
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
        )

    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))