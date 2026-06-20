"""
Analytics Service
-----------------
Business logic for the adaptive analytics system.
Categorises skill mastery statuses and computes trend indicators.
"""

from typing import Dict, List
from datetime import datetime, timedelta

from sqlalchemy.orm import Session
from sqlalchemy import func, cast, Date

from app.models.domain import Skill, QuizSession, StudentSkillState

# ── Skill Status Thresholds ──────────────────────────────────────────────
MASTERED_THRESHOLD = 0.80
ACTIVE_THRESHOLD = 0.01   # Anything above the initial default is "active"


def categorise_skill_status(mastery: float, is_mastered: bool, attempts: int) -> str:
    """
    Determine a human-readable status for a single skill.

    Returns one of:
      - MASTERED  → mastery ≥ 0.95 (or the flag is set)
      - ACTIVE    → the student has attempted the skill at least once
      - LOCKED    → no attempts yet (mastery at initial value)
    """
    if is_mastered or mastery >= MASTERED_THRESHOLD:
        return "MASTERED"
    if attempts > 0 or mastery > ACTIVE_THRESHOLD:
        return "ACTIVE"
    return "LOCKED"


def enrich_hierarchy_with_status(hierarchy: List[Dict]) -> List[Dict]:
    """
    Walk through the Unit > Lesson > Skill hierarchy returned by the
    repository and attach a `status` field to every skill node.
    Also attaches summary counts at the unit and lesson level.
    """
    for unit in hierarchy:
        unit_mastered = 0
        unit_total = 0
        for lesson in unit.get("lessons", []):
            lesson_mastered = 0
            lesson_total = 0
            for skill in lesson.get("skills", []):
                status = categorise_skill_status(
                    skill["mastery"],
                    skill["is_mastered"],
                    skill["attempts"],
                )
                skill["status"] = status
                lesson_total += 1
                if status == "MASTERED":
                    lesson_mastered += 1
            lesson["mastered_count"] = lesson_mastered
            lesson["total_count"] = lesson_total
            unit_mastered += lesson_mastered
            unit_total += lesson_total
        unit["mastered_count"] = unit_mastered
        unit["total_count"] = unit_total

    return hierarchy


def compute_mastery_trend(current_mastery: float, previous_mastery: float | None) -> str:
    """
    Compare current mastery to a previous snapshot and return a trend label.

    Returns one of: "improving", "declining", "stable"
    """
    if previous_mastery is None:
        return "stable"
    # Round to tame float-subtraction noise so an exact ±0.02 delta lands on the
    # band boundary as intended (e.g. 0.52 - 0.50 is 0.020000000000000018 in raw
    # float, which would otherwise read as "improving").
    delta = round(current_mastery - previous_mastery, 6)
    if delta > 0.02:
        return "improving"
    if delta < -0.02:
        return "declining"
    return "stable"


def get_overall_dashboard_stats(db: Session, student_uid: str) -> dict:
    """
    Computes global dashboard statistics for a student, including total tracked skills,
    mastered skills count, overall mastery percentage, and a 30-day activity heatmap.
    """
    # ── Aggregate mastery across all subjects ────────────────────────────
    all_states = (
        db.query(StudentSkillState)
        .filter(StudentSkillState.student_uid == student_uid)
        .all()
    )
    # Denominator = only skills this student has actually practiced (same
    # practiced-skills contract as get_subject_stats).
    attempted = [s for s in all_states if s.attempts > 0]
    total_skills = len(attempted)
    mastered_skills = sum(1 for s in attempted if s.is_mastered)
    overall_mastery = (
        round(sum(s.mastery_probability for s in attempted) / total_skills, 4)
        if total_skills
        else 0.0
    )

    # ── Activity heatmap: sessions per day over the last 30 days ─────────
    thirty_days_ago = datetime.utcnow() - timedelta(days=30)
    heatmap_rows = (
        db.query(
            cast(QuizSession.start_time, Date).label("date"),
            func.count(QuizSession.session_id).label("count"),
        )
        .filter(
            QuizSession.student_uid == student_uid,
            QuizSession.start_time >= thirty_days_ago,
        )
        .group_by(cast(QuizSession.start_time, Date))
        .order_by(cast(QuizSession.start_time, Date))
        .all()
    )
    activity_heatmap = {
        row.date.isoformat(): row.count for row in heatmap_rows
    }

    return {
        "student_uid": student_uid,
        "total_skills": total_skills,
        "mastered_skills": mastered_skills,
        "overall_mastery": overall_mastery,
        "activity_heatmap": activity_heatmap,
    }

