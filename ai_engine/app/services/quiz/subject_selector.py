"""
Auto-Quiz Subject Prioritization.

Business logic that picks which subject a student should be auto-quizzed on next.
Kept in the service layer (not the repository) because it is scoring/policy, not
data access — it composes the repository's pure query helpers.

The priority score is a weighted sum of interpretable factors, all tunable from
``settings.SUBJECT_SELECTION_WEIGHTS`` without code edits. Selection is argmax, so only
the RELATIVE ordering of scores matters — a factor weight of 0.0 simply disables that
factor (it isn't even computed). ``exam_urgency`` ships at 0.0 because the app does not
yet collect exam dates.
"""
from datetime import datetime
from typing import List, Optional

from sqlalchemy import or_
from sqlalchemy.orm import Session

from app.models.domain import Subject, QuizSession, StudentSubjectProfile
from app.repositories import get_subject_stats
from app.core.config import settings


def _exam_urgency(db: Session, student_uid: str, subject_id: int, now: datetime) -> float:
    """Exam proximity in [0, 1]: 1.0 within 7 days, linear decay to 0.0 by 30 days, else 0.0."""
    profile = (
        db.query(StudentSubjectProfile)
        .filter(
            StudentSubjectProfile.student_uid == student_uid,
            StudentSubjectProfile.subject_id == subject_id,
        )
        .first()
    )
    exam_date = profile.exam_date if profile else None
    if exam_date and exam_date > now:
        days_until_exam = (exam_date - now).total_seconds() / 86400
        if days_until_exam <= 7:
            return 1.0
        if days_until_exam <= 30:
            return 1.0 - ((days_until_exam - 7) / 23.0)  # linear decay 1.0 → 0.0
    return 0.0


def get_priority_subject(db: Session, student_uid: str) -> Optional[Subject]:
    """
    Select the highest-priority subject for an auto-generated quiz.

    Scoring per subject (weights from ``settings.SUBJECT_SELECTION_WEIGHTS``):
        score = w_gap*mastery_gap + w_neglect*neglect + w_exam*exam_urgency

      mastery_gap  (0–1): 1 - average_mastery. Higher gap ⇒ needs more practice.
      neglect      (0–1): how many quiz sessions the student has taken SINCE this subject
                          last appeared, normalized by SUBJECT_NEGLECT_QUIZ_WINDOW.
                          Never quizzed ⇒ 1.0 (maximally neglected). This is engagement-
                          based (count of quizzes), not wall-clock time.
      exam_urgency (0–1): exam proximity (only computed when its weight > 0).

    The most-recently-quizzed subject is multiplied by SUBJECT_ROTATION_PENALTY to
    encourage variety. Returns None if the student has no subjects with skills.
    """
    subjects = db.query(Subject).filter(
        or_(
            Subject.is_global == True,
            Subject.student_uid == student_uid,
        )
    ).all()

    if not subjects:
        return None

    weights = settings.SUBJECT_SELECTION_WEIGHTS or {}
    w_gap = weights.get("mastery_gap", 0.0)
    w_neglect = weights.get("neglect", 0.0)
    w_exam = weights.get("exam_urgency", 0.0)
    neglect_window = max(1, settings.SUBJECT_NEGLECT_QUIZ_WINDOW)

    now = datetime.utcnow()

    # One query: all of the student's quiz sessions, most recent first. The subject_id
    # list (in descending recency) lets us compute "quizzes since last appearance" in
    # memory and identify the last-quizzed subject for the rotation penalty.
    sessions = (
        db.query(QuizSession)
        .filter(QuizSession.student_uid == student_uid)
        .order_by(QuizSession.start_time.desc())
        .all()
    )
    session_subject_ids = [s.subject_id for s in sessions]
    last_subject_id = session_subject_ids[0] if session_subject_ids else None

    scored: List[tuple] = []  # (score, subject)

    for subj in subjects:
        stats = get_subject_stats(db, student_uid, subj.subject_id)

        # Skip subjects with no skills (nothing to quiz on)
        if stats["total_skills"] == 0:
            continue

        score = 0.0

        # ── Mastery Gap ──────────────────────────────────────────────
        if w_gap:
            score += w_gap * (1.0 - stats["average_mastery"])

        # ── Neglect: quiz sessions since this subject last appeared ──
        if w_neglect:
            try:
                quizzes_since = session_subject_ids.index(subj.subject_id)
            except ValueError:
                quizzes_since = neglect_window  # never quizzed → max neglect
            neglect = min(1.0, quizzes_since / neglect_window)
            score += w_neglect * neglect

        # ── Exam Urgency (only when weighted; app may not collect exam dates) ──
        if w_exam:
            score += w_exam * _exam_urgency(db, student_uid, subj.subject_id, now)

        # ── Rotation Penalty ─────────────────────────────────────────
        if subj.subject_id == last_subject_id:
            score *= settings.SUBJECT_ROTATION_PENALTY

        scored.append((score, subj))

    if not scored:
        return None

    scored.sort(key=lambda x: x[0], reverse=True)
    return scored[0][1]