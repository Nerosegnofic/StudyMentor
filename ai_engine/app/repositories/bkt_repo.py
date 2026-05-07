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
        raise ValueError(f"Skill state not found for student '{student_uid}' on skill '{skill_name}'.")

    return state
