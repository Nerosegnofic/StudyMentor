from typing import Optional
from sqlalchemy.orm import Session
from app.models.domain import Subject

def get_subject_by_id(db: Session, subject_id: int) -> Subject:
    return db.query(Subject).filter(Subject.subject_id == subject_id).first()

def get_quizzable_subject(db: Session, subject_id: int, student_uid: str) -> Optional[Subject]:
    """
    Returns the subject only if the student is allowed to be quizzed on it:
    either it is admin-published shared curriculum (is_global) or it is owned by
    this student. Returns None otherwise — callers must treat that as 404, so a
    student can never target another student's private subject (which, combined
    with the retrieval owner-filter, prevents cross-student context leakage).
    """
    return (
        db.query(Subject)
        .filter(
            Subject.subject_id == subject_id,
            (Subject.is_global == True) | (Subject.student_uid == student_uid),
        )
        .first()
    )

def find_or_create_subject(db: Session, subject_name: str, student_uid: str) -> Subject:
    """
    Finds a private subject by name for the given student. If it doesn't exist, creates it.
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

def get_or_create_global_subject(db: Session, subject_name: str) -> Subject:
    """
    Finds (or creates) an admin-published GLOBAL subject by name. Global subjects
    are shared across all students (is_global=True, student_uid=None); their
    curriculum chunks are owner-less and retrieved by subject_id alone.
    """
    subject = db.query(Subject).filter(
        Subject.name == subject_name,
        Subject.is_global == True,
    ).first()

    if not subject:
        subject = Subject(name=subject_name, student_uid=None, is_global=True)
        db.add(subject)
        db.commit()
        db.refresh(subject)

    return subject
