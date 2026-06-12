from typing import List, Dict
from sqlalchemy.orm import Session
from app.models.domain import Skill

def get_skills_by_subject_id(db: Session, subject_id: int):
    return db.query(Skill).filter(Skill.subject_id == subject_id).all()

def get_skills_by_names(db: Session, skill_names: list):
    return db.query(Skill).filter(Skill.name.in_(skill_names)).all()

def save_skills_from_mastery_data(
    db: Session,
    mastery_data: List[Dict],
    subject_id: int,
) -> int:
    """
    Upserts Skill rows from the structured mastery data produced by the RAG pipeline.

    mastery_data format:
        [{'unit': str, 'lesson': str, 'objectives': [str, ...], 'skill_ids': [str, ...]}]

    Returns the number of skills created/updated.
    """
    total = 0
    unit_lesson_counter: Dict[str, int] = {}  # unit -> lesson count within that unit

    for entry in mastery_data:
        unit = entry.get("unit", "Unknown")
        lesson = entry.get("lesson", "Unknown")
        objectives = entry.get("objectives", [])

        unit_lesson_counter[unit] = unit_lesson_counter.get(unit, 0) + 1
        lesson_idx = unit_lesson_counter[unit]

        for point in objectives:
            skill = db.query(Skill).filter(
                Skill.name == point,
                Skill.subject_id == subject_id,
            ).first()

            if not skill:
                skill = Skill(
                    name=point,
                    subject_id=subject_id,
                    unit_name=unit,
                    lesson_name=lesson,
                    lesson_index=lesson_idx,
                )
                db.add(skill)
            else:
                skill.unit_name = unit
                skill.lesson_name = lesson
                skill.lesson_index = lesson_idx

            total += 1

    db.commit()
    print(f"[RAG] Upserted {total} skills for subject_id={subject_id}.", flush=True)
    return total

def delete_skills_by_subject(db: Session, subject_id: int) -> int:
    """Deletes all skills (and cascaded states/chunks) for a given subject."""
    count = db.query(Skill).filter(Skill.subject_id == subject_id).count()
    db.query(Skill).filter(Skill.subject_id == subject_id).delete()
    db.commit()
    return count
