from typing import Dict, List
from sqlalchemy.orm import Session
from datetime import datetime, timedelta
from app.models.domain import StudentSkillState, Skill

def get_all_student_skill_states(db: Session, student_uid: str) -> Dict[str, float]:
    """Returns a dict mapping skill_name → mastery_probability for a student."""
    rows = (
        db.query(StudentSkillState, Skill)
        .join(Skill)
        .filter(StudentSkillState.student_uid == student_uid)
        .all()
    )
    return {skill.name: state.mastery_probability for state, skill in rows}

def get_subject_mastery_hierarchy(db: Session, student_uid: str, subject_id: int) -> List[Dict]:
    """
    Returns skills for a given subject grouped as Unit > Lesson,
    with each skill's current mastery probability for the student.
    """
    skills = (
        db.query(Skill)
        .filter(Skill.subject_id == subject_id)
        .order_by(Skill.unit_name, Skill.lesson_index, Skill.skill_id)
        .all()
    )

    skill_ids = [s.skill_id for s in skills]
    states = (
        db.query(StudentSkillState)
        .filter(
            StudentSkillState.student_uid == student_uid,
            StudentSkillState.skill_id.in_(skill_ids),
        )
        .all()
    )
    state_map: Dict[int, StudentSkillState] = {s.skill_id: s for s in states}

    units: Dict[str, Dict[str, list]] = {}
    for skill in skills:
        uname = skill.unit_name or "غير مصنف"
        lname = skill.lesson_name or "غير مصنف"
        units.setdefault(uname, {}).setdefault(lname, [])
        st = state_map.get(skill.skill_id)
        units[uname][lname].append({
            "skill_id": skill.skill_id,
            "name": skill.name,
            "mastery": round(st.mastery_probability, 4) if st else 0.0,
            "is_mastered": st.is_mastered if st else False,
            "attempts": st.attempts if st else 0,
        })

    result = []
    for uname, lessons in units.items():
        lesson_list = [{"lesson_name": lname, "skills": skill_list} for lname, skill_list in lessons.items()]
        result.append({"unit_name": uname, "lessons": lesson_list})

    return result

def get_subject_stats(db: Session, student_uid: str, subject_id: int) -> Dict:
    """
    Calculates aggregate analytics for a student in a given subject:
    - average_mastery: mean mastery probability across all skills
    - learning_velocity: proportion of skills practiced in the last 7 days
    - total_skills / mastered_skills counts
    """
    skills = db.query(Skill).filter(Skill.subject_id == subject_id).all()
    total_skills = len(skills)

    if not total_skills:
        return {"average_mastery": 0.0, "learning_velocity": 0.0, "total_skills": 0, "mastered_skills": 0}

    skill_ids = [s.skill_id for s in skills]
    states = (
        db.query(StudentSkillState)
        .filter(
            StudentSkillState.student_uid == student_uid,
            StudentSkillState.skill_id.in_(skill_ids),
        )
        .all()
    )

    if not states:
        return {"average_mastery": 0.0, "learning_velocity": 0.0, "total_skills": total_skills, "mastered_skills": 0}

    avg_mastery = sum(s.mastery_probability for s in states) / total_skills
    mastered_count = sum(1 for s in states if s.is_mastered)

    seven_days_ago = datetime.utcnow() - timedelta(days=7)
    recently_active = sum(1 for s in states if s.last_practiced and s.last_practiced >= seven_days_ago)
    velocity = recently_active / total_skills

    return {
        "average_mastery": round(avg_mastery, 4),
        "learning_velocity": round(velocity, 4),
        "total_skills": total_skills,
        "mastered_skills": mastered_count,
    }
