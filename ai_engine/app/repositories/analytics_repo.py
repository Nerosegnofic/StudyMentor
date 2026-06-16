from typing import Dict, List, Optional
from sqlalchemy.orm import Session
from datetime import datetime, timedelta
from app.models.domain import StudentSkillState, Skill, QuizSession

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
        .order_by(Skill.skill_id.asc())
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

    # Weight each skill's BKT probability by how much evidence exists.
    # A skill needs at least MIN_ATTEMPTS answers before its mastery is fully trusted.
    # This prevents 5 lucky correct answers from inflating the garden stage.
    MIN_ATTEMPTS = 20
    avg_mastery = sum(
        s.mastery_probability * min(1.0, s.attempts / MIN_ATTEMPTS)
        for s in states
    ) / total_skills
    mastered_count = sum(1 for s in states if s.is_mastered and s.attempts >= MIN_ATTEMPTS)

    seven_days_ago = datetime.utcnow() - timedelta(days=7)
    recently_active = sum(1 for s in states if s.last_practiced and s.last_practiced >= seven_days_ago)
    velocity = recently_active / total_skills

    return {
        "average_mastery": round(avg_mastery, 4),
        "learning_velocity": round(velocity, 4),
        "total_skills": total_skills,
        "mastered_skills": mastered_count,
    }


def get_recent_subject_accuracy(
    db: Session, student_uid: str, subject_id: int, limit: int = 3
) -> Optional[float]:
    """
    Average of the student's most recent quiz scores for a subject, as a 0–1 fraction.

    Returns None when there are no scored sessions yet. (QuizSession.score is persisted
    as a 0–100 percentage; this normalizes it so callers work in the same 0–1 space as
    mastery.)
    """
    sessions = (
        db.query(QuizSession)
        .filter(
            QuizSession.student_uid == student_uid,
            QuizSession.subject_id == subject_id,
            QuizSession.score.isnot(None),
        )
        .order_by(QuizSession.start_time.desc())
        .limit(max(1, limit))
        .all()
    )
    if not sessions:
        return None
    return (sum(s.score for s in sessions) / len(sessions)) / 100.0
