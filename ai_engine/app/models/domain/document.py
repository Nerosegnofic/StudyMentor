import uuid
from datetime import datetime
from sqlalchemy import Column, Integer, String, ForeignKey, DateTime, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID as PG_UUID
from sqlalchemy.orm import relationship
from .base import Base


class Document(Base):
    """
    Lightweight per-upload record.

    Created the instant a PDF is accepted — BEFORE the async ingestion runs — so that:
      1. a duplicate upload can be rejected up front via its file hash (Task 3), and
      2. a subject delete can enumerate every document to clean up its pgvector chunks
         and on-disk artifacts (Task 2).

    This row is NOT the curriculum content itself — chunks live in pgvector and skills
    in the relational tables. It only tracks the upload: the raw-file SHA-256 (dedup),
    the content-detected language/subject (Task 4), and a processing status.
    """
    __tablename__ = "documents"

    document_id = Column(PG_UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    firebase_uid = Column(String, nullable=True, index=True)        # owner; NULL for global curriculum
    subject_id = Column(Integer, ForeignKey("subjects.subject_id"), nullable=True, index=True)
    filename = Column(String, nullable=True)
    content_hash = Column(String(64), index=True)                   # SHA-256 hex of the raw file bytes
    detected_language = Column(String, nullable=True)               # "ar" | "en" (script-detected)
    detected_subject = Column(String, nullable=True)                # content-classified subject NAME (e.g. "Mathematics")
    status = Column(String, default="processing")                   # processing | ready | failed
    stage = Column(String, nullable=True)                           # coarse progress label: parsing | analyzing | building_skills (null once ready/failed)
    created_at = Column(DateTime, default=datetime.utcnow)

    subject = relationship("Subject", back_populates="documents")

    # Per-student dedup. Global docs have firebase_uid=NULL; Postgres treats NULLs as
    # distinct, so multiple owner-less docs aren't blocked here — global dedup is done
    # with an explicit query in the admin upload route.
    __table_args__ = (
        UniqueConstraint("firebase_uid", "content_hash", name="uq_doc_owner_hash"),
    )