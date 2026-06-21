import hashlib
from typing import Optional
from fastapi import APIRouter, UploadFile, File, BackgroundTasks, HTTPException, Form, Depends, Query
from uuid import uuid4, UUID
from sqlalchemy.orm import Session

from app.models.schemas import DocumentUploadResponse, SubjectStatus, SubjectsStatusResponse
from app.services.rag.ingestion import process_and_ingest_document, ingest_then_warm, delete_debug_artifacts
from app.repositories.vector_repo import delete_vector_embeddings, check_student_owns_document
from app.repositories.subject_repo import find_or_create_subject, get_or_create_global_subject
from app.repositories import document_repo
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
    - `student_uid`: The student this document is FOR. A parent uploads on a child's
      behalf, so the subject and chunks are owned by `student_uid` when provided.
      When omitted (a student uploading for themselves), ownership falls back to the
      authenticated uploader's own Firebase UID from the JWT.

    Returns a unique document ID immediately while the background task
    parses, chunks, embeds, and populates the Skill table.
    """
    file_content = await _read_validated_pdf(file)

    # Owner is the student the document is FOR. A parent uploads on a child's behalf, so
    # the document, its subject, and its chunks must all belong to student_uid when
    # provided; fall back to the uploader's own UID (a student uploading for themselves).
    # Resolved up front so dedup is scoped per-CHILD — re-uploading the same file for a
    # DIFFERENT child must be allowed, only a re-upload for the SAME child is a duplicate.
    owner_uid = student_uid or firebase_uid

    # Reject an exact re-upload of the same file for this student (file-level dedup).
    # Done up front so we never pay for a redundant parse/embedding pass.
    content_hash = hashlib.sha256(file_content).hexdigest()
    existing_doc = document_repo.find_duplicate(db, owner_uid, content_hash)
    if existing_doc:
        # If the document's subject was deleted (orphaned row from a failed cascade),
        # auto-clean the stale record and proceed with the fresh upload.
        from app.models.domain import Subject
        subject_exists = db.query(Subject).filter(
            Subject.subject_id == existing_doc.subject_id
        ).first() if existing_doc.subject_id else None
        if not subject_exists:
            print(
                f"[Upload] Cleaning orphaned document {existing_doc.document_id} "
                f"(subject_id={existing_doc.subject_id} no longer exists).",
                flush=True,
            )
            document_repo.delete_document_row(db, existing_doc.document_id)
        elif existing_doc.status == "failed":
            # A previous ingestion of these exact bytes failed — let the student retry by
            # clearing the failed row so the unique (owner, hash) constraint doesn't block
            # the re-upload.
            print(
                f"[Upload] Re-uploading previously failed document "
                f"{existing_doc.document_id}; clearing stale row.",
                flush=True,
            )
            document_repo.delete_document_row(db, existing_doc.document_id)
        else:
            raise HTTPException(
                status_code=409,
                detail="This document has already been uploaded.",
            )

    subject = find_or_create_subject(db, subject_name, owner_uid)
    resolved_subject_id = subject.subject_id

    # Reject a second (different) upload for a subject whose first document is still
    # ingesting. Two concurrent ingestions for the same subject would race on the skill
    # save (save_skills_from_mastery_data); serializing at the door is the simplest fix.
    # Scoped per-child via owner_uid so one child's in-flight ingest doesn't block a
    # different child's upload for the same-named subject.
    if document_repo.has_processing_document(db, owner_uid, resolved_subject_id):
        raise HTTPException(
            status_code=409,
            detail=(
                "A document for this subject is still being processed. "
                "Please wait until it finishes before uploading another."
            ),
        )

    document_id = uuid4()

    # Record the upload synchronously (before the background task) so the dedup gate
    # and the unique constraint also block a rapid second upload of the same bytes.
    document_repo.create_document(
        db,
        document_id=document_id,
        firebase_uid=owner_uid,
        subject_id=resolved_subject_id,
        filename=file.filename,
        content_hash=content_hash,
    )

    # Chunks must be tagged with the SAME owner the student retrieves with, otherwise
    # RAG retrieval for this private subject finds nothing (cross-student isolation
    # makes the owner's firebase_uid mandatory on every retrieval tier).
    #
    # ingest_then_warm runs the ingestion pipeline, then (on success only) pre-warms the
    # subject's first quiz so the student's first "Practice" is instant — the server is
    # the only place guaranteed to run at the "subject became ready" moment, since the
    # PARENT uploads on the child's behalf and may close the app.
    background_tasks.add_task(
        ingest_then_warm,
        document_id=document_id,
        file_content=file_content,
        filename=file.filename,
        subject_id=resolved_subject_id,
        firebase_uid=owner_uid,
        subject_name=subject_name,
    )

    return DocumentUploadResponse(
        status="Processing started in background",
        document_id=document_id,
        firebase_uid=owner_uid,
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

    # Reject an exact re-upload of the same global curriculum file (owner-less dedup).
    content_hash = hashlib.sha256(file_content).hexdigest()
    if document_repo.find_duplicate_global(db, content_hash):
        raise HTTPException(
            status_code=409,
            detail="This global document has already been published.",
        )

    subject = get_or_create_global_subject(db, subject_name)
    resolved_subject_id = subject.subject_id

    document_id = uuid4()

    document_repo.create_document(
        db,
        document_id=document_id,
        firebase_uid=None,  # global curriculum is owner-less / shared
        subject_id=resolved_subject_id,
        filename=file.filename,
        content_hash=content_hash,
    )

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


@router.get("/subjects/status", response_model=SubjectsStatusResponse)
async def get_subjects_status(
    student_uid: Optional[str] = Query(None),
    firebase_uid: str = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Per-subject ingestion readiness, polled by the app to:
      - show a "Preparing…" indicator (with a coarse `stage`) while a document ingests,
      - gate the Practice button until the subject is quizzable (`has_skills`).

    `student_uid` is optional: a PARENT passes the child's uid to see that child's
    subjects (the parent uploads on the child's behalf); a student omits it and the JWT
    uid is used. Same convention as `GET /analytics/subjects?student_uid=`. The query
    work lives in `document_repo.get_subjects_ingestion_status`; this handler maps it.
    """
    target_uid = student_uid if student_uid else firebase_uid
    rows = document_repo.get_subjects_ingestion_status(db, target_uid)
    return SubjectsStatusResponse(subjects=[SubjectStatus(**row) for row in rows])


@router.delete("/{document_id}")
async def delete_document(
    document_id: UUID,
    firebase_uid: str = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Deletes a single uploaded document: its vector embeddings, its tracking row, and
    its on-disk debug artifacts.

    **Requires:** `Authorization: Bearer <Firebase JWT>` header.

    Skills whose source chunks belong to this document are left intact because they
    are subject-scoped and shared across a subject's documents (and may have
    accumulated student BKT state). Full removal of skills/mastery happens when the
    SUBJECT is deleted — see `DELETE /subjects/{subject_id}`.
    """
    # Ownership: the document's tracking row is authoritative (works even if ingestion
    # produced no chunks); fall back to chunk ownership for legacy docs without a row.
    doc = document_repo.get_document(db, document_id)
    owns_document = (doc is not None and doc.firebase_uid == firebase_uid) or \
        check_student_owns_document(document_id, firebase_uid)

    if not owns_document:
        # Return 403 if the document exists but belongs to someone else,
        # and also if it doesn't exist (to avoid information disclosure).
        raise HTTPException(
            status_code=403,
            detail="You do not have permission to delete this document."
        )

    try:
        delete_vector_embeddings(document_id)
        document_repo.delete_document_row(db, document_id)
        delete_debug_artifacts(document_id)
        return {"status": "success", "message": f"Document {document_id} deleted."}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
