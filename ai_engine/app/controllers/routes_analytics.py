from fastapi import APIRouter, HTTPException, Depends, Query
from pydantic import BaseModel
from typing import List
from sqlalchemy.orm import Session
from sqlalchemy import func
from app.core.database import get_db
from app.core.auth import get_current_user
from app.repositories.vector_repo import delete_vector_embeddings_by_subject
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
    GardenPlant,
)
from app.models.domain.student import StudentSubjectProfile

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
async def delete_subject(
    subject_name: str,
    student_uid: str = Query(...),
    db: Session = Depends(get_db),
    _: str = Depends(get_current_user),
):
    """
    Deletes a custom subject and all its associated skills for a specific student.
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

    # Delete rows that have no SQLAlchemy cascade from Subject
    db.query(GardenPlant).filter(
        GardenPlant.subject_id == subject_id,
        GardenPlant.student_uid == student_uid,
    ).delete()
    db.query(StudentSubjectProfile).filter(
        StudentSubjectProfile.subject_id == subject_id,
        StudentSubjectProfile.student_uid == student_uid,
    ).delete()

    # Delete the subject (cascades: skills → skill_states, curriculum_chunks, questions)
    db.delete(subject)
    db.commit()

    # Delete vector embeddings from LangChain's pgvector table (outside SQLAlchemy ORM)
    try:
        delete_vector_embeddings_by_subject(subject_id)
    except Exception as e:
        print(f"[DeleteSubject] Vector cleanup failed for subject_id={subject_id}: {e}", flush=True)

    return {"deleted": subject_name}
