from datetime import datetime
from fastapi import HTTPException
from sqlalchemy.orm import Session

from app.models.schemas import QuizSubmissionRequest, QuizSubmissionResponse
from app.models.domain import QuestionResponse
from app.models.domain.quiz import QuizSession as QuizSessionModel
from app.repositories import (
    get_questions_for_session,
    get_question_by_id,
    save_question_response,
    get_student_skill_state,
    upsert_garden_plant,
)
from app.services.evaluation.bkt_engine import BKTEngine
from app.services.gamification import GamificationService
from app.core.config import settings

bkt_engine = BKTEngine()
gamification_service = GamificationService()


def process_quiz_submission(
    db: Session,
    request: QuizSubmissionRequest,
    student_uid: str,
) -> QuizSubmissionResponse:
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
        if str(ans.question_id) not in session_question_ids:
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
        skill_name = db_question.skill.name if db_question.skill else "General"
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

    # ── Gamification rewards ──────────────────────────────────────────────
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

    # ── Garden sync (update plant mastery after BKT states are persisted) ─
    if quiz_session and quiz_session.subject_id:
        try:
            upsert_garden_plant(db, student_uid, quiz_session.subject_id)
            db.commit()
        except Exception:
            db.rollback()

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
