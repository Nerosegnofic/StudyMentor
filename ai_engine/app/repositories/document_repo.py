"""
Document tracking repository.

Encapsulates all DB access for the lightweight `documents` table — the per-upload
record used for duplicate rejection (Task 3), content-detection metadata (Task 4),
and subject-delete cleanup (Task 2).
"""
from collections import Counter
from typing import List, Optional, Tuple
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