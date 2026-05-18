"""
Data Retention — 30-Day Purge (G18 — Scheduled Daily Job)
----------------------------------------------------------
Implements the data retention policy:
  1. DELETE questions older than 30 days that were never submitted (submitted_at IS NULL).
  2. UPDATE questions older than 30 days to NULL-out heavy text/options columns,
     keeping lightweight metadata for historical analytics.

Previously this ran only once at startup. It now runs as a daily background job
via APScheduler at 03:00 UTC so data accumulation is bounded regardless of
server restart frequency.
"""

from datetime import datetime, timedelta
from sqlalchemy import update, delete, text
from sqlalchemy.orm import Session

from app.models.domain import Question


# ---------------------------------------------------------------------------
# Purge Logic
# ---------------------------------------------------------------------------

def purge_old_data(db: Session) -> dict:
    """
    Run the 30-day data retention purge.

    Returns a summary dict with counts of deleted and scrubbed rows.
    This function is safe to call from both startup and the scheduler.
    """
    try:
        cutoff = datetime.utcnow() - timedelta(days=30)

        # 1. Delete unanswered questions older than 30 days
        delete_stmt = (
            delete(Question)
            .where(Question.created_at < cutoff)
            .where(Question.submitted_at.is_(None))
        )
        delete_result = db.execute(delete_stmt)
        deleted_count = delete_result.rowcount

        # 2. Scrub heavy columns from old answered questions
        scrub_stmt = (
            update(Question)
            .where(Question.created_at < cutoff)
            .where(Question.submitted_at.isnot(None))
            .values(
                text_content=None,
                options=None,
                explanation=None,
                hints=None,
            )
        )
        scrub_result = db.execute(scrub_stmt)
        scrubbed_count = scrub_result.rowcount

        db.commit()

        summary = {
            "deleted_unanswered": deleted_count,
            "scrubbed_answered": scrubbed_count,
            "cutoff_date": cutoff.isoformat(),
        }
        print(f"[DataRetention] Purge complete: {summary}", flush=True)
        return summary

    except Exception as e:
        db.rollback()
        # Log but don't propagate — a purge failure must not crash the scheduler thread
        print(f"[DataRetention] ERROR: Purge failed: {type(e).__name__}: {e}", flush=True)
        return {"error": str(e)}


# ---------------------------------------------------------------------------
# Scheduler Lifecycle (called from main.py lifespan)
# ---------------------------------------------------------------------------

_scheduler = None


def start_scheduler(db: Session):
    """
    Starts the APScheduler background scheduler.
    Runs an immediate purge at startup, then schedules a daily job at 03:00 UTC.
    Called from the FastAPI lifespan context manager.
    """
    global _scheduler

    from apscheduler.schedulers.background import BackgroundScheduler
    from app.core.database import SessionLocal

    def _scheduled_purge():
        """Wrapper that creates its own DB session for the scheduled job."""
        job_db = SessionLocal()
        try:
            purge_old_data(job_db)
        finally:
            job_db.close()

    # Run once immediately at startup to handle any backlog
    purge_old_data(db)

    _scheduler = BackgroundScheduler()
    _scheduler.add_job(
        _scheduled_purge,
        trigger="cron",
        hour=3,
        minute=0,
        id="daily_data_purge",
        replace_existing=True,
    )
    _scheduler.start()
    print("[DataRetention] Daily purge scheduler started (runs at 03:00 UTC).", flush=True)


def shutdown_scheduler():
    """Gracefully shuts down the APScheduler. Called from the FastAPI lifespan shutdown."""
    global _scheduler
    if _scheduler and _scheduler.running:
        _scheduler.shutdown(wait=False)
        print("[DataRetention] Scheduler shut down.", flush=True)
