from sqlalchemy import create_engine, text
from langchain_postgres import PGVector
from app.core.embeddings import RateLimitedCohereEmbeddings
from app.core.config import settings

def get_vector_store() -> PGVector:
    """
    Initializes and returns the PGVector store connected to the Postgres vector database.
    """
    embeddings = RateLimitedCohereEmbeddings(
        cohere_api_key=settings.COHERE_API_KEY,
        model="embed-multilingual-v3.0"
    )
    
    vector_store = PGVector(
        embeddings=embeddings,
        collection_name="math_curriculum",
        connection=settings.POSTGRES_CONNECTION,
        use_jsonb=True,
    )
    
    return vector_store

def init_db():
    """
    Ensures that all necessary relational tables exist in the database.
    """
    engine = create_engine(settings.POSTGRES_CONNECTION)
    
    with engine.begin() as conn:
        # Create mastery_points table
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
        
        # Ensure latest columns exist (schema evolution)
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
    
    print("Database initialization complete (Relational tables checked).", flush=True)
