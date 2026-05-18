from sqlalchemy.orm import Session
from app.models.domain import QuizSession, Question, QuestionResponse, StudentSubjectProfile
from datetime import datetime
from typing import List, Optional

def create_quiz_session(db: Session, student_uid: str, subject_id: int, total_questions: int) -> QuizSession:
    quiz_session = QuizSession(
        student_uid=student_uid,
        subject_id=subject_id,
        total_questions=total_questions
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

    Used by the /generate endpoint to enable cross-device quiz caching:
    if an active session already exists, its questions are returned directly
    without calling the LLM or consuming the rate limit.
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
