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

def save_mastery_points(mastery_data: list, document_id: UUID, source: str = "regex"):
    """
    Saves extracted mastery points to the database.
    
    Args:
        mastery_data: List of dicts, each with:
            {'unit': str, 'lesson': str, 'objectives': [str, ...], 'skill_ids': [str, ...] (optional)}
        document_id: UUID of the source document.
        source: Origin of the points — 'regex' or 'llm_refined'.
    """
    engine = create_engine(settings.POSTGRES_CONNECTION)
    
    with engine.begin() as conn:
        # 1. Ensure table exists
        conn.execute(text("""
            CREATE TABLE IF NOT EXISTS mastery_points (
                id UUID PRIMARY KEY,
                document_id UUID,
                unit TEXT,
                lesson TEXT,
                skill_id TEXT,
                point_text TEXT,
                source TEXT DEFAULT 'regex',
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """))
        
        # Ensure new columns exist on older tables
        for col, col_type, default in [
            ('skill_id', 'TEXT', None),
            ('source', 'TEXT', "'regex'"),
        ]:
            try:
                alter_sql = f"ALTER TABLE mastery_points ADD COLUMN IF NOT EXISTS {col} {col_type}"
                if default:
                    alter_sql += f" DEFAULT {default}"
                conn.execute(text(alter_sql))
            except Exception:
                pass  # Column already exists
        
        # 2. Clear old mastery points for this document and source
        conn.execute(
            text("DELETE FROM mastery_points WHERE document_id = :doc_id AND source = :source"),
            {"doc_id": document_id, "source": source}
        )
        
        # 3. Insert new points
        total = 0
        for entry in mastery_data:
            unit = entry.get('unit', 'Unknown')
            lesson = entry.get('lesson', 'Unknown')
            objectives = entry.get('objectives', [])
            skill_ids = entry.get('skill_ids', [])  # May be empty for regex source
            
            for idx, point in enumerate(objectives):
                sid = skill_ids[idx] if idx < len(skill_ids) else None
                conn.execute(
                    text("INSERT INTO mastery_points (id, document_id, unit, lesson, skill_id, point_text, source) "
                         "VALUES (:id, :doc_id, :unit, :lesson, :skill_id, :point, :source)"),
                    {
                        "id": uuid.uuid4(),
                        "doc_id": document_id,
                        "unit": unit,
                        "lesson": lesson,
                        "skill_id": sid,
                        "point": point,
                        "source": source,
                    }
                )
                total += 1
    print(f"[{document_id}] Successfully saved {total} mastery points (source={source}) to database!", flush=True)

def get_mastery_points(document_id: UUID, source: str = None) -> List[Dict]:
    """
    Retrieves mastery points for a given document.
    
    Args:
        document_id: UUID of the document.
        source: If provided, filter by source ('regex' or 'llm_refined').
                If None, returns all sources.
    """
    engine = create_engine(settings.POSTGRES_CONNECTION)
    with engine.connect() as conn:
        if source:
            result = conn.execute(
                text("SELECT unit, lesson, skill_id, point_text, source FROM mastery_points "
                     "WHERE document_id = :doc_id AND source = :source ORDER BY created_at ASC"),
                {"doc_id": document_id, "source": source}
            )
        else:
            result = conn.execute(
                text("SELECT unit, lesson, skill_id, point_text, source FROM mastery_points "
                     "WHERE document_id = :doc_id ORDER BY created_at ASC"),
                {"doc_id": document_id}
            )
        return [
            {"unit": row[0], "lesson": row[1], "skill_id": row[2], "point_text": row[3], "source": row[4]}
            for row in result
        ]

def delete_document_embeddings(document_id: UUID):
    """
    Deletes all vector embeddings associated with a specific document from the database.
    """
    engine = create_engine(settings.POSTGRES_CONNECTION)
    with engine.begin() as conn:
        # Delete embeddings
        conn.execute(
            text("DELETE FROM langchain_pg_embedding WHERE cmetadata->>'document_id' = :doc_id"),
            {"doc_id": str(document_id)}
        )
        # Delete mastery points
        conn.execute(
            text("DELETE FROM mastery_points WHERE document_id = :doc_id"),
            {"doc_id": document_id}
        )

def clear_all_embeddings():
    """
    Wipes the entire vector database.
    """
    engine = create_engine(settings.POSTGRES_CONNECTION)
    with engine.begin() as conn:
        # Ensure table exists before truncating to avoid UndefinedTable error
        conn.execute(text("""
            CREATE TABLE IF NOT EXISTS mastery_points (
                id UUID PRIMARY KEY,
                document_id UUID,
                unit TEXT,
                lesson TEXT,
                skill_id TEXT,
                point_text TEXT,
                source TEXT DEFAULT 'regex',
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """))
        conn.execute(text("TRUNCATE langchain_pg_embedding, langchain_pg_collection, mastery_points CASCADE;"))
    print("Database cleared completely!", flush=True)

# Expose new functions
__all__ = ["save_chunks_to_pgvector", "save_mastery_points", "delete_document_embeddings", "clear_all_embeddings"]
