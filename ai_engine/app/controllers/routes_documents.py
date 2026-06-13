from fastapi import APIRouter, UploadFile, File, BackgroundTasks, HTTPException, Form, Depends
from uuid import uuid4, UUID
from sqlalchemy.orm import Session

from app.models.schemas import DocumentUploadResponse
from app.services.rag.ingestion import process_and_ingest_document
from app.repositories.vector_repo import delete_vector_embeddings, check_student_owns_document
from app.repositories.subject_repo import find_or_create_subject, get_or_create_global_subject
from app.core.auth import get_current_user
from app.core.admin_auth import require_admin
from app.core.database import get_db
from app.core.config import settings

router = APIRouter(prefix="/documents", tags=["Documents"])

# Allowed MIME types for upload
_ALLOWED_MIME_TYPES = {"application/pdf", "application/octet-stream", "", None}


async def _read_validated_pdf(file: UploadFile) -> bytes:
    """
    Validate an uploaded file is a PDF within the size limit and return its bytes.
    Shared by the student and admin upload routes. Raises HTTPException on failure.
    """
    # MIME type guard — check actual content type, not just file extension.
    if file.content_type not in _ALLOWED_MIME_TYPES:
        raise HTTPException(
            status_code=415,
            detail=f"Unsupported file type '{file.content_type}'. Only PDF files are accepted."
        )
    # Extension guard as a secondary check.
    if not file.filename.lower().endswith(".pdf"):
        raise HTTPException(status_code=400, detail="Only PDF files are supported.")
    # Size guard — read content first, then validate size.
    file_content = await file.read()
    max_bytes = settings.MAX_UPLOAD_SIZE_MB * 1024 * 1024
    if len(file_content) > max_bytes:
        raise HTTPException(
            status_code=413,
            detail=f"File too large. Maximum allowed size is {settings.MAX_UPLOAD_SIZE_MB} MB."
        )
    return file_content


@router.post("/upload", response_model=DocumentUploadResponse)
async def upload_document(
    background_tasks: BackgroundTasks,
    file: UploadFile = File(...),
    subject_name: str = Form(...),
    student_uid: str = Form(None),
    firebase_uid: str = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Handles asynchronous upload and ingestion of a PDF textbook.

    **Requires:** `Authorization: Bearer <Firebase JWT>` header.

    - `subject_name`: The subject this document belongs to.
    - Ownership (subject and chunks) is derived from the authenticated Firebase
      UID in the JWT — never from request fields. The `student_uid` form field is
      accepted for backward compatibility but **ignored** for authorization, per
      the security rule "never trust a client-supplied UID."

    Returns a unique document ID immediately while the background task
    parses, chunks, embeds, and populates the Skill table.
    """
    file_content = await _read_validated_pdf(file)

    # Owner is the authenticated uploader (JWT), NOT the client-supplied student_uid.
    subject = find_or_create_subject(db, subject_name, firebase_uid)
    resolved_subject_id = subject.subject_id

    document_id = uuid4()

    background_tasks.add_task(
        process_and_ingest_document,
        document_id=document_id,
        file_content=file_content,
        filename=file.filename,
        subject_id=resolved_subject_id,
        firebase_uid=firebase_uid,
        subject_name=subject_name,
    )

    return DocumentUploadResponse(
        status="Processing started in background",
        document_id=document_id,
        firebase_uid=firebase_uid,
    )


@router.post("/upload-global", response_model=DocumentUploadResponse)
async def upload_global_document(
    background_tasks: BackgroundTasks,
    file: UploadFile = File(...),
    subject_name: str = Form(...),
    _: bool = Depends(require_admin),
    db: Session = Depends(get_db),
):
    """
    Publishes a PDF textbook as **global (shared) curriculum** available to every
    student. Admin-only.

    **Requires:** the `X-Admin-Key` header (matching `ADMIN_API_KEY`). In Swagger
    `/docs`, click **Authorize**, paste the key, then submit this multipart form.

    The document is ingested under a global subject (`is_global=True`,
    `student_uid=NULL`); its chunks are owner-less so any student can retrieve them
    via the subject-only path, while private subjects stay per-student isolated.
    """
    file_content = await _read_validated_pdf(file)

    subject = get_or_create_global_subject(db, subject_name)
    resolved_subject_id = subject.subject_id

    document_id = uuid4()

    background_tasks.add_task(
        process_and_ingest_document,
        document_id=document_id,
        file_content=file_content,
        filename=file.filename,
        subject_id=resolved_subject_id,
        firebase_uid=None,  # global curriculum is owner-less / shared
        subject_name=subject_name,
    )

    return DocumentUploadResponse(
        status="Processing started in background (global curriculum)",
        document_id=document_id,
        firebase_uid=None,
    )


@router.delete("/{document_id}")
async def delete_document(
    document_id: UUID,
    firebase_uid: str = Depends(get_current_user),
):
    """
    Deletes all vector embeddings for a specific document.

    **Requires:** `Authorization: Bearer <Firebase JWT>` header.

    Verifies that the requesting user owns at least one chunk from this document
    before deleting. Skills whose source chunks belong to this document are left
    intact because they may have accumulated student BKT state.
    """
    owns_document = check_student_owns_document(document_id, firebase_uid)

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
