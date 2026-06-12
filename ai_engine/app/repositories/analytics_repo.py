from typing import Dict, List, Optional
from sqlalchemy.orm import Session
from sqlalchemy import or_
from datetime import datetime, timedelta
from app.models.domain import StudentSkillState, Skill, Subject, QuizSession, StudentSubjectProfile

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


# ═══════════════════════════════════════════════════════════════════════════
# Auto-Quiz Subject Prioritization
# ═══════════════════════════════════════════════════════════════════════════

def get_priority_subject(db: Session, student_uid: str) -> Optional[Subject]:
    """
    Selects the highest-priority subject for auto-generated quizzes.

    Scoring formula per subject:
        score = (mastery_gap * 40) + (neglect * 30) + (exam_urgency * 30)

    Components:
        mastery_gap  (0–1): How far the student is from mastery. (1 - avg_mastery)
                            Higher gap = needs more practice = higher score.
        neglect      (0–1): How long since this subject was last quizzed.
                            Normalized over 30 days; never quizzed = 1.0.
        exam_urgency (0–1): How close the exam is.
                            Exams within 7 days = 1.0; no exam = 0.0.

    Returns None if the student has no subjects with skills.
    """
    # Get globally shared subjects OR subjects owned by this specific student
    subjects = db.query(Subject).filter(
        or_(
            Subject.is_global == True,
            Subject.student_uid == student_uid
        )
    ).all()
    
    if not subjects:
        return None

    now = datetime.utcnow()
    scored: List[tuple] = []  # (score, subject)

    # Find the most recently quizzed subject to apply a rotation penalty
    last_session = (
        db.query(QuizSession)
        .filter(QuizSession.student_uid == student_uid)
        .order_by(QuizSession.start_time.desc())
        .first()
    )
    last_subject_id = last_session.subject_id if last_session else None

    for subj in subjects:
        stats = get_subject_stats(db, student_uid, subj.subject_id)

        # Skip subjects with no skills (nothing to quiz on)
        if stats["total_skills"] == 0:
            continue

        # ── Mastery Gap (0–1) ────────────────────────────────────────
        mastery_gap = 1.0 - stats["average_mastery"]

        # ── Neglect (0–1) ────────────────────────────────────────────
        # Use the last quiz session for this subject+student as the reference
        last_quiz_for_subject = (
            db.query(QuizSession)
            .filter(
                QuizSession.student_uid == student_uid,
                QuizSession.subject_id == subj.subject_id,
            )
            .order_by(QuizSession.start_time.desc())
            .first()
        )
        if last_quiz_for_subject and last_quiz_for_subject.start_time:
            days_since = (now - last_quiz_for_subject.start_time).total_seconds() / 86400
            neglect = min(1.0, days_since / 30.0)  # Cap at 1.0 after 30 days
        else:
            neglect = 1.0  # Never quizzed → maximum neglect

        # ── Exam Urgency (0–1) ───────────────────────────────────────
        profile = (
            db.query(StudentSubjectProfile)
            .filter(
                StudentSubjectProfile.student_uid == student_uid,
                StudentSubjectProfile.subject_id == subj.subject_id
            )
            .first()
        )
        
        exam_date = profile.exam_date if profile else None

        if exam_date and exam_date > now:
            days_until_exam = (exam_date - now).total_seconds() / 86400
            if days_until_exam <= 7:
                exam_urgency = 1.0
            elif days_until_exam <= 30:
                exam_urgency = 1.0 - ((days_until_exam - 7) / 23.0)  # Linear decay from 1.0 to 0.0
            else:
                exam_urgency = 0.0
        else:
            exam_urgency = 0.0  # No exam date set or exam already passed

        # ── Weighted Score ───────────────────────────────────────────
        score = (mastery_gap * 40) + (neglect * 30) + (exam_urgency * 30)

        # ── Rotation Penalty ─────────────────────────────────────────
        # If this was the last subject quizzed, reduce its score to encourage variety
        if subj.subject_id == last_subject_id:
            score *= 0.6

        scored.append((score, subj))

    if not scored:
        return None

    # Return the subject with the highest score
    scored.sort(key=lambda x: x[0], reverse=True)
    return scored[0][1]
