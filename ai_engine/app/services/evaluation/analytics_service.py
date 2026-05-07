"""
Analytics Service
-----------------
Business logic for the adaptive analytics system.
Categorises skill mastery statuses and computes trend indicators.
"""

from typing import Dict, List

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
    delta = current_mastery - previous_mastery
    if delta > 0.02:
        return "improving"
    if delta < -0.02:
        return "declining"
    return "stable"
