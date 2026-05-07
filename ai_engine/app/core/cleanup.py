"""
Data Retention – 30-Day Purge
-----------------------------
Implements the data retention policy:
  1. DELETE questions older than 30 days that were never submitted (submitted_at IS NULL).
  2. UPDATE questions older than 30 days to NULL-out heavy text/options columns,
     keeping lightweight metadata for historical analytics.
"""

from datetime import datetime, timedelta
from sqlalchemy import update, delete
from sqlalchemy.orm import Session

from app.models.domain import Question


def purge_old_data(db: Session) -> dict:
    """
    Run the 30-day data retention purge.

    Returns a summary dict with counts of deleted and scrubbed rows.
    """
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
    print(f"[Data Retention] Purge complete: {summary}", flush=True)
    return summary
