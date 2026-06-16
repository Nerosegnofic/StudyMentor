from sqlalchemy import create_engine
from langchain_postgres import PGVector
from app.core.embeddings import RateLimitedCohereEmbeddings
from app.core.config import settings

from sqlalchemy.orm import sessionmaker
from app.models.domain import Base

engine = create_engine(settings.POSTGRES_CONNECTION)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def get_vector_store() -> PGVector:
    """
    Initializes and returns the PGVector store connected to the Postgres vector database.
    """
    embeddings = RateLimitedCohereEmbeddings(
        cohere_api_key=settings.COHERE_API_KEY,
        model=settings.COHERE_EMBEDDING_MODEL
    )
    
    vector_store = PGVector(
        embeddings=embeddings,
        collection_name=settings.PGVECTOR_COLLECTION_NAME,
        connection=settings.POSTGRES_CONNECTION,
        use_jsonb=True,
    )
    
    return vector_store

def init_db():
    """
    Creates all ORM-defined tables in the database on startup.
    All schema is driven by the SQLAlchemy models in domain.py — no raw SQL needed.
    """
    Base.metadata.create_all(bind=engine)
    print("Database initialization complete.", flush=True)
