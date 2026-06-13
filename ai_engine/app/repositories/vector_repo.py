import hashlib
import uuid
from uuid import UUID
from sqlalchemy import create_engine, text
from app.core.config import settings
from app.core.database import get_vector_store

def generate_chunk_id(content: str, metadata: dict, document_id: UUID) -> str:
    """
    Generates a deterministic UUID based on content and metadata.
    Ensures that identical text in different chapters has different IDs.
    """
    # Sort metadata to ensure consistent hashing
    metadata_str = str(sorted(metadata.items()))
    hash_input = f"{document_id}_{content}_{metadata_str}"
    hash_hex = hashlib.sha256(hash_input.encode('utf-8')).hexdigest()[:32]
    return str(uuid.UUID(hash_hex))

def save_chunks_to_pgvector(
    langchain_docs: list,
    document_id: UUID,
    firebase_uid: str = None,
    subject_id: int = None,
):
    """
    Stores the vectorized chunks into PGVector incrementally.
    Skips chunks that are already embedded in the database.

    Args:
        langchain_docs: LangChain Document objects from the chunker.
        document_id: UUID of the source document.
        firebase_uid: If provided, tags chunks for tenant-scoped retrieval.
        subject_id: If provided, tags chunks for subject-scoped retrieval.
                    Required for the RAG guardrail that prevents cross-subject
                    context injection into quiz prompts.
    """
    if not langchain_docs:
        print(f"Warning: No text could be extracted from document {document_id}", flush=True)
        return

    vector_store = get_vector_store()
    engine = create_engine(settings.POSTGRES_CONNECTION)

    # 1. Fetch all existing chunk IDs for this document to avoid re-embedding
    with engine.connect() as conn:
        result = conn.execute(
            text("SELECT id FROM langchain_pg_embedding WHERE cmetadata->>'document_id' = :doc_id"),
            {"doc_id": str(document_id)}
        )
        existing_ids = {row[0] for row in result}

    # 2. Map docs to their deterministic IDs and filter out duplicates
    new_chunks_registry = {}

    for doc in langchain_docs:
        doc.metadata["document_id"] = str(document_id)
        if firebase_uid:
            doc.metadata["firebase_uid"] = firebase_uid
        if subject_id is not None:
            doc.metadata["subject_id"] = subject_id
        chunk_id = generate_chunk_id(doc.page_content, doc.metadata, document_id)

        if chunk_id not in existing_ids and chunk_id not in new_chunks_registry:
            new_chunks_registry[chunk_id] = doc

    ids_to_add = list(new_chunks_registry.keys())
    docs_to_add = list(new_chunks_registry.values())
    
    total_new = len(docs_to_add)
    if total_new == 0:
        print(f"[{document_id}] All {len(langchain_docs)} chunks already exist in database. Skipping...", flush=True)
        return

    print(f"[{document_id}] Found {total_new} new chunks to embed (Skipped {len(langchain_docs) - total_new} existing).", flush=True)

    # 3. Save in batches
    batch_size = 190
    for i in range(0, total_new, batch_size):
        batch_docs = docs_to_add[i:i + batch_size]
        batch_ids = ids_to_add[i:i + batch_size]
        
        vector_store.add_documents(batch_docs, ids=batch_ids)
        print(f"[{document_id}] Progress: Saved {min(i + batch_size, total_new)}/{total_new} new chunks...", flush=True)

    print(f"[{document_id}] Successfully synchronized all chunks to PGVector!", flush=True)

def delete_vector_embeddings(document_id: UUID):
    """
    Deletes all vector embeddings associated with a specific document.
    """
    engine = create_engine(settings.POSTGRES_CONNECTION)
    with engine.begin() as conn:
        conn.execute(
            text("DELETE FROM langchain_pg_embedding WHERE cmetadata->>'document_id' = :doc_id"),
            {"doc_id": str(document_id)}
        )


def delete_vector_embeddings_by_subject(subject_id: int):
    """
    Deletes all vector embeddings tagged with a subject_id. Used by the subject hard-delete
    as a safety net to remove any chunks not covered by a `documents` row (e.g. legacy
    uploads that predate the documents table). Compared as text to match the JSON storage.
    """
    engine = create_engine(settings.POSTGRES_CONNECTION)
    with engine.begin() as conn:
        conn.execute(
            text("DELETE FROM langchain_pg_embedding WHERE cmetadata->>'subject_id' = :sid"),
            {"sid": str(subject_id)}
        )

def clear_vector_database():
    """
    Wipes the entire vector database.
    """
    engine = create_engine(settings.POSTGRES_CONNECTION)
    with engine.begin() as conn:
        conn.execute(text("TRUNCATE langchain_pg_embedding, langchain_pg_collection CASCADE;"))
    print("Vector database cleared!", flush=True)

def check_student_owns_document(document_id: UUID, firebase_uid: str) -> bool:
    """
    Checks if a given student owns at least one vector embedding for the specified document.
    """
    engine = create_engine(settings.POSTGRES_CONNECTION)
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
        return result.fetchone() is not None
