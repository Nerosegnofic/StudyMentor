from typing import Optional
from sqlalchemy.orm import Session
from app.models.domain import Subject, QuizSession, StudentSubjectProfile

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


def delete_subject_cascade(db: Session, subject_id: int) -> bool:
    """
    Hard-delete a subject and ALL of its stored data, in FK-safe order.

    `QuizSession.subject_id` and `StudentSubjectProfile.subject_id` are plain FKs with
    NO cascade, so those rows must be removed BEFORE the subject (otherwise the subject
    delete raises an FK violation). Deleting the subject then ORM-cascades:
        Skill → {StudentSkillState, Question → QuestionResponse}  and  Document rows.

    pgvector chunks and on-disk debug artifacts live outside the ORM and are removed
    explicitly. Returns False if the subject doesn't exist.
    """
    # Lazy imports avoid an import cycle: this repo is loaded by repositories/__init__,
    # and ingestion imports the repositories package.
    from app.repositories.document_repo import get_documents_for_subject
    from app.repositories.vector_repo import (
        delete_vector_embeddings,
        delete_vector_embeddings_by_subject,
    )
    from app.services.rag.ingestion import delete_debug_artifacts

    subject = db.query(Subject).filter(Subject.subject_id == subject_id).first()
    if not subject:
        return False

    # 1. Vector chunks + debug artifacts per document, plus a subject_id safety net for
    #    any legacy chunks without a documents row.
    for doc in get_documents_for_subject(db, subject_id):
        delete_vector_embeddings(doc.document_id)
        delete_debug_artifacts(doc.document_id)
    delete_vector_embeddings_by_subject(subject_id)

    # 2. Quiz sessions for this subject → cascades their Questions → QuestionResponses.
    # Must explicitly delete XpTransactions first as they reference the session but don't cascade.
    from app.models.domain.gamification import XpTransaction
    for session in db.query(QuizSession).filter(QuizSession.subject_id == subject_id).all():
        db.query(XpTransaction).filter(XpTransaction.quiz_session_id == session.session_id).delete(synchronize_session=False)
        db.delete(session)

    # 3. Student subject profiles (no cascade from subjects).
    db.query(StudentSubjectProfile).filter(
        StudentSubjectProfile.subject_id == subject_id
    ).delete(synchronize_session=False)

    # 4. The subject itself → ORM-cascades Skill (→ states, questions→responses) + Documents.
    db.delete(subject)
    db.commit()
    return True
