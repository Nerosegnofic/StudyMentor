from pydantic import BaseModel
from uuid import UUID
from typing import List, Literal, Optional

class DocumentUploadResponse(BaseModel):
    status: str
    document_id: UUID
    firebase_uid: Optional[str] = None  # None for global/admin-published curriculum


class SubjectStatus(BaseModel):
    """Per-subject ingestion readiness, polled by the app to gate uploads & quizzes."""
    subject_id: int
    subject_name: str
    state: Literal["processing", "ready", "failed"]
    # Coarse progress label for the most recent in-flight document (null once ready/failed).
    stage: Optional[str] = None
    # True once skills exist — the authoritative "quizzable" signal.
    has_skills: bool


class SubjectsStatusResponse(BaseModel):
    subjects: List[SubjectStatus]
