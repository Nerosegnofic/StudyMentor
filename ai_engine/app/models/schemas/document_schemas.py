from pydantic import BaseModel
from uuid import UUID
from typing import Optional

class DocumentUploadResponse(BaseModel):
    status: str
    document_id: UUID
    firebase_uid: Optional[str] = None  # None for global/admin-published curriculum
