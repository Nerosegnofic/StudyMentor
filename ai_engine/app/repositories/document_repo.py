"""
Document tracking repository.

Encapsulates all DB access for the lightweight `documents` table — the per-upload
record used for duplicate rejection (Task 3), content-detection metadata (Task 4),
and subject-delete cleanup (Task 2).
"""
from collections import Counter
from typing import Dict, List, Optional, Tuple
from uuid import UUID

from sqlalchemy.orm import Session

from app.models.domain import Document


def find_duplicate(db: Session, firebase_uid: str, content_hash: str) -> Optional[Document]:
    """Return this student's existing document with the same file hash, if any (per-student dedup)."""
    if not firebase_uid or not content_hash:
        return None
    return (
        db.query(Document)
        .filter(Document.firebase_uid == firebase_uid, Document.content_hash == content_hash)
        .first()
    )


def find_duplicate_global(db: Session, content_hash: str) -> Optional[Document]:
    """Return an existing GLOBAL (owner-less) document with the same file hash, if any."""
    if not content_hash:
        return None
    return (
        db.query(Document)
        .filter(Document.firebase_uid.is_(None), Document.content_hash == content_hash)
        .first()
    )


def create_document(
    db: Session,
    document_id: UUID,
    firebase_uid: Optional[str],
    subject_id: Optional[int],
    filename: Optional[str],
    content_hash: str,
    status: str = "processing",
) -> Document:
    """Insert the upload record (called synchronously at upload time, before ingestion)."""
    doc = Document(
        document_id=document_id,
        firebase_uid=firebase_uid,
        subject_id=subject_id,
        filename=filename,
        content_hash=content_hash,
        status=status,
    )
    db.add(doc)
    db.commit()
    db.refresh(doc)
    return doc


def set_detected_metadata(
    db: Session,
    document_id: UUID,
    language: Optional[str] = None,
    subject: Optional[str] = None,
) -> None:
    """Persist content-detected language/subject for a document (only overwrites provided fields)."""
    doc = db.query(Document).filter(Document.document_id == document_id).first()
    if not doc:
        return
    if language is not None:
        doc.detected_language = language
    if subject is not None:
        doc.detected_subject = subject
    db.commit()


def set_status(db: Session, document_id: UUID, status: str) -> None:
    """Update the processing status (processing | ready | failed)."""
    doc = db.query(Document).filter(Document.document_id == document_id).first()
    if doc:
        doc.status = status
        db.commit()


def set_stage(db: Session, document_id: UUID, stage: Optional[str]) -> None:
    """
    Update the coarse progress stage (parsing | analyzing | building_skills, or None).

    Purely a "which ingestion step am I on" report consumed by the readiness endpoint —
    it carries no quiz/business logic, so it doesn't widen ingestion's responsibility.
    """
    doc = db.query(Document).filter(Document.document_id == document_id).first()
    if doc:
        doc.stage = stage
        db.commit()


def has_processing_document(db: Session, firebase_uid: Optional[str], subject_id: Optional[int]) -> bool:
    """
    True if this owner has a document for this subject that is still `processing`.

    Used by the upload route to reject a second (different) upload for a subject whose
    first document is still ingesting — avoiding the concurrent skill-save race.
    """
    if not firebase_uid or subject_id is None:
        return False
    return (
        db.query(Document.document_id)
        .filter(
            Document.firebase_uid == firebase_uid,
            Document.subject_id == subject_id,
            Document.status == "processing",
        )
        .first()
        is not None
    )


def get_subject_doc_status(db: Session, subject_id: int) -> Dict[str, int]:
    """
    Return counts of this subject's documents grouped by status,
    e.g. {"processing": 1, "ready": 2, "failed": 0}.
    """
    counts = {"processing": 0, "ready": 0, "failed": 0}
    for doc in db.query(Document.status).filter(Document.subject_id == subject_id).all():
        status = doc.status or "processing"
        counts[status] = counts.get(status, 0) + 1
    return counts


def get_latest_stage_for_subject(db: Session, subject_id: int) -> Optional[str]:
    """Stage of the most recent still-processing document for a subject, or None."""
    doc = (
        db.query(Document)
        .filter(Document.subject_id == subject_id, Document.status == "processing")
        .order_by(Document.created_at.desc())
        .first()
    )
    return doc.stage if doc else None


def get_subjects_ingestion_status(db: Session, student_uid: str) -> List[dict]:
    """
    Per-subject ingestion readiness for the student's ACTIVE subjects.

    Returns a list of dicts: {subject_id, subject_name, state, stage, has_skills}, where
    `state` is derived per subject (any processing ⇒ "processing"; else any ready ⇒
    "ready"; else only failed ⇒ "failed"). Subjects with no documents at all are omitted.

    Composes sibling repositories so the controller stays free of DB queries.
    """
    # Imported here (not at module top) to avoid an import cycle between repos.
    from app.repositories.subject_repo import get_active_subjects
    from app.repositories.skill_repo import subject_has_skills

    results: List[dict] = []
    for subj in get_active_subjects(db, student_uid):
        counts = get_subject_doc_status(db, subj.subject_id)
        if counts.get("processing", 0) > 0:
            state = "processing"
        elif counts.get("ready", 0) > 0:
            state = "ready"
        elif counts.get("failed", 0) > 0:
            state = "failed"
        else:
            continue  # no documents — nothing to report

        results.append(
            {
                "subject_id": subj.subject_id,
                "subject_name": subj.name,
                "state": state,
                "stage": get_latest_stage_for_subject(db, subj.subject_id) if state == "processing" else None,
                "has_skills": subject_has_skills(db, subj.subject_id),
            }
        )
    return results


def get_document(db: Session, document_id: UUID) -> Optional[Document]:
    return db.query(Document).filter(Document.document_id == document_id).first()


def get_documents_for_subject(db: Session, subject_id: int) -> List[Document]:
    return db.query(Document).filter(Document.subject_id == subject_id).all()


def get_detected_for_subject(db: Session, subject_id: int) -> Tuple[Optional[str], Optional[str]]:
    """
    Resolve a subject's content-detected language + subject NAME by MAJORITY VOTE over
    its `ready` documents — robust if a subject ever holds both an Arabic and an
    English version. Returns (language, subject); either may be None when unknown.
    """
    docs = (
        db.query(Document)
        .filter(Document.subject_id == subject_id, Document.status == "ready")
        .all()
    )
    language = _majority([d.detected_language for d in docs if d.detected_language])
    subject = _majority([d.detected_subject for d in docs if d.detected_subject])
    return language, subject


def delete_document_row(db: Session, document_id: UUID) -> None:
    db.query(Document).filter(Document.document_id == document_id).delete()
    db.commit()


def _majority(values: List[str]) -> Optional[str]:
    if not values:
        return None
    return Counter(values).most_common(1)[0][0]