from typing import Dict, List
from app.services.quiz.difficulty_mapper import mastery_to_difficulty
from app.services.quiz.priority_engine import compute_skill_priority_weight
from app.services.quiz.allocator import allocate_questions

def build_quiz_payload(
    student_profile: Dict[str, float],
    total_questions: int,
    static_weights: Dict[str, float] = None
) -> List[Dict]:
    """
    Bridges the BKT mastery profile and the AI Quiz Generator by computing
    an optimal question distribution across skills.
    
    student_profile: Dictionary mapping skill_name -> mastery_probability
    static_weights: Dictionary mapping skill_name -> static ERD weight (default 1.0)
    """
    if not student_profile or total_questions <= 0:
        return []
        
    if static_weights is None:
        static_weights = {}

    # 1. Compute per-skill priority weights (Dynamic * Static)
    weights: Dict[str, float] = {}
    for skill, mastery in student_profile.items():
        dynamic_w = compute_skill_priority_weight(mastery)
        static_w = static_weights.get(skill, 1.0)
        weights[skill] = dynamic_w * static_w

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
