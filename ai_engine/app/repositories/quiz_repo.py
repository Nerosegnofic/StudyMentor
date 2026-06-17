from sqlalchemy.orm import Session
from app.models.domain import QuizSession, Question, QuestionResponse, StudentSubjectProfile
from datetime import datetime
from typing import List, Optional, Set

def create_quiz_session(
    db: Session,
    student_uid: str,
    subject_id: int,
    total_questions: int,
    quiz_context: str = "VOLUNTARY",
) -> QuizSession:
    quiz_session = QuizSession(
        student_uid=student_uid,
        subject_id=subject_id,
        total_questions=total_questions,
        quiz_context=quiz_context,
    )
    db.add(quiz_session)
    db.flush()
    return quiz_session

def upsert_student_subject_profile_last_quizzed(db: Session, student_uid: str, subject_id: int) -> StudentSubjectProfile:
    profile = db.query(StudentSubjectProfile).filter(
        StudentSubjectProfile.student_uid == student_uid,
        StudentSubjectProfile.subject_id == subject_id
    ).first()
    
    if profile:
        profile.last_quizzed_at = datetime.utcnow()
    else:
        profile = StudentSubjectProfile(
            student_uid=student_uid,
            subject_id=subject_id,
            last_quizzed_at=datetime.utcnow()
        )
        db.add(profile)
    db.flush()
    return profile

def save_questions(db: Session, questions: List[Question]):
    db.add_all(questions)
    db.flush()

def get_quiz_session_by_id(db: Session, session_id: str) -> QuizSession:
    return db.query(QuizSession).filter(QuizSession.session_id == session_id).first()

def get_question_by_id(db: Session, question_id: str) -> Question:
    return db.query(Question).filter(Question.question_id == question_id).first()

def save_question_response(db: Session, response: QuestionResponse):
    db.add(response)
    db.flush()


def get_active_quiz_session(
    db: Session,
    student_uid: str,
    subject_id: int,
) -> Optional[QuizSession]:
    """
    Returns the most recent unsubmitted quiz session for this student + subject.

    Used by the /generate endpoint to enable quiz caching (cross-device reuse and
    client-side pre-warming): if an active session already exists, its questions are
    returned directly without calling the LLM or consuming the rate limit.

    Note: this intentionally does NOT filter by question count. An already-warmed quiz
    is served as-is even if the parent has since changed the quiz-count setting — that
    first cached quiz keeps its original count. The new count takes effect on the next
    generated quiz, because the next warm replays the launch's (updated) count.
    """
    return (
        db.query(QuizSession)
        .filter(
            QuizSession.student_uid == student_uid,
            QuizSession.subject_id == subject_id,
            QuizSession.end_time.is_(None),
        )
        .order_by(QuizSession.start_time.desc())
        .first()
    )


def get_questions_for_session(
    db: Session,
    session_id,
) -> List[Question]:
    """
    Returns all questions for a given session, ordered by creation time.
    Used to hydrate a CACHED quiz session response.
    """
    return (
        db.query(Question)
        .filter(Question.session_id == session_id)
        .order_by(Question.created_at)
        .all()
    )


def get_recent_question_fingerprints(
    db: Session,
    student_uid: str,
    subject_id: int,
    limit: int = 50,
) -> Set[str]:
    """
    Get fingerprints (first 80 chars) of recently generated questions
    for a specific student + subject, to prevent the LLM from repeating
    questions across quiz sessions.

    Scoped to `subject_id` so Math dedup fingerprints don't bleed into
    Arabic or Science quizzes (and vice versa).
    """
    recent_session_ids = (
        db.query(QuizSession.session_id)
        .filter(
            QuizSession.student_uid == student_uid,
            QuizSession.subject_id == subject_id,
        )
        .order_by(QuizSession.start_time.desc())
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
        q.text_content[:150].strip()
        for q in recent_questions
        if q.text_content
    }
