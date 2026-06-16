from datetime import datetime
from fastapi import APIRouter, HTTPException, Depends, Query
from pydantic import BaseModel
from typing import List, Optional
from sqlalchemy.orm import Session
from sqlalchemy import func, or_
from app.core.database import get_db
from app.core.auth import get_current_user
from app.repositories.vector_repo import delete_vector_embeddings_by_subject
from app.repositories.subject_repo import delete_subject_cascade
from app.repositories import (
    get_subject_mastery_hierarchy,
    get_subject_stats,
    get_error_and_difficulty_breakdown,
    get_mastery_history,
    get_subject_by_id,
)
from app.repositories.analytics_repo import get_daily_snapshot_stats, get_weakest_subject
from app.repositories.gamification_repo import get_or_create_student_gamification
from app.services.evaluation.analytics_service import (
    enrich_hierarchy_with_status,
    get_overall_dashboard_stats,
)
from app.services.evaluation.insights import build_daily_summary
from app.models.schemas import DailySummaryRequest
from collections import defaultdict
from app.models.domain import (
    Subject,
    QuizSession,
    GardenPlant,
    Question,
    QuestionResponse,
    Skill,
    MasterySnapshot,
)
from app.models.domain.student import StudentSubjectProfile, StudentSkillState
from app.models.domain.gamification import (
    StudentGamification,
    XpTransaction,
    CoinTransaction,
    StreakEvent,
)

router = APIRouter(prefix="/analytics", tags=["Analytics Dashboard"])

# ═══════════════════════════════════════════════════════════════════════════
# GET  /analytics/subjects   — List all subjects with high-level stats
# ═══════════════════════════════════════════════════════════════════════════

@router.get("/subjects")
def list_subjects_analytics(
    student_uid: Optional[str] = Query(None),
    db: Session = Depends(get_db),
    current_user: str = Depends(get_current_user),
):
    """
    Returns every subject the student is enrolled in, with:
    - average mastery %
    - learning velocity (recent activity proxy)
    - color hex for the UI
    """
    target_uid = student_uid if student_uid else current_user
    subjects = db.query(Subject).filter(
        or_(Subject.is_global == True, Subject.student_uid == target_uid)
    ).all()

    # Query cached garden plants to match the student-side garden exactly
    plant_map = {
        p.subject_id: p.mastery_percent
        for p in db.query(GardenPlant).filter_by(student_uid=target_uid).all()
    }

    results = []
    for subj in subjects:
        stats = get_subject_stats(db, target_uid, subj.subject_id)
        
        cached_mastery = plant_map.get(subj.subject_id)
        average_mastery = (cached_mastery / 100.0) if cached_mastery is not None else stats["average_mastery"]

        results.append({
            "subject_id": subj.subject_id,
            "name": subj.name,
            "color_hex": subj.color_hex,
            "average_mastery": average_mastery,
            "learning_velocity": stats["learning_velocity"],
            "total_skills": stats["total_skills"],
            "mastered_skills": stats["mastered_skills"],
        })
    return results


# ═══════════════════════════════════════════════════════════════════════════
# GET  /analytics/subjects/{id}/mastery   — Hierarchical skill tree
# ═══════════════════════════════════════════════════════════════════════════

@router.get("/subjects/{subject_id}/mastery")
def get_subject_mastery_tree(
    subject_id: int,
    student_uid: Optional[str] = Query(None),
    db: Session = Depends(get_db),
    current_user: str = Depends(get_current_user),
):
    """
    Returns the Unit > Lesson > Skill mastery tree for a single subject.
    Each skill node includes: mastery, status (LOCKED/ACTIVE/MASTERED), attempts.
    """
    target_uid = student_uid if student_uid else current_user
    subject = db.query(Subject).filter(Subject.subject_id == subject_id).first()
    if not subject:
        raise HTTPException(status_code=404, detail="Subject not found.")

    hierarchy = get_subject_mastery_hierarchy(db, target_uid, subject_id)
    enriched = enrich_hierarchy_with_status(hierarchy)

    return {
        "subject_id": subject.subject_id,
        "subject_name": subject.name,
        "units": enriched,
    }


# ═══════════════════════════════════════════════════════════════════════════
# GET  /analytics/subjects/{id}/mastery-history — Daily mastery snapshots
# ═══════════════════════════════════════════════════════════════════════════

@router.get("/subjects/{subject_id}/mastery-history")
def get_subject_mastery_history(
    subject_id: int,
    days: int = Query(30, ge=2, le=365),
    student_uid: Optional[str] = Query(None),
    db: Session = Depends(get_db),
    current_user: str = Depends(get_current_user),
):
    """Returns ordered daily mastery snapshots (oldest first) for one subject."""
    target_uid = student_uid if student_uid else current_user
    if not get_subject_by_id(db, subject_id):
        raise HTTPException(status_code=404, detail="Subject not found.")

    return {
        "subject_id": subject_id,
        "history": get_mastery_history(db, target_uid, subject_id, days=days),
    }


# ═══════════════════════════════════════════════════════════════════════════
# GET  /analytics/subjects/{id}/error-breakdown — Error types + difficulty accuracy
# ═══════════════════════════════════════════════════════════════════════════

@router.get("/subjects/{subject_id}/error-breakdown")
def get_subject_error_breakdown(
    subject_id: int,
    student_uid: Optional[str] = Query(None),
    db: Session = Depends(get_db),
    current_user: str = Depends(get_current_user),
):
    """
    Returns the careless / concept-gap / guessing error split and per-difficulty
    accuracy for a student in a single subject.
    """
    target_uid = student_uid if student_uid else current_user
    if not get_subject_by_id(db, subject_id):
        raise HTTPException(status_code=404, detail="Subject not found.")

    data = get_error_and_difficulty_breakdown(db, target_uid, subject_id)
    return {"subject_id": subject_id, **data}


# ═══════════════════════════════════════════════════════════════════════════
# GET  /analytics/subjects/{id}/history   — Paginated quiz history
# ═══════════════════════════════════════════════════════════════════════════

@router.get("/subjects/{subject_id}/history")
def get_subject_quiz_history(
    subject_id: int,
    page: int = Query(1, ge=1),
    page_size: int = Query(10, ge=1, le=200),
    student_uid: Optional[str] = Query(None),
    db: Session = Depends(get_db),
    current_user: str = Depends(get_current_user),
):
    """
    Returns paginated quiz session history for a given subject.
    """
    target_uid = student_uid if student_uid else current_user
    subject = db.query(Subject).filter(Subject.subject_id == subject_id).first()
    if not subject:
        raise HTTPException(status_code=404, detail="Subject not found.")

    query = (
        db.query(QuizSession)
        .filter(
            QuizSession.student_uid == target_uid,
            QuizSession.subject_id == subject_id,
        )
        .order_by(QuizSession.start_time.desc())
    )

    total = query.count()
    sessions = query.offset((page - 1) * page_size).limit(page_size).all()
    session_ids = [s.session_id for s in sessions]

    # Batch: correct question IDs per session (avoids N+1)
    correct_q_records = (
        db.query(Question.session_id, Question.question_id)
        .join(QuestionResponse, QuestionResponse.question_id == Question.question_id)
        .filter(
            Question.session_id.in_(session_ids),
            QuestionResponse.student_uid == target_uid,
            QuestionResponse.is_correct == True,
        )
        .all()
    )
    correct_ids_by_session = defaultdict(set)
    for (sid, qid) in correct_q_records:
        correct_ids_by_session[str(sid)].add(str(qid))

    # Batch: questions with skill name per session, ordered for stable numbering
    all_q_rows = (
        db.query(Question.session_id, Question.question_id, Question.created_at, Skill.name)
        .join(Skill, Question.skill_id == Skill.skill_id)
        .filter(Question.session_id.in_(session_ids))
        .order_by(Question.session_id, Question.created_at)
        .all()
    )
    questions_by_session = defaultdict(list)
    for (sid, qid, created_at, skill_name) in all_q_rows:
        questions_by_session[str(sid)].append({"qid": str(qid), "skill": skill_name})

    items = []
    for s in sessions:
        sid_str = str(s.session_id)
        qs = questions_by_session.get(sid_str, [])
        qid_to_num = {q["qid"]: i + 1 for i, q in enumerate(qs)}
        correct_ids = correct_ids_by_session.get(sid_str, set())
        correct_answer_numbers = sorted(
            qid_to_num[qid] for qid in correct_ids if qid in qid_to_num
        )
        correct_count = len(correct_ids)
        skill_tag = qs[0]["skill"] if qs else None
        score_val = s.score
        passed = (score_val >= 60) if score_val is not None else False

        items.append({
            "session_id": sid_str,
            "start_time": s.start_time.isoformat() if s.start_time else None,
            "end_time": s.end_time.isoformat() if s.end_time else None,
            "total_questions": s.total_questions,
            "score": score_val,
            "correct_answers": correct_count,
            "passed": passed,
            "skill_tag": skill_tag,
            "correct_answer_numbers": correct_answer_numbers,
        })

    return {
        "subject_id": subject_id,
        "page": page,
        "page_size": page_size,
        "total": total,
        "sessions": items,
    }


# ═══════════════════════════════════════════════════════════════════════════
# GET  /analytics/overall   — Global dashboard stats
# ═══════════════════════════════════════════════════════════════════════════

@router.get("/overall")
def get_overall_analytics(
    db: Session = Depends(get_db),
    student_uid: str = Depends(get_current_user),
):
    """
    Global dashboard:
    - Total skills tracked & mastered across all subjects
    - Activity heatmap (sessions grouped by date for the last 30 days)
    """
    return get_overall_dashboard_stats(db, student_uid)


# ═══════════════════════════════════════════════════════════════════════════
# POST /analytics/parent/daily-summary — Per-child daily summary for parent home
# ═══════════════════════════════════════════════════════════════════════════

@router.post("/parent/daily-summary")
def parent_daily_summary(
    body: DailySummaryRequest,
    db: Session = Depends(get_db),
    _caller: str = Depends(get_current_user),
):
    """
    Build the parent-home AI Daily Summary: a household headline (with 2+ children)
    plus one slide per child, generated fresh from each child's real data.
    """
    anchor = None
    if body.client_local_date:
        try:
            anchor = datetime.strptime(body.client_local_date, "%Y-%m-%d").date()
        except ValueError:
            anchor = None
    today = anchor or datetime.utcnow().date()

    children_signals = []
    for child in body.children:
        snap = get_daily_snapshot_stats(db, child.uid, anchor)
        gam = get_or_create_student_gamification(db, child.uid)

        days_since_last_quiz = None
        if gam.last_quiz_date:
            last_q = gam.last_quiz_date
            last_q = last_q.date() if hasattr(last_q, "date") else last_q
            days_since_last_quiz = (today - last_q).days

        children_signals.append({
            "child_uid": child.uid,
            "name": child.name,
            "quizzes_today": snap["quizzes_today"],
            "study_minutes_today": snap["study_minutes_today"],
            "accuracy_today": snap["accuracy_today"],
            "current_streak": gam.current_streak,
            "days_since_last_quiz": days_since_last_quiz,
            "weakest_subject": get_weakest_subject(db, child.uid),
        })

    return {
        "slides": build_daily_summary(children_signals),
        "generated_at": datetime.utcnow().isoformat(),
    }


# ═══════════════════════════════════════════════════════════════════════════
# POST /analytics/subjects/ensure  — Create Subject rows for assigned subjects
# ═══════════════════════════════════════════════════════════════════════════

class _EnsureSubjectsBody(BaseModel):
    student_uid: str
    subject_names: List[str]


@router.post("/subjects/ensure")
def ensure_subjects(
    body: _EnsureSubjectsBody,
    db: Session = Depends(get_db),
    _: str = Depends(get_current_user),
):
    """
    Ensures a Subject row exists for each assigned subject name.
    Called when a parent assigns subjects to a student so they appear in
    the Knowledge Garden. Skips names that already exist (case-insensitive).
    """
    created = []
    for name in body.subject_names:
        existing = db.query(Subject).filter(
            func.lower(Subject.name) == name.lower(),
            Subject.student_uid == body.student_uid,
        ).first()
        if not existing:
            db.add(Subject(name=name, student_uid=body.student_uid, is_global=False))
            created.append(name)
    if created:
        db.commit()
    return {"ensured": len(body.subject_names), "created": created}


# ═══════════════════════════════════════════════════════════════════════════
# DELETE /analytics/subjects/{subject_name}  — Wipe custom subject securely
# ═══════════════════════════════════════════════════════════════════════════

@router.delete("/subjects/{subject_name}")
def delete_subject(
    subject_name: str,
    student_uid: str = Query(...),
    db: Session = Depends(get_db),
    _: str = Depends(get_current_user),
):
    """
    Deletes a custom subject and all its associated data for a specific student.
    Uses delete_subject_cascade() which handles FK ordering:
    QuizSessions → StudentSubjectProfile → Subject (ORM cascades Skills/Documents)
    + vector embeddings + debug artifacts cleanup.
    Only deletes subjects owned by the student (not global subjects).
    """
    subject = db.query(Subject).filter(
        func.lower(Subject.name) == subject_name.lower(),
        Subject.student_uid == student_uid,
        Subject.is_global == False,
    ).first()
    if not subject:
        raise HTTPException(status_code=404, detail="Subject not found or not owned by this student.")

    subject_id = subject.subject_id

    deleted = delete_subject_cascade(db, subject_id)
    if not deleted:
        raise HTTPException(status_code=500, detail="Failed to delete subject data.")

    return {"deleted": subject_name}


# ═══════════════════════════════════════════════════════════════════════════
# DELETE /analytics/students/{student_uid}  — Wipe all AI-engine data for a student
# ═══════════════════════════════════════════════════════════════════════════

# ═══════════════════════════════════════════════════════════════════════════
# GET  /analytics/sessions/{session_id}/questions  — Per-question review data
# ═══════════════════════════════════════════════════════════════════════════

@router.get("/sessions/{session_id}/questions")
def get_session_questions(
    session_id: str,
    student_uid: Optional[str] = Query(None),
    db: Session = Depends(get_db),
    current_user: str = Depends(get_current_user),
):
    """
    Returns every question in a quiz session together with the student's
    selected answer and correctness, ordered by creation time (question 1 first).
    """
    target_uid = student_uid if student_uid else current_user

    session = db.query(QuizSession).filter(QuizSession.session_id == session_id).first()
    if not session:
        raise HTTPException(status_code=404, detail="Session not found.")
    if session.student_uid != target_uid:
        raise HTTPException(status_code=403, detail="Not authorized.")

    questions = (
        db.query(Question)
        .filter(Question.session_id == session_id)
        .order_by(Question.created_at)
        .all()
    )
    q_ids = [q.question_id for q in questions]

    responses = (
        db.query(QuestionResponse)
        .filter(
            QuestionResponse.question_id.in_(q_ids),
            QuestionResponse.student_uid == target_uid,
        )
        .all()
    )
    resp_map = {str(r.question_id): r for r in responses}

    result = []
    for i, q in enumerate(questions):
        r = resp_map.get(str(q.question_id))
        result.append({
            "question_number": i + 1,
            "question_text": q.text_content,
            "options": q.options,
            "correct_answer": q.correct_answer,
            "selected_answer": r.selected_option if r else None,
            "is_correct": r.is_correct if r else False,
        })

    return {"session_id": session_id, "questions": result}


@router.delete("/students/{student_uid}")
def delete_student_all_data(
    student_uid: str,
    db: Session = Depends(get_db),
    _: str = Depends(get_current_user),
):
    """
    Deletes every AI-engine record for a student.
    Called by the parent app when the parent permanently deletes a student account.
    The caller's JWT (parent) is used only for authentication; the student_uid
    in the path identifies whose data to wipe.
    """
    # 1. Gamification transaction logs — must go before quiz_sessions (FK xp_transactions.quiz_session_id)
    db.query(XpTransaction).filter(XpTransaction.student_uid == student_uid).delete(synchronize_session=False)
    db.query(CoinTransaction).filter(CoinTransaction.student_uid == student_uid).delete(synchronize_session=False)
    db.query(StreakEvent).filter(StreakEvent.student_uid == student_uid).delete(synchronize_session=False)
    db.query(StudentGamification).filter(StudentGamification.student_uid == student_uid).delete(synchronize_session=False)

    # 2. Skill states (FK to skills, safe to bulk-delete before subjects)
    db.query(StudentSkillState).filter(StudentSkillState.student_uid == student_uid).delete(synchronize_session=False)

    # 3. Subject-linked rows (FK to subjects — must go before Subject deletion)
    db.query(StudentSubjectProfile).filter(StudentSubjectProfile.student_uid == student_uid).delete(synchronize_session=False)
    db.query(GardenPlant).filter(GardenPlant.student_uid == student_uid).delete(synchronize_session=False)
    db.query(MasterySnapshot).filter(MasterySnapshot.student_uid == student_uid).delete(synchronize_session=False)

    # 4. Quiz sessions — load each so SQLAlchemy cascades to questions → responses
    for session in db.query(QuizSession).filter(QuizSession.student_uid == student_uid).all():
        db.delete(session)

    # 5. Custom subjects — cascade: skills → skill_states (already gone), chunks, questions (already gone)
    custom_subjects = db.query(Subject).filter(Subject.student_uid == student_uid).all()
    custom_subject_ids = [s.subject_id for s in custom_subjects]
    for subject in custom_subjects:
        db.delete(subject)

    db.commit()

    # 6. Vector embeddings live outside the ORM — clean up best-effort
    for subject_id in custom_subject_ids:
        try:
            delete_vector_embeddings_by_subject(subject_id)
        except Exception as e:
            print(f"[DeleteStudent] Vector cleanup failed subject_id={subject_id}: {e}", flush=True)

    return {"deleted": student_uid}
