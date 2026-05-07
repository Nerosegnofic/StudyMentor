from pydantic import BaseModel
from uuid import UUID

class DocumentUploadResponse(BaseModel):
    status: str
    document_id: UUID
