from typing import Dict, List, Optional
from sqlalchemy.orm import Session
from datetime import datetime, timedelta
from sqlalchemy import or_, func
from datetime import datetime, timedelta
from app.core.config import settings
from app.models.domain import (
    StudentSkillState,
    Skill,
    Subject,
    QuizSession,
    StudentSubjectProfile,
    Question,
    QuestionResponse,
    MasterySnapshot,
    GardenPlant,
)

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

def get_study_time_series(
    db: Session,
    student_uid: str,
    anchor_date=None,
    heatmap_days: int = 28,
    daily_days: int = 7,
):
    """
    Returns two real study-time series for the Habits tab:
      - heatmap: one entry per day for the last `heatmap_days` (oldest first),
                 each {date, study_minutes}
      - daily:   the last `daily_days` as [{day_label, study_minutes}]
    Study minutes are summed from completed quiz sessions, grouped by the day
    the session started.
    """
    today = anchor_date or datetime.utcnow().date()
    start = today - timedelta(days=heatmap_days - 1)
    start_dt = datetime(start.year, start.month, start.day)

    sessions = (
        db.query(QuizSession)
        .filter(
            QuizSession.student_uid == student_uid,
            QuizSession.start_time >= start_dt,
            QuizSession.end_time.isnot(None),
        )
        .all()
    )

    minutes_by_date: Dict = {}
    for s in sessions:
        if s.start_time is None or s.end_time is None:
            continue
        d = s.start_time.date()
        minutes_by_date[d] = minutes_by_date.get(d, 0) + int(
            (s.end_time - s.start_time).total_seconds() / 60
        )

    heatmap = [
        {
            "date": (start + timedelta(days=i)).isoformat(),
            "study_minutes": minutes_by_date.get(start + timedelta(days=i), 0),
        }
        for i in range(heatmap_days)
    ]

    day_labels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    daily = []
    for i in range(daily_days):
        d = today - timedelta(days=daily_days - 1 - i)
        daily.append(
            {"day_label": day_labels[d.weekday()], "study_minutes": minutes_by_date.get(d, 0)}
        )

    return heatmap, daily


def upsert_mastery_snapshot(
    db: Session,
    student_uid: str,
    subject_id: int,
    mastery_percent: float,
    on_date=None,
) -> None:
    """Record (or update) today's mastery snapshot for one student + subject."""
    on_date = on_date or datetime.utcnow().date()
    snap = (
        db.query(MasterySnapshot)
        .filter_by(student_uid=student_uid, subject_id=subject_id, recorded_on=on_date)
        .first()
    )
    if snap:
        snap.mastery_percent = mastery_percent
    else:
        db.add(
            MasterySnapshot(
                student_uid=student_uid,
                subject_id=subject_id,
                mastery_percent=mastery_percent,
                recorded_on=on_date,
            )
        )
    db.flush()


def get_mastery_history(db: Session, student_uid: str, subject_id: int, days: int = 30) -> List[Dict]:
    """Ordered daily mastery snapshots (oldest first) for the last `days`."""
    since = datetime.utcnow().date() - timedelta(days=days - 1)
    rows = (
        db.query(MasterySnapshot)
        .filter(
            MasterySnapshot.student_uid == student_uid,
            MasterySnapshot.subject_id == subject_id,
            MasterySnapshot.recorded_on >= since,
        )
        .order_by(MasterySnapshot.recorded_on)
        .all()
    )
    return [
        {"date": r.recorded_on.isoformat(), "mastery": round(r.mastery_percent, 1)}
        for r in rows
    ]


def get_time_of_day_distribution(
    db: Session,
    student_uid: str,
    tz_offset_minutes: int = 0,
    days: int = 30,
) -> List[Dict]:
    """
    Study minutes grouped by part of the day (in the student's local time) over
    the last `days`. `tz_offset_minutes` is the client's offset from UTC so the
    buckets reflect the student's actual morning/afternoon/evening/night.
    """
    since = datetime.utcnow() - timedelta(days=days)
    sessions = (
        db.query(QuizSession)
        .filter(
            QuizSession.student_uid == student_uid,
            QuizSession.start_time >= since,
            QuizSession.end_time.isnot(None),
        )
        .all()
    )

    buckets = {"Morning": 0, "Afternoon": 0, "Evening": 0, "Night": 0}
    offset = timedelta(minutes=tz_offset_minutes)
    for s in sessions:
        if s.start_time is None or s.end_time is None:
            continue
        hour = (s.start_time + offset).hour
        minutes = int((s.end_time - s.start_time).total_seconds() / 60)
        if 5 <= hour < 12:
            buckets["Morning"] += minutes
        elif 12 <= hour < 17:
            buckets["Afternoon"] += minutes
        elif 17 <= hour < 21:
            buckets["Evening"] += minutes
        else:
            buckets["Night"] += minutes

    return [{"label": label, "minutes": minutes} for label, minutes in buckets.items()]


def get_daily_snapshot_stats(db: Session, student_uid: str, anchor_date=None) -> Dict:
    """Today's quiz count, study minutes, and average accuracy for one student."""
    today = anchor_date or datetime.utcnow().date()
    sessions = (
        db.query(QuizSession)
        .filter(
            QuizSession.student_uid == student_uid,
            func.date(QuizSession.start_time) == today,
            QuizSession.end_time.isnot(None),
        )
        .all()
    )
    study_minutes = sum(
        int((s.end_time - s.start_time).total_seconds() / 60)
        for s in sessions
        if s.start_time and s.end_time
    )
    scored = [s.score for s in sessions if s.score is not None]
    accuracy = int(sum(scored) / len(scored)) if scored else 0
    return {
        "quizzes_today": len(sessions),
        "study_minutes_today": study_minutes,
        "accuracy_today": accuracy,
    }


def get_window_summary(db: Session, student_uid: str, start, end) -> Dict:
    """Quiz count, study minutes, and accuracy for completed sessions in [start, end)."""
    sessions = (
        db.query(QuizSession)
        .filter(
            QuizSession.student_uid == student_uid,
            QuizSession.start_time >= start,
            QuizSession.start_time < end,
            QuizSession.end_time.isnot(None),
        )
        .all()
    )
    study_minutes = sum(
        int((s.end_time - s.start_time).total_seconds() / 60)
        for s in sessions
        if s.start_time and s.end_time
    )
    scored = [s.score for s in sessions if s.score is not None]
    accuracy = round(sum(scored) / len(scored), 1) if scored else 0.0
    return {"quizzes": len(sessions), "study_minutes": study_minutes, "accuracy": accuracy}


def get_weakest_subject(db: Session, student_uid: str) -> Optional[Dict]:
    """The student's lowest-mastery subject that has some activity, or None."""
    row = (
        db.query(GardenPlant, Subject)
        .join(Subject, GardenPlant.subject_id == Subject.subject_id)
        .filter(
            GardenPlant.student_uid == student_uid,
            GardenPlant.mastery_percent > 0,
        )
        .order_by(GardenPlant.mastery_percent.asc())
        .first()
    )
    if not row:
        return None
    plant, subject = row
    return {"name": subject.name, "mastery": round(plant.mastery_percent, 1)}


def summarize_quiz_effort(sessions: List[QuizSession]) -> Dict:
    """
    Pure aggregation over a list of quiz sessions (no DB access):
      - voluntary_quizzes / forced_quizzes: self-started vs taken to unlock apps
      - guessing_sessions: sessions where rapid guessing made up at least
        settings.GUESSING_SESSION_SPAM_FRACTION of the quiz's questions
    """
    voluntary = forced = guessing_sessions = 0
    for s in sessions:
        if (s.quiz_context or "VOLUNTARY").upper() == "FORCED":
            forced += 1
        else:
            voluntary += 1

        total_q = s.total_questions or 0
        spam = s.consecutive_spam_clicks or 0
        if total_q > 0 and (spam / total_q) >= settings.GUESSING_SESSION_SPAM_FRACTION:
            guessing_sessions += 1
    return {
        "voluntary_quizzes": voluntary,
        "forced_quizzes": forced,
        "guessing_sessions": guessing_sessions,
    }


def get_subject_time_allocation(db: Session, sessions: List[QuizSession]) -> List[Dict]:
    """
    Given a list of completed quiz sessions, returns each subject's share of the
    total study minutes as [{subject_key, percentage, color_hex}], sorted from
    most to least time. Returns an empty list when there is no study time.
    """
    subject_minutes: Dict[int, int] = {}
    for s in sessions:
        if s.subject_id is None or s.start_time is None or s.end_time is None:
            continue
        minutes = int((s.end_time - s.start_time).total_seconds() / 60)
        subject_minutes[s.subject_id] = subject_minutes.get(s.subject_id, 0) + minutes

    total = sum(subject_minutes.values())
    if total <= 0:
        return []

    rows = (
        db.query(Subject)
        .filter(Subject.subject_id.in_(list(subject_minutes.keys())))
        .all()
    )
    meta = {r.subject_id: (r.name, r.color_hex) for r in rows}

    allocations: List[Dict] = []
    for sid, minutes in sorted(subject_minutes.items(), key=lambda kv: kv[1], reverse=True):
        name, color = meta.get(sid, (f"Subject {sid}", None))
        allocations.append({
            "subject_key": name,
            "percentage": round(minutes / total * 100, 1),
            "color_hex": color or "#2196F3",
        })
    return allocations


def get_error_and_difficulty_breakdown(db: Session, student_uid: str, subject_id: int) -> Dict:
    """
    For one student + subject, classifies every wrong answer as careless /
    concept-gap / guessing, and computes accuracy per difficulty band (1–5).
    Thresholds come from `settings` (quizzes are not timed → no time-pressure bucket).

    Classification (wrong answers only, first match wins):
      - guessing    → answered in under settings.MINIMUM_GENUINE_TIME_MS
      - careless    → quick answer (< settings.CARELESS_MAX_TIME_MS) on material the
                      student should know (mastery ≥ settings.CARELESS_KNOWN_MASTERY
                      or difficulty ≤ 2)
      - concept-gap → everything else (slow miss, low mastery, or hints used)
    """
    rows = (
        db.query(
            QuestionResponse.is_correct,
            QuestionResponse.time_taken_ms,
            QuestionResponse.hints_used,
            Question.difficulty,
            Question.skill_id,
        )
        .join(Question, QuestionResponse.question_id == Question.question_id)
        .join(Skill, Question.skill_id == Skill.skill_id)
        .filter(
            QuestionResponse.student_uid == student_uid,
            Skill.subject_id == subject_id,
        )
        .all()
    )

    # Mastery per skill, to tell "knew it but slipped" from a genuine gap.
    mastery_map = {
        st.skill_id: st.mastery_probability
        for st in (
            db.query(StudentSkillState)
            .join(Skill, StudentSkillState.skill_id == Skill.skill_id)
            .filter(
                StudentSkillState.student_uid == student_uid,
                Skill.subject_id == subject_id,
            )
            .all()
        )
    }

    careless = concept = guessing = 0
    diff_counts = {d: [0, 0] for d in range(1, 6)}  # difficulty → [total, correct]

    for is_correct, time_ms, hints_used, difficulty, skill_id in rows:
        d = difficulty if difficulty in diff_counts else max(1, min(5, difficulty or 1))
        diff_counts[d][0] += 1
        if is_correct:
            diff_counts[d][1] += 1
            continue

        time_ms = time_ms or 0
        mastery = mastery_map.get(skill_id, 0.0)
        if time_ms < settings.MINIMUM_GENUINE_TIME_MS:
            guessing += 1
        elif time_ms < settings.CARELESS_MAX_TIME_MS and (
            mastery >= settings.CARELESS_KNOWN_MASTERY or d <= 2
        ):
            careless += 1
        else:
            concept += 1

    total_errors = careless + concept + guessing

    def pct(x: int) -> float:
        return round(x / total_errors * 100, 1) if total_errors else 0.0

    difficulty_accuracy = [
        {
            "difficulty": d,
            "total": diff_counts[d][0],
            "accuracy": (
                round(diff_counts[d][1] / diff_counts[d][0] * 100, 1)
                if diff_counts[d][0]
                else 0.0
            ),
        }
        for d in range(1, 6)
    ]

    return {
        "error_breakdown": {
            "careless_percent": pct(careless),
            "concept_gap_percent": pct(concept),
            "guessing_percent": pct(guessing),
            "total_errors": total_errors,
        },
        "difficulty_accuracy": difficulty_accuracy,
    }


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

    # Garden/subject mastery reflects how well the student knows the skills they
    # have actually practiced. Untouched skills are excluded so a large curriculum
    # doesn't pin the plant near 0% (the old `/ total_skills` capped growth at
    # practiced/total). The gentle per-question mastery_step (see BKTConfig) is what
    # now guards against a few lucky answers inflating the stage.
    attempted = [s for s in states if s.attempts > 0]
    avg_mastery = (
        sum(s.mastery_probability for s in attempted) / len(attempted)
        if attempted else 0.0
    )
    mastered_count = sum(1 for s in attempted if s.is_mastered)

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
