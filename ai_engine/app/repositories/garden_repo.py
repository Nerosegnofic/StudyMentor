from datetime import datetime
from sqlalchemy import or_
from sqlalchemy.orm import Session

from app.models.domain import GardenPlant, Subject
from app.repositories.analytics_repo import get_subject_stats, upsert_mastery_snapshot
from app.repositories.subject_repo import get_active_subject_ids


def upsert_garden_plant(db: Session, student_uid: str, subject_id: int) -> None:
    """Recompute mastery for one subject, cache it in garden_plants, and record a
    daily mastery snapshot for the mastery-over-time history."""
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

    # Daily history snapshot (one row per student/subject/day, upserted).
    upsert_mastery_snapshot(db, student_uid, subject_id, mastery_percent)
    db.flush()


def get_garden_for_student(db: Session, student_uid: str) -> list:
    """
    Returns the subjects ACTIVE for the student (selected globals + their own non-deselected
    uploads), paired with cached mastery from garden_plants.
    Subjects with no quiz history return mastery_percent = 0.0.
    """
    active_ids = get_active_subject_ids(db, student_uid)
    subjects = [
        s
        for s in db.query(Subject)
        .filter(or_(Subject.is_global == True, Subject.student_uid == student_uid))
        .all()
        if s.subject_id in active_ids
    ]

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
