from sqlalchemy.orm import Session
from app.models.domain import StudentSkillState, StudentBKTProfile, Skill, Subject

def get_student_bkt_profile(db: Session, student_uid: str) -> StudentBKTProfile:
    profile = (
        db.query(StudentBKTProfile)
        .filter(StudentBKTProfile.student_uid == student_uid)
        .first()
    )
    if not profile:
        profile = StudentBKTProfile(student_uid=student_uid)
        db.add(profile)
        db.commit()
        db.refresh(profile)
    return profile

def get_student_skill_state(db: Session, student_uid: str, skill_name: str) -> StudentSkillState:
    """
    Returns (and auto-creates) the BKT state for a student/skill pair.
    Skills should already exist after RAG ingestion; the fallback here
    handles edge cases (e.g., developer testing without a full corpus).
    """
    skill = db.query(Skill).filter(Skill.name == skill_name).first()

    if not skill:
        # Ensure the default subject exists, then create the skill
        default_subject = db.query(Subject).filter(Subject.subject_id == 1).first()
        if not default_subject:
            default_subject = Subject(subject_id=1, name="General")
            db.add(default_subject)
            db.flush()

        skill = Skill(subject_id=1, name=skill_name)
        db.add(skill)
        db.commit()
        db.refresh(skill)

    state = (
        db.query(StudentSkillState)
        .filter(
            StudentSkillState.student_uid == student_uid,
            StudentSkillState.skill_id == skill.skill_id,
        )
        .first()
    )

    if not state:
        state = StudentSkillState(
            student_uid=student_uid,
            skill_id=skill.skill_id,
            mastery_probability=0.01,
        )
        db.add(state)
        db.commit()
        db.refresh(state)

    return state
