from fastapi import APIRouter, UploadFile, File, BackgroundTasks, HTTPException, Form
from uuid import uuid4, UUID
from app.models.schemas import DocumentUploadResponse
from app.services.rag.ingestion import process_and_ingest_document
from app.repositories.vector_repo import delete_vector_embeddings

router = APIRouter(prefix="/documents", tags=["Documents"])

@router.post("/upload", response_model=DocumentUploadResponse)
async def upload_document(
    background_tasks: BackgroundTasks,
    file: UploadFile = File(...),
    subject_id: int = Form(1)
):
    """
    Handles asynchronous upload and ingestion of a PDF textbook.

    - `subject_id`: The subject this document belongs to (default: 1).
    
    Returns a unique document ID immediately while the background task
    parses, chunks, embeds, and populates the Skill table.
    """
    if not file.filename.lower().endswith('.pdf'):
        raise HTTPException(status_code=400, detail="Only PDF files are supported.")

    document_id = uuid4()
    file_content = await file.read()

    background_tasks.add_task(
        process_and_ingest_document,
        document_id=document_id,
        file_content=file_content,
        filename=file.filename,
        subject_id=subject_id
    )

    return DocumentUploadResponse(
        status="Processing started in background",
        document_id=document_id
    )

@router.delete("/{document_id}")
async def delete_document(document_id: UUID):
    """
    Deletes all vector embeddings (CurriculumChunks) for a specific document.
    Skills whose source chunks belong to this document are left intact because
    they may have accumulated student BKT state.
    """
    try:
        delete_vector_embeddings(document_id)
        return {"status": "success", "message": f"Vector embeddings for document {document_id} deleted."}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
