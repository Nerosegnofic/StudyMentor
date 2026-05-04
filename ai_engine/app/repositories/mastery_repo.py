from sqlalchemy.orm import Session
from sqlalchemy import text
from typing import List, Dict, Optional
import uuid
from uuid import UUID
from app.models.domain import StudentSkillState, StudentBKTProfile, Skill

# Legacy Mastery Points (RAG Extraction)
def save_mastery_points(db: Session, mastery_data: List[Dict], document_id: UUID, source: str = "regex"):
    db.execute(
        text("DELETE FROM mastery_points WHERE document_id = :doc_id AND source = :source"),
        {"doc_id": document_id, "source": source}
    )
    
    total = 0
    for entry in mastery_data:
        unit = entry.get('unit', 'Unknown')
        lesson = entry.get('lesson', 'Unknown')
        objectives = entry.get('objectives', [])
        skill_ids = entry.get('skill_ids', [])
        
        for idx, point in enumerate(objectives):
            sid = skill_ids[idx] if idx < len(skill_ids) else None
            db.execute(
                text("INSERT INTO mastery_points (id, document_id, unit, lesson, skill_id, point_text, source) "
                     "VALUES (:id, :doc_id, :unit, :lesson, :skill_id, :point, :source)"),
                {
                    "id": uuid.uuid4(),
                    "doc_id": document_id,
                    "unit": unit,
                    "lesson": lesson,
                    "skill_id": sid,
                    "point": point,
                    "source": source,
                }
            )
            total += 1
    db.commit()
    print(f"[{document_id}] Successfully saved {total} mastery points (source={source}) to database!", flush=True)

def get_mastery_points(db: Session, document_id: UUID, source: str = None) -> List[Dict]:
    params = {"doc_id": document_id}
    sql = "SELECT unit, lesson, skill_id, point_text, source FROM mastery_points WHERE document_id = :doc_id"
    if source:
        sql += " AND source = :source"
        params["source"] = source
    sql += " ORDER BY created_at ASC"
    
    result = db.execute(text(sql), params)
    return [
        {"unit": row[0], "lesson": row[1], "skill_id": row[2], "point_text": row[3], "source": row[4]}
        for row in result
    ]

def delete_mastery_points(db: Session, document_id: UUID):
    db.execute(text("DELETE FROM mastery_points WHERE document_id = :doc_id"), {"doc_id": document_id})
    db.commit()

def clear_mastery_points(db: Session):
    db.execute(text("TRUNCATE mastery_points CASCADE;"))
    db.commit()


# BKT and Student State Management
def get_student_bkt_profile(db: Session, student_uid: str) -> StudentBKTProfile:
    profile = db.query(StudentBKTProfile).filter(StudentBKTProfile.student_uid == student_uid).first()
    if not profile:
        profile = StudentBKTProfile(student_uid=student_uid)
        db.add(profile)
        db.commit()
        db.refresh(profile)
    return profile

def get_student_skill_state(db: Session, student_uid: str, skill_name: str) -> StudentSkillState:
    # Look up the Skill by name to get its default learn rate
    skill = db.query(Skill).filter(Skill.name == skill_name).first()
    
    # If the skill doesn't exist in the DB, we might want to auto-create it or handle it.
    # For now, we auto-create it to prevent crashes if RAG hasn't populated it.
    if not skill:
        # We need a dummy subject_id. Assuming 1 exists or we just create one.
        # This is a fallback; ideally skills are pre-populated.
        db.execute(text("INSERT INTO subjects (subject_id, name) VALUES (1, 'General') ON CONFLICT DO NOTHING"))
        skill = Skill(subject_id=1, name=skill_name)
        db.add(skill)
        db.commit()
        db.refresh(skill)

    state = db.query(StudentSkillState).filter(
        StudentSkillState.student_uid == student_uid,
        StudentSkillState.skill_id == skill.skill_id
    ).first()
    
    if not state:
        state = StudentSkillState(
            student_uid=student_uid, 
            skill_id=skill.skill_id,
            mastery_probability=0.01
        )
        db.add(state)
        db.commit()
        db.refresh(state)
        
    return state

def get_all_student_skill_states(db: Session, student_uid: str) -> Dict[str, float]:
    """Returns a dictionary mapping skill_name to mastery_probability."""
    states = db.query(StudentSkillState, Skill).join(Skill).filter(StudentSkillState.student_uid == student_uid).all()
    return {skill.name: state.mastery_probability for state, skill in states}
