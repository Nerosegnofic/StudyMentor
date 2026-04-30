from fastapi import APIRouter, UploadFile, File, BackgroundTasks, HTTPException
from uuid import uuid4, UUID
from app.models.schemas import DocumentUploadResponse
from app.services.rag.ingestion import process_and_ingest_document
from app.repositories.vector_repo import delete_vector_embeddings
from app.repositories.mastery_repo import delete_mastery_points

router = APIRouter(prefix="/documents", tags=["Documents"])

@router.post("/upload", response_model=DocumentUploadResponse)
async def upload_document(background_tasks: BackgroundTasks, file: UploadFile = File(...)):
    """
    Controller method to handle the asynchronous upload and ingestion of a PDF textbook.
    
    Returns a unique document ID immediately, while processing and embedding 
    the document contents into the PGVector database in a background task.
    """
    if not file.filename.lower().endswith('.pdf'):
        raise HTTPException(status_code=400, detail="Only PDF files are supported.")
        
    document_id = uuid4()
    file_content = await file.read()
    
    # Process in background task using multimodal LlamaParse and LangChain PGVector
    background_tasks.add_task(
        process_and_ingest_document,
        document_id=document_id,
        file_content=file_content,
        filename=file.filename
    )
    
    return DocumentUploadResponse(
        status="Processing started in background",
        document_id=document_id
    )

@router.delete("/{document_id}")
async def delete_document(document_id: UUID):
    """
    Deletes all vector embeddings and mastery points corresponding to a specific document.
    """
    try:
        delete_vector_embeddings(document_id)
        delete_mastery_points(document_id)
        return {"status": "success", "message": f"Document {document_id} data deleted."}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
