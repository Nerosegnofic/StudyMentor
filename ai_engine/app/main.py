from fastapi import FastAPI
from app.core.config import settings
from app.controllers.routes_documents import router as documents_router
from app.controllers.routes_quizzes import router as quizzes_router
from app.controllers.routes_analytics import router as analytics_router
from app.controllers.routes_student import router as student_router
from app.core.database import get_vector_store, init_db, SessionLocal
from app.core.cleanup import purge_old_data
from app.core.auth import init_firebase

from contextlib import asynccontextmanager

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup logic
    print("DEBUG: Lifespan startup sequence beginning...")
    try:
        init_firebase()
        init_db()
        _ = get_vector_store()
        db = SessionLocal()
        try:
            purge_old_data(db)
        finally:
            db.close()
        print("DEBUG: Lifespan startup sequence complete.")
    except Exception as e:
        print(f"CRITICAL: Lifespan startup failed: {e}")
    yield
    # Shutdown logic (if any)

app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    description="Adaptive AI Math Assessment Microservice (RAG & Engine)",
    lifespan=lifespan
)
# Include Routers
app.include_router(documents_router, prefix="/api/v1")
app.include_router(quizzes_router, prefix="/api/v1")
app.include_router(analytics_router, prefix="/api/v1")
app.include_router(student_router, prefix="/api/v1")

@app.get("/health", tags=["Health"])
def health_check():
    """Simple health check endpoint"""
    return {"status": "healthy"}

if __name__ == "__main__":
    import uvicorn
    # Typically run via `uvicorn app.main:app --reload`
    uvicorn.run(app, host="0.0.0.0", port=8000)
