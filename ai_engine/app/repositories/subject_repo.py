from sqlalchemy.orm import Session
from app.models.domain import Subject

def get_subject_by_id(db: Session, subject_id: int) -> Subject:
    return db.query(Subject).filter(Subject.subject_id == subject_id).first()
