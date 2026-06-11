from sqlalchemy.orm import Session
from app.models.domain import Subject

def get_subject_by_id(db: Session, subject_id: int) -> Subject:
    return db.query(Subject).filter(Subject.subject_id == subject_id).first()

def find_or_create_subject(db: Session, subject_name: str, student_uid: str) -> Subject:
    """
    Finds a subject by name for the given student. If it doesn't exist, creates it.
    """
    subject = db.query(Subject).filter(
        Subject.name == subject_name,
        Subject.student_uid == student_uid
    ).first()

    if not subject:
        subject = Subject(name=subject_name, student_uid=student_uid, is_global=False)
        db.add(subject)
        db.commit()
        db.refresh(subject)
        
    return subject
