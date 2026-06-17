"""
Adaptive Auto Quiz-Length.

When the parent selects "Auto" quiz length, the number of questions is computed from how
much material is currently active for the student — the breadth of the frontier plus any
reviews that are due — rather than a fixed count. The result is then eased DOWN for a
struggling student (shorter, less-frustrating sets) and nudged UP for a thriving one,
reusing the same recent-accuracy thresholds as the skill selector. The final count always
clamps to [QUIZ_AUTO_MIN_QUESTIONS, QUIZ_AUTO_MAX_QUESTIONS].

This is the quiz-length analogue of the subject selector (which subject) and the skill
selector (which skills) — here we decide HOW MANY questions.
"""
from sqlalchemy.orm import Session

from app.core.config import settings
from app.repositories import get_recent_subject_accuracy
from app.services.quiz.skill_selector import classify_skills
from app.services.quiz.srs_scheduler import count_due_reviews


def compute_adaptive_quiz_length(
    db: Session,
    student_uid: str,
    subject_id: int,
    student_grade: int = 5,
) -> int:
    """
    Size an auto-length quiz from the student's currently-active material, eased by recent
    accuracy and clamped to the configured [min, max] range.

    base = (# active frontier skills) + (capped # of due reviews) + (1 preview taste if any
    locked skills remain). A struggling student's base is multiplied by
    ``QUIZ_AUTO_STRUGGLING_FACTOR``; a thriving one's by ``QUIZ_AUTO_THRIVING_FACTOR``.
    """
    frontier_window = settings.SKILL_FRONTIER_WINDOW_BY_GRADE.get(
        student_grade, settings.SKILL_DEFAULT_FRONTIER_WINDOW
    )
    zones = classify_skills(db, student_uid, subject_id, frontier_window)

    due_reviews = min(count_due_reviews(zones["mastered"]), settings.QUIZ_AUTO_REVIEW_CAP)
    preview_taste = 1 if zones["locked"] else 0
    base = len(zones["frontier"]) + due_reviews + preview_taste

    # Ease the length by recent accuracy, reusing the skill selector's thresholds so
    # "struggling" / "thriving" mean the same thing across the quiz pipeline.
    recent_accuracy = get_recent_subject_accuracy(
        db, student_uid, subject_id, limit=settings.SKILL_ADAPTIVE_RECENT_SESSIONS
    )
    if recent_accuracy is not None:
        if recent_accuracy < settings.SKILL_ADAPTIVE_LOW_ACCURACY:
            base = round(base * settings.QUIZ_AUTO_STRUGGLING_FACTOR)
        elif recent_accuracy >= settings.SKILL_ADAPTIVE_HIGH_ACCURACY:
            base = round(base * settings.QUIZ_AUTO_THRIVING_FACTOR)

    return max(
        settings.QUIZ_AUTO_MIN_QUESTIONS,
        min(settings.QUIZ_AUTO_MAX_QUESTIONS, int(base)),
    )