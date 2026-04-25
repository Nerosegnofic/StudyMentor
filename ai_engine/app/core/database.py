from langchain_postgres import PGVector
from app.core.embeddings import RateLimitedCohereEmbeddings
from app.core.config import settings

def get_vector_store() -> PGVector:
    """
    Initializes and returns the PGVector store connected to the Postgres vector database.
    We use CohereEmbeddings as they provide an excellent free tier for Arabic multilingual embeddings.
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
