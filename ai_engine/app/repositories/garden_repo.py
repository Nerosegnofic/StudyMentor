from datetime import datetime
from sqlalchemy import or_
from sqlalchemy.orm import Session

from app.models.domain import GardenPlant, Subject, Skill
from app.repositories.analytics_repo import get_subject_stats


def upsert_garden_plant(db: Session, student_uid: str, subject_id: int) -> None:
    """Recompute mastery for one subject and cache it in garden_plants."""
    stats = get_subject_stats(db, student_uid, subject_id)
    mastery_percent = round(stats["average_mastery"] * 100, 2)

    plant = (
        db.query(GardenPlant)
        .filter_by(student_uid=student_uid, subject_id=subject_id)
        .first()
    )
    if plant:
        plant.mastery_percent = mastery_percent
        plant.updated_at = datetime.utcnow()
    else:
        plant = GardenPlant(
            student_uid=student_uid,
            subject_id=subject_id,
            mastery_percent=mastery_percent,
        )
        db.add(plant)
    db.flush()


def get_garden_for_student(db: Session, student_uid: str) -> list:
    """
    Returns all subjects accessible to the student (global + their own uploads)
    that have at least one skill, paired with cached mastery from garden_plants.
    Subjects with no quiz history return mastery_percent = 0.0.
    """
    subjects = (
        db.query(Subject)
        .filter(
            or_(Subject.is_global == True, Subject.student_uid == student_uid)
        )
        .join(Skill, Subject.subject_id == Skill.subject_id)
        .distinct()
        .all()
    )

    plant_map: dict[int, float] = {
        p.subject_id: p.mastery_percent
        for p in db.query(GardenPlant)
        .filter_by(student_uid=student_uid)
        .all()
    }

    return [
        {
            "subject_id": s.subject_id,
            "subject_name": s.name,
            "mastery_percent": plant_map.get(s.subject_id, 0.0),
        }
        for s in subjects
    ]
