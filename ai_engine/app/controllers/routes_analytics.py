from fastapi import APIRouter, HTTPException, Depends, Query
from pydantic import BaseModel
from typing import List
from sqlalchemy.orm import Session
from sqlalchemy import func, cast, Date, text
from app.core.database import get_db
from app.core.auth import get_current_user
from app.repositories import (
    get_subject_mastery_hierarchy,
    get_subject_stats,
)
from app.services.evaluation.analytics_service import (
    enrich_hierarchy_with_status,
    get_overall_dashboard_stats,
)
from app.models.domain import (
    Subject,
    QuizSession,
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
    return get_overall_dashboard_stats(db, student_uid)


# ═══════════════════════════════════════════════════════════════════════════
# POST /analytics/subjects/ensure  — Create Subject rows for assigned subjects
# ═══════════════════════════════════════════════════════════════════════════

class _EnsureSubjectsBody(BaseModel):
    student_uid: str
    subject_names: List[str]


@router.post("/subjects/ensure")
async def ensure_subjects(
    body: _EnsureSubjectsBody,
    db: Session = Depends(get_db),
    _: str = Depends(get_current_user),
):
    """
    Ensures a Subject row exists in the AI engine for each assigned subject name.
    Called when a parent assigns global subjects to a student so they appear in
    the Knowledge Garden. Skips names that already have a matching row (case-insensitive).
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
# DELETE /analytics/subjects/{subject_name}   — Wipe custom subject securely
# ═══════════════════════════════════════════════════════════════════════════

@router.delete("/subjects/{subject_name}")
async def delete_subject(
    subject_name: str,
    student_uid: str = Query(..., description="UID of the student who owns the subject"),
    db: Session = Depends(get_db),
    _: str = Depends(get_current_user),
):
    """
    Deletes a custom subject and all related data for a specific student.
    Global subjects (is_global=True) cannot be deleted.
    QuizSession history is preserved with subject_id set to NULL.
    """
    subject = db.query(Subject).filter(
        func.lower(Subject.name) == subject_name.lower(),
        Subject.student_uid == student_uid,
    ).first()

    if not subject:
        raise HTTPException(status_code=404, detail="Subject not found or access denied.")

    subject_id = subject.subject_id

    try:
        db.execute(
            text("DELETE FROM langchain_pg_embedding WHERE cmetadata->>'subject_id' = :sid"),
            {"sid": str(subject_id)},
        )
        db.execute(
            text("UPDATE quiz_sessions SET subject_id = NULL WHERE subject_id = :sid"),
            {"sid": subject_id},
        )
        db.execute(
            text("DELETE FROM garden_plants WHERE subject_id = :sid"),
            {"sid": subject_id},
        )
        db.execute(
            text("DELETE FROM student_subject_profiles WHERE subject_id = :sid"),
            {"sid": subject_id},
        )
        db.delete(subject)
        db.commit()
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to delete subject: {str(e)}")

    return {"status": "success", "message": f"Subject '{subject_name}' deleted successfully."}
