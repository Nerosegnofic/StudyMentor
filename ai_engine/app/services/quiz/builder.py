from typing import Dict, List

from sqlalchemy.orm import Session

from app.services.quiz.skill_selector import select_quiz_skills


def build_quiz_payload(
    db: Session,
    student_uid: str,
    subject_id: int,
    total_questions: int,
    student_grade: int = 5,
) -> List[Dict]:
    """
    Bridges the Ordered Frontier skill selector and the quiz generation route.

    Uses zone-classified skill selection (Frontier/Review/Preview) to produce
    the payload format expected by ``routes_quizzes.py``.

    Returns a list of dicts, each containing::

        {
            "skill":      str   — skill name,
            "difficulty":  int   — 1-5 difficulty target,
            "count":       int   — number of questions to generate,
            "zone":        str   — "frontier", "review", or "preview",
            "mastery":     float — current mastery probability,
        }
    """
    quiz_skills = select_quiz_skills(
        db, student_uid, subject_id, total_questions, student_grade
    )

    payload: List[Dict] = []
    for entry in quiz_skills:
        payload.append({
            "skill": entry["skill"].name,
            "difficulty": entry["difficulty"],
            "count": entry["count"],
            "zone": entry.get("zone", "frontier"),
            "mastery": entry.get("mastery", 0.0),
        })

    # Sort: highest-count skills first (frontier skills tend to have more questions)
    payload.sort(key=lambda x: x["count"], reverse=True)

    return payload
