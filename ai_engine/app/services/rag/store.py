import uuid
from uuid import UUID
from sqlalchemy import create_engine, text
from app.core.config import settings
from app.core.database import get_vector_store

def save_chunks_to_pgvector(langchain_docs: list, document_id: UUID):
    """
    Stores the vectorized chunks into PGVector.
    """
    if langchain_docs:
        vector_store = get_vector_store()
        chunk_ids = [str(uuid.uuid4()) for _ in langchain_docs]
        
        # We don't need manual batching loops here anymore because
        # the RateLimitedCohereEmbeddings wrapper automatically handles
        # safe batching and sleeping to respect API limits!
        vector_store.add_documents(langchain_docs, ids=chunk_ids)
        
        print(f"[{document_id}] Successfully saved all vectorized chunks into PGVector!")
    else:
        print(f"Warning: No text could be extracted from document {document_id}")

def delete_document_embeddings(document_id: UUID):
    """
    Deletes all vector embeddings associated with a specific document from the database.
    """
    engine = create_engine(settings.POSTGRES_CONNECTION)
    with engine.begin() as conn:
        conn.execute(
            text("DELETE FROM langchain_pg_embedding WHERE cmetadata->>'document_id' = :doc_id"),
            {"doc_id": str(document_id)}
        )
