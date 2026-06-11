"""
Spaced Repetition Scheduler for the Mastered skill zone.

Selects mastered skills most in need of review based on a simplified
SM-2-inspired interval schedule. Skills that are overdue for review
are prioritized, ensuring long-term retention without overwhelming
the student.
"""

from datetime import datetime, timedelta
from typing import List, Optional


# SM-2-inspired interval tiers based on practice attempts.
# More attempts = student has reviewed it more = longer until next review.
_INTERVAL_TIERS = [
    (2, timedelta(days=1)),               # 1-2 attempts: review after 1 day
    (4, timedelta(days=3)),               # 3-4 attempts: review after 3 days
    (6, timedelta(days=7)),               # 5-6 attempts: review after 7 days
    (float('inf'), timedelta(days=14)),   # 7+ attempts: review after 14 days
]


def _compute_review_interval(attempts: int) -> timedelta:
    """Get the SRS interval for a skill based on how many times it's been practiced."""
    for max_attempts, interval in _INTERVAL_TIERS:
        if attempts <= max_attempts:
            return interval
    return timedelta(days=14)


def select_srs_review_skills(
    mastered_skills: List[dict],
    max_review: int,
    now: Optional[datetime] = None,
) -> List[dict]:
    """
    Select mastered skills most in need of review.

    Each skill entry is expected to have:
        - "skill":          Skill ORM object
        - "mastery":        float
        - "last_practiced": datetime or None
        - "attempts":       int

    Returns up to ``max_review`` skill entries, sorted most-overdue first.
    """
    if not mastered_skills or max_review <= 0:
        return []

    if now is None:
        now = datetime.utcnow()

    def overdue_days(entry: dict) -> float:
        """Negative = overdue (should be reviewed), positive = not yet due."""
        last = entry.get("last_practiced")
        if last is None:
            return -999.0  # Never practiced → maximally overdue

        attempts = entry.get("attempts", 0)
        interval = _compute_review_interval(attempts)
        due_date = last + interval
        return (due_date - now).total_seconds() / 86400.0

    # Sort: most overdue first (most negative overdue_days)
    scored = sorted(mastered_skills, key=overdue_days)
    return scored[:max_review]
