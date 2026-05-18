from fastapi import APIRouter, UploadFile, File, BackgroundTasks, HTTPException, Form, Depends
from uuid import uuid4, UUID
from app.models.schemas import DocumentUploadResponse
from app.services.rag.ingestion import process_and_ingest_document
from app.repositories.vector_repo import delete_vector_embeddings
from app.core.auth import get_current_user
from app.core.config import settings

router = APIRouter(prefix="/documents", tags=["Documents"])

# Allowed MIME types for upload
_ALLOWED_MIME_TYPES = {"application/pdf"}


@router.post("/upload", response_model=DocumentUploadResponse)
async def upload_document(
    background_tasks: BackgroundTasks,
    file: UploadFile = File(...),
    subject_name: str = Form(...),
    firebase_uid: str = Depends(get_current_user),
):
    """
    Handles asynchronous upload and ingestion of a PDF textbook.

    **Requires:** `Authorization: Bearer <Firebase JWT>` header.

    - `subject_name`: The subject this document belongs to.
    - The authenticated user's Firebase UID is extracted from the JWT and
      associated with the document for ownership tracking.

    Returns a unique document ID immediately while the background task
    parses, chunks, embeds, and populates the Skill table.
    """
    # G19a: MIME type guard — check actual content type, not just file extension.
    # A malicious file could be renamed to .pdf to bypass an extension-only check.
    if file.content_type not in _ALLOWED_MIME_TYPES:
        raise HTTPException(
            status_code=415,
            detail=f"Unsupported file type '{file.content_type}'. Only PDF files are accepted."
        )

    # G19b: Extension guard as a secondary check
    if not file.filename.lower().endswith(".pdf"):
        raise HTTPException(status_code=400, detail="Only PDF files are supported.")

    # G19c: File size guard — read content first, then validate size.
    file_content = await file.read()
    max_bytes = settings.MAX_UPLOAD_SIZE_MB * 1024 * 1024
    if len(file_content) > max_bytes:
        raise HTTPException(
            status_code=413,
            detail=f"File too large. Maximum allowed size is {settings.MAX_UPLOAD_SIZE_MB} MB."
        )

    # Find or Create Subject based on name and user
    from app.core.database import SessionLocal
    from app.models.domain.curriculum import Subject
    db = SessionLocal()
    try:
        subject = db.query(Subject).filter(
            Subject.name == subject_name,
            Subject.student_uid == firebase_uid
        ).first()

        if not subject:
            subject = Subject(name=subject_name, student_uid=firebase_uid, is_global=False)
            db.add(subject)
            db.commit()
            db.refresh(subject)

        resolved_subject_id = subject.subject_id
    finally:
        db.close()

    document_id = uuid4()

    background_tasks.add_task(
        process_and_ingest_document,
        document_id=document_id,
        file_content=file_content,
        filename=file.filename,
        subject_id=resolved_subject_id,
        firebase_uid=firebase_uid,
    )

    return DocumentUploadResponse(
        status="Processing started in background",
        document_id=document_id,
        firebase_uid=firebase_uid,
    )


@router.delete("/{document_id}")
async def delete_document(
    document_id: UUID,
    firebase_uid: str = Depends(get_current_user),  # G20: was completely unauthenticated
):
    """
    Deletes all vector embeddings (CurriculumChunks) for a specific document.

    **Requires:** `Authorization: Bearer <Firebase JWT>` header.

    Verifies that the requesting user owns at least one chunk from this document
    before deleting. Skills whose source chunks belong to this document are left
    intact because they may have accumulated student BKT state.
    """
    from app.core.database import get_db_engine
    from sqlalchemy import text, create_engine
    from app.core.config import settings as cfg

    # Ownership verification: confirm at least one chunk from this document
    # belongs to the requesting user before deleting anything.
    engine = create_engine(cfg.POSTGRES_CONNECTION)
    with engine.connect() as conn:
        result = conn.execute(
            text(
                "SELECT 1 FROM langchain_pg_embedding "
                "WHERE cmetadata->>'document_id' = :doc_id "
                "AND cmetadata->>'firebase_uid' = :uid "
                "LIMIT 1"
            ),
            {"doc_id": str(document_id), "uid": firebase_uid},
        )
        owns_document = result.fetchone() is not None

    if not owns_document:
        # Return 403 if the document exists but belongs to someone else,
        # and also if it doesn't exist (to avoid information disclosure).
        raise HTTPException(
            status_code=403,
            detail="You do not have permission to delete this document."
        )

    try:
        delete_vector_embeddings(document_id)
        return {"status": "success", "message": f"Vector embeddings for document {document_id} deleted."}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
