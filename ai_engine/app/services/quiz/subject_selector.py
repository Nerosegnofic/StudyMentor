"""
Auto-Quiz Subject Prioritization.

Business logic that picks which subject a student should be auto-quizzed on next.
Kept in the service layer (not the repository) because it is scoring/policy, not
data access — it composes the repository's pure query helpers.
"""
from datetime import datetime
from typing import List, Optional

from sqlalchemy import or_
from sqlalchemy.orm import Session

from app.models.domain import Subject, QuizSession, StudentSubjectProfile
from app.repositories import get_subject_stats


def get_priority_subject(db: Session, student_uid: str) -> Optional[Subject]:
    """
    Selects the highest-priority subject for auto-generated quizzes.

    Scoring formula per subject:
        score = (mastery_gap * 40) + (neglect * 30) + (exam_urgency * 30)

    Components:
        mastery_gap  (0–1): How far the student is from mastery. (1 - avg_mastery)
                            Higher gap = needs more practice = higher score.
        neglect      (0–1): How long since this subject was last quizzed.
                            Normalized over 30 days; never quizzed = 1.0.
        exam_urgency (0–1): How close the exam is.
                            Exams within 7 days = 1.0; no exam = 0.0.

    Returns None if the student has no subjects with skills.
    """
    # Get globally shared subjects OR subjects owned by this specific student
    subjects = db.query(Subject).filter(
        or_(
            Subject.is_global == True,
            Subject.student_uid == student_uid
        )
    ).all()

    if not subjects:
        return None

    now = datetime.utcnow()
    scored: List[tuple] = []  # (score, subject)

    # Find the most recently quizzed subject to apply a rotation penalty
    last_session = (
        db.query(QuizSession)
        .filter(QuizSession.student_uid == student_uid)
        .order_by(QuizSession.start_time.desc())
        .first()
    )
    last_subject_id = last_session.subject_id if last_session else None

    for subj in subjects:
        stats = get_subject_stats(db, student_uid, subj.subject_id)

        # Skip subjects with no skills (nothing to quiz on)
        if stats["total_skills"] == 0:
            continue

        # ── Mastery Gap (0–1) ────────────────────────────────────────
        mastery_gap = 1.0 - stats["average_mastery"]

        # ── Neglect (0–1) ────────────────────────────────────────────
        # Use the last quiz session for this subject+student as the reference
        last_quiz_for_subject = (
            db.query(QuizSession)
            .filter(
                QuizSession.student_uid == student_uid,
                QuizSession.subject_id == subj.subject_id,
            )
            .order_by(QuizSession.start_time.desc())
            .first()
        )
        if last_quiz_for_subject and last_quiz_for_subject.start_time:
            days_since = (now - last_quiz_for_subject.start_time).total_seconds() / 86400
            neglect = min(1.0, days_since / 30.0)  # Cap at 1.0 after 30 days
        else:
            neglect = 1.0  # Never quizzed → maximum neglect

        # ── Exam Urgency (0–1) ───────────────────────────────────────
        profile = (
            db.query(StudentSubjectProfile)
            .filter(
                StudentSubjectProfile.student_uid == student_uid,
                StudentSubjectProfile.subject_id == subj.subject_id
            )
            .first()
        )

        exam_date = profile.exam_date if profile else None

        if exam_date and exam_date > now:
            days_until_exam = (exam_date - now).total_seconds() / 86400
            if days_until_exam <= 7:
                exam_urgency = 1.0
            elif days_until_exam <= 30:
                exam_urgency = 1.0 - ((days_until_exam - 7) / 23.0)  # Linear decay from 1.0 to 0.0
            else:
                exam_urgency = 0.0
        else:
            exam_urgency = 0.0  # No exam date set or exam already passed

        # ── Weighted Score ───────────────────────────────────────────
        score = (mastery_gap * 40) + (neglect * 30) + (exam_urgency * 30)

        # ── Rotation Penalty ─────────────────────────────────────────
        # If this was the last subject quizzed, reduce its score to encourage variety
        if subj.subject_id == last_subject_id:
            score *= 0.6

        scored.append((score, subj))

    if not scored:
        return None

    # Return the subject with the highest score
    scored.sort(key=lambda x: x[0], reverse=True)
    return scored[0][1]