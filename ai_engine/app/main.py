import traceback
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from slowapi import _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded

from app.core.rate_limit import limiter

from app.core.config import settings
from app.controllers.routes_documents import router as documents_router
from app.controllers.routes_quizzes import router as quizzes_router
from app.controllers.routes_analytics import router as analytics_router
from app.controllers.routes_student import router as student_router
from app.controllers.routes_gamification import router as gamification_router
from app.core.database import get_vector_store, init_db, SessionLocal
from app.core.cleanup import start_scheduler, shutdown_scheduler
from app.core.auth import init_firebase, get_current_user_optional

from contextlib import asynccontextmanager





@asynccontextmanager
async def lifespan(app: FastAPI):
    # --- Startup ---
    print("DEBUG: Lifespan startup sequence beginning...")
    try:
        init_firebase()   # Raises RuntimeError if Firebase fails (intentional)
        init_db()
        # Seed static gamification levels on first startup
        from app.repositories.gamification_repo import seed_levels
        _seed_db = SessionLocal()
        try:
            seed_levels(_seed_db)
        finally:
            _seed_db.close()
        _ = get_vector_store()
        db = SessionLocal()
        try:
            start_scheduler(db)
        finally:
            db.close()
        print("DEBUG: Lifespan startup sequence complete.")
    except RuntimeError:
        # Re-raise RuntimeErrors (e.g., Firebase init failure) so the server refuses to start
        raise
    except Exception as e:
        print(f"CRITICAL: Lifespan startup failed: {e}")

    yield

    # --- Shutdown ---
    shutdown_scheduler()


app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    description="Adaptive AI Math Assessment Microservice (RAG & Engine)",
    lifespan=lifespan,
)

# Attach rate limiter state
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# Include Routers
app.include_router(documents_router, prefix="/api/v1")
app.include_router(quizzes_router, prefix="/api/v1")
app.include_router(analytics_router, prefix="/api/v1")
app.include_router(student_router, prefix="/api/v1")
app.include_router(gamification_router, prefix="/api/v1")


# ---------------------------------------------------------------------------
# Global Exception Handler (G16)
# Catches any unhandled exception, logs it internally, and returns a generic
# 500 response — prevents raw Python tracebacks from leaking to clients.
# ---------------------------------------------------------------------------
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    # Log full traceback internally for debugging
    print(
        f"[GlobalExceptionHandler] Unhandled exception on {request.method} {request.url}:\n"
        f"{traceback.format_exc()}",
        flush=True,
    )
    return JSONResponse(
        status_code=500,
        content={"detail": "An internal server error occurred. Please try again later."},
    )


# ---------------------------------------------------------------------------
# Health Check (G17 — Deep)
# Tests actual DB and vector store connectivity instead of always returning 200.
# ---------------------------------------------------------------------------
@app.get("/health", tags=["Health"])
def health_check():
    """
    Deep health check — verifies database and vector store connectivity.
    Returns 200 if all dependencies are healthy, 503 if any are down.
    """
    from sqlalchemy import text
    from app.core.database import SessionLocal, get_vector_store

    status = {"status": "healthy", "db": "ok", "vector_store": "ok"}
    http_status = 200

    # Test DB
    try:
        db = SessionLocal()
        db.execute(text("SELECT 1"))
        db.close()
    except Exception as e:
        status["status"] = "degraded"
        status["db"] = f"error: {type(e).__name__}"
        http_status = 503

    # Test Vector Store
    try:
        get_vector_store()
    except Exception as e:
        status["status"] = "degraded"
        status["vector_store"] = f"error: {type(e).__name__}"
        http_status = 503

    from fastapi.responses import JSONResponse
    return JSONResponse(content=status, status_code=http_status)


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
