from fastapi import APIRouter, HTTPException, Depends, Query
from sqlalchemy.orm import Session
from sqlalchemy import func, cast, Date
from app.core.database import get_db
from app.core.auth import get_current_user
from datetime import datetime, timedelta
from app.repositories import (
    get_subject_mastery_hierarchy,
    get_subject_stats,
)
from app.services.evaluation.analytics_service import (
    enrich_hierarchy_with_status,
)
from app.models.domain import (
    Skill,
    Subject,
    QuizSession,
    StudentSkillState,
)

router = APIRouter(prefix="/analytics", tags=["Analytics Dashboard"])

# ═══════════════════════════════════════════════════════════════════════════
# GET  /analytics/subjects   — List all subjects with high-level stats
# ═══════════════════════════════════════════════════════════════════════════

@router.get("/subjects")
async def list_subjects_analytics(
    db: Session = Depends(get_db),
    student_uid: str = Depends(get_current_user),
):
    """
    Returns every subject the student is enrolled in, with:
    - average mastery %
    - learning velocity (recent activity proxy)
    - color hex for the UI
    """
    subjects = db.query(Subject).all()
    results = []
    for subj in subjects:
        stats = get_subject_stats(db, student_uid, subj.subject_id)
        results.append({
            "subject_id": subj.subject_id,
            "name": subj.name,
            "color_hex": subj.color_hex,
            "average_mastery": stats["average_mastery"],
            "learning_velocity": stats["learning_velocity"],
            "total_skills": stats["total_skills"],
            "mastered_skills": stats["mastered_skills"],
        })
    return results


# ═══════════════════════════════════════════════════════════════════════════
# GET  /analytics/subjects/{id}/mastery   — Hierarchical skill tree
# ═══════════════════════════════════════════════════════════════════════════

@router.get("/subjects/{subject_id}/mastery")
async def get_subject_mastery_tree(
    subject_id: int,
    db: Session = Depends(get_db),
    student_uid: str = Depends(get_current_user),
):
    """
    Returns the Unit > Lesson > Skill mastery tree for a single subject.
    Each skill node includes: mastery, status (LOCKED/ACTIVE/MASTERED), attempts.
    """
    subject = db.query(Subject).filter(Subject.subject_id == subject_id).first()
    if not subject:
        raise HTTPException(status_code=404, detail="Subject not found.")

    hierarchy = get_subject_mastery_hierarchy(db, student_uid, subject_id)
    enriched = enrich_hierarchy_with_status(hierarchy)

    return {
        "subject_id": subject.subject_id,
        "subject_name": subject.name,
        "units": enriched,
    }


# ═══════════════════════════════════════════════════════════════════════════
# GET  /analytics/subjects/{id}/history   — Paginated quiz history
# ═══════════════════════════════════════════════════════════════════════════

@router.get("/subjects/{subject_id}/history")
async def get_subject_quiz_history(
    subject_id: int,
    page: int = Query(1, ge=1),
    page_size: int = Query(10, ge=1, le=50),
    db: Session = Depends(get_db),
    student_uid: str = Depends(get_current_user),
):
    """
    Returns paginated quiz session history for a given subject.
    """
    subject = db.query(Subject).filter(Subject.subject_id == subject_id).first()
    if not subject:
        raise HTTPException(status_code=404, detail="Subject not found.")

    query = (
        db.query(QuizSession)
        .filter(
            QuizSession.student_uid == student_uid,
            QuizSession.subject_id == subject_id,
        )
        .order_by(QuizSession.start_time.desc())
    )

    total = query.count()
    sessions = query.offset((page - 1) * page_size).limit(page_size).all()

    items = []
    for s in sessions:
        items.append({
            "session_id": str(s.session_id),
            "start_time": s.start_time.isoformat() if s.start_time else None,
            "end_time": s.end_time.isoformat() if s.end_time else None,
            "total_questions": s.total_questions,
            "score": s.score,
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
async def get_overall_analytics(
    db: Session = Depends(get_db),
    student_uid: str = Depends(get_current_user),
):
    """
    Global dashboard:
    - Total skills tracked & mastered across all subjects
    - Activity heatmap (sessions grouped by date for the last 30 days)
    """

    # ── Aggregate mastery across all subjects ────────────────────────────
    all_states = (
        db.query(StudentSkillState)
        .filter(StudentSkillState.student_uid == student_uid)
        .all()
    )
    total_skills = db.query(Skill).count()
    mastered_skills = sum(1 for s in all_states if s.is_mastered)
    overall_mastery = (
        round(sum(s.mastery_probability for s in all_states) / total_skills, 4)
        if total_skills
        else 0.0
    )

    # ── Activity heatmap: sessions per day over the last 30 days ─────────
    thirty_days_ago = datetime.utcnow() - timedelta(days=30)
    heatmap_rows = (
        db.query(
            cast(QuizSession.start_time, Date).label("date"),
            func.count(QuizSession.session_id).label("count"),
        )
        .filter(
            QuizSession.student_uid == student_uid,
            QuizSession.start_time >= thirty_days_ago,
        )
        .group_by(cast(QuizSession.start_time, Date))
        .order_by(cast(QuizSession.start_time, Date))
        .all()
    )
    activity_heatmap = {
        row.date.isoformat(): row.count for row in heatmap_rows
    }

    return {
        "student_uid": student_uid,
        "total_skills": total_skills,
        "mastered_skills": mastered_skills,
        "overall_mastery": overall_mastery,
        "activity_heatmap": activity_heatmap,
    }
