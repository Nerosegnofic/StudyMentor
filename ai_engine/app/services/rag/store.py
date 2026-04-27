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

def save_chunks_to_pgvector(langchain_docs: list, document_id: UUID):
    """
    Stores the vectorized chunks into PGVector incrementally.
    Skips chunks that are already embedded in the database.
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
    # Using a dict ensures we don't have duplicate IDs in the SAME batch
    new_chunks_registry = {}
    
    for doc in langchain_docs:
        doc.metadata["document_id"] = str(document_id)
        # Include metadata in the ID generation so context is preserved!
        chunk_id = generate_chunk_id(doc.page_content, doc.metadata, document_id)
        
        # Only add if it's not in the database AND hasn't been seen in this loop
        if chunk_id not in existing_ids and chunk_id not in new_chunks_registry:
            new_chunks_registry[chunk_id] = doc

    ids_to_add = list(new_chunks_registry.keys())
    docs_to_add = list(new_chunks_registry.values())
    
    total_new = len(docs_to_add)
    if total_new == 0:
        print(f"[{document_id}] All {len(langchain_docs)} chunks already exist in database. Skipping...", flush=True)
        return

    print(f"[{document_id}] Found {total_new} new chunks to embed (Skipped {len(langchain_docs) - total_new} existing).", flush=True)

    # 3. Save in batches to ensure progress is saved even if it crashes
    batch_size = 190 # Match or slightly exceed the embedding batch size
    for i in range(0, total_new, batch_size):
        batch_docs = docs_to_add[i:i + batch_size]
        batch_ids = ids_to_add[i:i + batch_size]
        
        vector_store.add_documents(batch_docs, ids=batch_ids)
        print(f"[{document_id}] Progress: Saved {min(i + batch_size, total_new)}/{total_new} new chunks...", flush=True)

    print(f"[{document_id}] Successfully synchronized all chunks to PGVector!", flush=True)

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

def clear_all_embeddings():
    """
    Wipes the entire vector database.
    """
    engine = create_engine(settings.POSTGRES_CONNECTION)
    with engine.begin() as conn:
        conn.execute(text("TRUNCATE langchain_pg_embedding, langchain_pg_collection CASCADE;"))
    print("Database cleared completely!", flush=True)
