from fastapi import FastAPI
from app.core.config import settings
from app.controllers.routes_documents import router as documents_router
from app.controllers.routes_quizzes import router as quizzes_router
from app.controllers.routes_analytics import router as analytics_router
from app.core.database import get_vector_store, init_db

app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    description="Adaptive AI Math Assessment Microservice (RAG & Engine)"
)

@app.on_event("startup")
async def startup_event():
    """
    Lifecycle event that triggers when the Uvicorn server starts.
    Tests the connection to the PGVector extension to avoid late-stage crashes.
    """
    try:
        # 1. Initialize relational tables
        init_db()
        
        # 2. Test PGVector connectivity
        # Langchain-postgres handles setup on instantiation or first interaction
        _ = get_vector_store()
        print("PGVector connectivity initialized on startup.")
    except Exception as e:
        # Print failure but don't strictly crash app if DB isn't ready immediately
        print(f"Warning: Issue connecting to PGVector Database at startup: {e}")

# Include Routers
app.include_router(documents_router, prefix="/api/v1")
app.include_router(quizzes_router, prefix="/api/v1")
app.include_router(analytics_router, prefix="/api/v1")

@app.get("/health", tags=["Health"])
def health_check():
    """Simple health check endpoint"""
    return {"status": "healthy"}

if __name__ == "__main__":
    import uvicorn
    # Typically run via `uvicorn app.main:app --reload`
    uvicorn.run(app, host="0.0.0.0", port=8000)
