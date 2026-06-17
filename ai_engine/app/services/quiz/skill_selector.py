"""
Ordered Frontier + SRS Skill Selector.

Classifies all skills in a subject into three zones for a student:
  - Frontier: actively learning (Zone of Proximal Development)
  - Mastered: previously learned, due for SRS review
  - Locked:   not yet unlocked (prerequisites not met)

Quiz composition draws from all three zones. The split, the unlock threshold, and the
per-grade frontier window are all configurable in ``settings`` (no code edits to tune).
When ``SKILL_ADAPTIVE_BUDGET`` is on, the split and frontier width also adapt to the
student's recent quiz accuracy — shifting toward review when they're struggling and
toward the frontier when they're thriving.
"""

from typing import Dict, List, Optional
import random

from sqlalchemy.orm import Session

from app.models.domain import Skill, StudentSkillState
from app.repositories import get_recent_subject_accuracy
from app.services.quiz.difficulty_mapper import mastery_to_difficulty
from app.services.quiz.srs_scheduler import select_srs_review_skills
from app.core.config import settings


# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

# Preview questions are always Very Easy (recall-only) — just a taste of what's next.
PREVIEW_DIFFICULTY = 1

# Alternate zone splits applied under adaptivity (the base split lives in config).
_ADAPTIVE_STRUGGLING_SPLIT = {"frontier": 0.40, "review": 0.50, "preview": 0.10}
_ADAPTIVE_THRIVING_SPLIT = {"frontier": 0.70, "review": 0.20, "preview": 0.10}


# ---------------------------------------------------------------------------
# Zone Classification
# ---------------------------------------------------------------------------

def classify_skills(
    db: Session,
    student_uid: str,
    subject_id: int,
    frontier_window: Optional[int] = None,
) -> Dict[str, List[dict]]:
    """
    Classifies all skills in a subject into three zones for a student,
    walking through skills in curriculum order (by ``lesson_index``).

    Returns::

        {
            "frontier": [{"skill": Skill, "mastery": float}, ...],
            "mastered": [{"skill": Skill, "mastery": float,
                          "last_practiced": datetime, "attempts": int}, ...],
            "locked":   [{"skill": Skill}, ...],
        }
    """
    if frontier_window is None:
        frontier_window = settings.SKILL_DEFAULT_FRONTIER_WINDOW
    unlock_threshold = settings.SKILL_UNLOCK_THRESHOLD

    # Get all skills ordered by curriculum sequence. lesson_index is a PER-UNIT
    # counter, so unit_name must lead the ordering — otherwise the frontier walk
    # interleaves units (all "lesson 1" skills first, across every unit).
    all_skills = (
        db.query(Skill)
        .filter(Skill.subject_id == subject_id)
        .order_by(Skill.unit_name.asc(), Skill.lesson_index.asc(), Skill.skill_id.asc())
        .all()
    )

    if not all_skills:
        return {"frontier": [], "mastered": [], "locked": []}

    # Get student's current state for all skills in one query
    states = (
        db.query(StudentSkillState)
        .filter(
            StudentSkillState.student_uid == student_uid,
            StudentSkillState.skill_id.in_([s.skill_id for s in all_skills]),
        )
        .all()
    )
    state_map = {s.skill_id: s for s in states}

    mastered: List[dict] = []
    frontier: List[dict] = []
    locked: List[dict] = []

    frontier_count = 0

    for skill in all_skills:
        state = state_map.get(skill.skill_id)
        mastery = state.mastery_probability if state else 0.01
        last_practiced = state.last_practiced if state else None
        attempts = state.attempts if state else 0

        if mastery >= unlock_threshold:
            # Skill is above the unlock threshold → mastered zone (SRS review)
            mastered.append({
                "skill": skill,
                "mastery": mastery,
                "last_practiced": last_practiced,
                "attempts": attempts,
            })
        elif frontier_count < frontier_window:
            # Still room in the frontier → active learning zone
            frontier.append({
                "skill": skill,
                "mastery": mastery,
            })
            frontier_count += 1
        else:
            # Gate closed → locked zone (not yet unlocked)
            locked.append({"skill": skill})

    return {"frontier": frontier, "mastered": mastered, "locked": locked}


# ---------------------------------------------------------------------------
# Quiz Skill Selection
# ---------------------------------------------------------------------------

def select_quiz_skills(
    db: Session,
    student_uid: str,
    subject_id: int,
    total_questions: int,
    student_grade: int = 5,
) -> List[dict]:
    """
    Select skills for a quiz using the Ordered Frontier + SRS model.

    Returns a list of dicts, each containing::

        {
            "skill":      Skill ORM object,
            "count":      int   — number of questions to generate,
            "zone":       str   — "frontier", "review", or "preview",
            "difficulty": int   — 1-5 difficulty target,
            "mastery":    float — current mastery probability,
        }
    """
    # ── Frontier window (grade-based, optionally personalized) ────
    frontier_window = settings.SKILL_FRONTIER_WINDOW_BY_GRADE.get(
        student_grade, settings.SKILL_DEFAULT_FRONTIER_WINDOW
    )

    recent_accuracy = (
        get_recent_subject_accuracy(
            db, student_uid, subject_id, limit=settings.SKILL_ADAPTIVE_RECENT_SESSIONS
        )
        if settings.SKILL_ADAPTIVE_BUDGET else None
    )

    # ── Zone budget split (base from config, adapted to recent accuracy) ──
    split = settings.SKILL_ZONE_BUDGET_SPLIT or {}
    fracs = {
        "frontier": split.get("frontier", 0.60),
        "review": split.get("review", 0.30),
        "preview": split.get("preview", 0.10),
    }
    if recent_accuracy is not None:
        if recent_accuracy < settings.SKILL_ADAPTIVE_LOW_ACCURACY:
            # Struggling → consolidate via review, narrow the frontier.
            fracs = dict(_ADAPTIVE_STRUGGLING_SPLIT)
            frontier_window = max(1, frontier_window - 1)
        elif recent_accuracy >= settings.SKILL_ADAPTIVE_HIGH_ACCURACY:
            # Thriving → push the frontier wider.
            fracs = dict(_ADAPTIVE_THRIVING_SPLIT)
            frontier_window += 1

    zones = classify_skills(db, student_uid, subject_id, frontier_window)

    # ── Initial integer budgets per zone ──────────────────────────
    frontier_budget = max(1, round(total_questions * fracs["frontier"]))
    review_budget = max(0, round(total_questions * fracs["review"]))
    preview_budget = max(0, total_questions - frontier_budget - review_budget)

    # ── Proportional redistribution from empty zones ──────────────
    # An empty zone's budget is shared among the POPULATED zones in proportion to their
    # base fractions, rather than dumped entirely on the next zone.
    present = {
        "frontier": bool(zones["frontier"]),
        "review": bool(zones["mastered"]),
        "preview": bool(zones["locked"]),
    }
    budgets = {"frontier": frontier_budget, "review": review_budget, "preview": preview_budget}
    empty_budget = sum(b for z, b in budgets.items() if not present[z])
    if empty_budget:
        populated = [z for z in budgets if present[z]]
        weight_total = sum(fracs[z] for z in populated) or 1.0
        for z in populated:
            budgets[z] += int(round(empty_budget * fracs[z] / weight_total))
        for z in budgets:
            if not present[z]:
                budgets[z] = 0
    frontier_budget = budgets["frontier"]
    review_budget = budgets["review"]
    preview_budget = budgets["preview"]

    selections: List[dict] = []
    allocated = 0

    # ── Frontier Skills ───────────────────────────────────────────
    if zones["frontier"] and frontier_budget > 0:
        n_frontier = len(zones["frontier"])
        per_skill = max(1, frontier_budget // n_frontier)
        remainder = frontier_budget - per_skill * n_frontier

        for i, entry in enumerate(zones["frontier"]):
            count = per_skill + (1 if i < remainder else 0)
            count = min(count, total_questions - allocated)
            if count > 0:
                selections.append({
                    "skill": entry["skill"],
                    "count": count,
                    "zone": "frontier",
                    "difficulty": mastery_to_difficulty(entry["mastery"]),
                    "mastery": entry["mastery"],
                })
                allocated += count

    # ── SRS Review ────────────────────────────────────────────────
    if zones["mastered"] and review_budget > 0 and allocated < total_questions:
        review_skills = select_srs_review_skills(
            zones["mastered"],
            max_review=min(review_budget, total_questions - allocated),
        )
        for entry in review_skills:
            if allocated >= total_questions:
                break
            selections.append({
                "skill": entry["skill"],
                "count": 1,
                "zone": "review",
                "difficulty": mastery_to_difficulty(entry["mastery"]),
                "mastery": entry["mastery"],
            })
            allocated += 1

    # ── Preview / Exploration ─────────────────────────────────────
    if zones["locked"] and preview_budget > 0 and allocated < total_questions:
        n_previews = min(
            preview_budget,
            len(zones["locked"]),
            total_questions - allocated,
        )
        previews = random.sample(zones["locked"], n_previews)
        for entry in previews:
            if allocated >= total_questions:
                break
            selections.append({
                "skill": entry["skill"],
                "count": 1,
                "zone": "preview",
                "difficulty": PREVIEW_DIFFICULTY,
                "mastery": 0.01,
            })
            allocated += 1

    return selections