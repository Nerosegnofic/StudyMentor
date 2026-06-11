"""
Ordered Frontier + SRS Skill Selector.

Classifies all skills in a subject into three zones for a student:
  - Frontier: actively learning (Zone of Proximal Development)
  - Mastered: previously learned, due for SRS review
  - Locked:   not yet unlocked (prerequisites not met)

Quiz composition draws from all three zones:
  60% Frontier | 30% SRS Review | 10% Preview of locked skills

The frontier window (how many unmastered skills are active at once)
is configurable per grade level to match cognitive capacity.
"""

import random
from typing import Dict, List

from sqlalchemy.orm import Session

from app.models.domain import Skill, StudentSkillState
from app.services.quiz.difficulty_mapper import mastery_to_difficulty
from app.services.quiz.srs_scheduler import select_srs_review_skills


# ---------------------------------------------------------------------------
# Thresholds
# ---------------------------------------------------------------------------

# Mastery probability needed to "unlock" the next sequential skill.
# 0.70 is permissive — the student has demonstrated solid competence (~70%)
# and SRS review will reinforce retention in the background.
UNLOCK_THRESHOLD = 0.70

# Preview questions are always Very Easy (recall-only) — just a taste
# of what's coming next to build curiosity.
PREVIEW_DIFFICULTY = 1

# Grade → frontier window size.
# Younger students get a narrower focus to prevent cognitive overload.
FRONTIER_WINDOW_BY_GRADE: Dict[int, int] = {
    1: 2, 2: 2,             # Grades 1-2: narrow focus for young learners
    3: 3, 4: 3,             # Grades 3-4: standard
    5: 4, 6: 4,             # Grades 5-6: wider
    7: 5, 8: 5, 9: 5,       # Grades 7-9
    10: 5, 11: 5, 12: 5,    # Grades 10-12
}

DEFAULT_FRONTIER_WINDOW = 3


# ---------------------------------------------------------------------------
# Zone Classification
# ---------------------------------------------------------------------------

def classify_skills(
    db: Session,
    student_uid: str,
    subject_id: int,
    frontier_window: int = DEFAULT_FRONTIER_WINDOW,
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
    # Get all skills ordered by curriculum sequence
    all_skills = (
        db.query(Skill)
        .filter(Skill.subject_id == subject_id)
        .order_by(Skill.lesson_index.asc(), Skill.skill_id.asc())
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

        if mastery >= UNLOCK_THRESHOLD:
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
    frontier_window = FRONTIER_WINDOW_BY_GRADE.get(
        student_grade, DEFAULT_FRONTIER_WINDOW
    )
    zones = classify_skills(db, student_uid, subject_id, frontier_window)

    # ── Calculate question allocation per zone ────────────────────
    frontier_budget = max(1, round(total_questions * 0.60))
    review_budget = max(0, round(total_questions * 0.30))
    preview_budget = max(0, total_questions - frontier_budget - review_budget)

    # Redistribute budget from empty zones to non-empty ones
    if not zones["frontier"]:
        review_budget += frontier_budget
        frontier_budget = 0
    if not zones["mastered"]:
        if zones["frontier"]:
            frontier_budget += review_budget
        else:
            preview_budget += review_budget
        review_budget = 0
    if not zones["locked"]:
        if zones["frontier"]:
            frontier_budget += preview_budget
        elif zones["mastered"]:
            review_budget += preview_budget
        preview_budget = 0

    selections: List[dict] = []
    allocated = 0

    # ── Frontier Skills (60%) ─────────────────────────────────────
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

    # ── SRS Review (30%) ──────────────────────────────────────────
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

    # ── Preview / Exploration (10%) ───────────────────────────────
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
