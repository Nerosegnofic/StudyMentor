import sys
import os
from sqlalchemy import text

# Add the parent directory (ai_engine) to the Python path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.core.database import engine, init_db
from app.models.domain import Base

def truncate_database():
    print("Connecting to database...")
    
    # Drop langchain-postgres tables explicitly using CASCADE to clean up constraints/relations
    print("Dropping PGVector/LangChain tables...")
    with engine.connect() as conn:
        conn.execute(text("DROP TABLE IF EXISTS langchain_pg_embedding CASCADE;"))
        conn.execute(text("DROP TABLE IF EXISTS langchain_pg_collection CASCADE;"))
        conn.commit()
        
    print("Dropping application domain tables...")
    Base.metadata.drop_all(bind=engine)
    
    print("Re-initializing tables...")
    init_db()
    
    print("Database truncated and re-initialized successfully!")

if __name__ == "__main__":
    truncate_database()
