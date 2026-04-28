import asyncio
from app.core.database import get_vector_store

vector_store = get_vector_store()
doc_id = "778a2921-457e-4cf2-8bb7-df369d2153bd"

docs = vector_store.similarity_search("Table of contents", k=5, filter={"document_id": doc_id})
print(f"Filter string doc_id: Found {len(docs)} docs")

docs2 = vector_store.similarity_search("Table of contents", k=5)
print(f"No filter: Found {len(docs2)} docs")

from sqlalchemy import create_engine, text
from app.core.config import settings

engine = create_engine(settings.POSTGRES_CONNECTION)
with engine.begin() as conn:
    res = conn.execute(text("SELECT count(*) FROM langchain_pg_embedding WHERE cmetadata->>'document_id' = :doc_id"), {"doc_id": doc_id})
    print(f"DB raw count for doc_id: {res.fetchone()[0]}")
    
    res_all = conn.execute(text("SELECT count(*) FROM langchain_pg_embedding"))
    print(f"DB raw total count: {res_all.fetchone()[0]}")
    
    res_sample = conn.execute(text("SELECT cmetadata FROM langchain_pg_embedding LIMIT 1"))
    row = res_sample.fetchone()
    if row:
        print(f"Sample metadata: {row[0]}")
