from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.auth import get_current_user
from app.repositories import get_garden_for_student, get_subject_mastery_hierarchy
from app.models.domain import Subject
from app.services.evaluation.analytics_service import enrich_hierarchy_with_status

router = APIRouter(prefix="/garden", tags=["Knowledge Garden"])


def _mastery_to_stage(mastery_percent: float) -> int:
    if mastery_percent >= 80:
        return 5
    if mastery_percent >= 60:
        return 4
    if mastery_percent >= 40:
        return 3
    if mastery_percent >= 20:
        return 2
    return 1


@router.get("")
async def get_garden(
    db: Session = Depends(get_db),
    student_uid: str = Depends(get_current_user),
):
    """
    Returns all subjects accessible to the student with their mastery snapshot.
    Each entry maps directly to one plant in the Knowledge Garden.
    An empty list means no subjects have been assigned / uploaded yet.
    """
    plants = get_garden_for_student(db, student_uid)
    return [
        {
            "subject_id": p["subject_id"],
            "subject_name": p["subject_name"],
            "mastery_percent": p["mastery_percent"],
            "plant_stage": _mastery_to_stage(p["mastery_percent"]),
        }
        for p in plants
    ]


@router.get("/{subject_id}/skills")
async def get_subject_skills(
    subject_id: int,
    db: Session = Depends(get_db),
    student_uid: str = Depends(get_current_user),
):
    """
    Returns a flat list of skills for a subject, each with the student's
    current BKT mastery probability converted to a 0-100 percent value.
    Used by the subject detail screen.
    """
    subject = db.query(Subject).filter(Subject.subject_id == subject_id).first()
    if not subject:
        raise HTTPException(status_code=404, detail="Subject not found.")

    hierarchy = get_subject_mastery_hierarchy(db, student_uid, subject_id)
    enriched = enrich_hierarchy_with_status(hierarchy)

    skills = []
    for unit in enriched:
        for lesson in unit.get("lessons", []):
            for skill in lesson.get("skills", []):
                skills.append({
                    "skill_id": skill["skill_id"],
                    "name": skill["name"],
                    "mastery_percent": round(skill["mastery"] * 100, 1),
                    "is_mastered": skill.get("is_mastered", False),
                    "attempts": skill.get("attempts", 0),
                })
    return skills
