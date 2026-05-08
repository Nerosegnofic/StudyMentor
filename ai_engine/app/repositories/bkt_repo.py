from sqlalchemy.orm import Session
from app.models.domain import StudentSkillState, Skill, Subject

def get_student_skill_state(db: Session, student_uid: str, skill_name: str) -> StudentSkillState:
    """
    Returns the BKT state for a student/skill pair.
    Raises ValueError if the skill or the state does not exist.
    """
    skill = db.query(Skill).filter(Skill.name == skill_name).first()

    if not skill:
        raise ValueError(f"Skill '{skill_name}' does not exist in the curriculum database.")

    state = (
        db.query(StudentSkillState)
        .filter(
            StudentSkillState.student_uid == student_uid,
            StudentSkillState.skill_id == skill.skill_id,
        )
        .first()
    )

    if not state:
        # Create a default state if none exists
        state = StudentSkillState(
            student_uid=student_uid,
            skill_id=skill.skill_id,
            mastery_probability=0.01,  # Default starting mastery
            is_mastered=False,
            attempts=0
        )
        db.add(state)
        db.flush() # Ensure state has IDs but don't commit yet

    return state
