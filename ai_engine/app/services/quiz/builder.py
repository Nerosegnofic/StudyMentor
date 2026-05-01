from typing import Dict, List
from app.services.quiz.difficulty_mapper import mastery_to_difficulty
from app.services.quiz.priority_engine import compute_skill_priority_weight
from app.services.quiz.allocator import allocate_questions

def build_quiz_payload(
    student_profile: Dict[str, float],
    total_questions: int,
) -> List[Dict]:
    """
    Bridges the BKT mastery profile and the AI Quiz Generator by computing
    an optimal question distribution across skills.
    """
    if not student_profile or total_questions <= 0:
        return []

    # 1. Compute per-skill priority weights
    weights: Dict[str, float] = {
        skill: compute_skill_priority_weight(mastery)
        for skill, mastery in student_profile.items()
    }

    # 2. Distribute questions
    allocation = allocate_questions(weights, total_questions)

    # 3. Build the payload (skip zero-allocation skills)
    payload: List[Dict] = []
    for skill, count in allocation.items():
        if count <= 0:
            continue
        payload.append({
            "skill": skill,
            "difficulty": mastery_to_difficulty(student_profile[skill]),
            "count": count,
        })

    # 4. Sort payload: highest-count skills first
    payload.sort(key=lambda x: x["count"], reverse=True)

    return payload
