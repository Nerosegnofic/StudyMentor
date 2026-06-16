from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.auth import get_current_user
from app.core.database import get_db
from app.repositories.subject_repo import get_subject_by_id, delete_subject_cascade

router = APIRouter(prefix="/subjects", tags=["Subjects"])


@router.delete("/{subject_id}")
async def delete_subject(
    subject_id: int,
    firebase_uid: str = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Parent/student UI action: permanently delete a subject and ALL of its stored data.

    **Requires:** `Authorization: Bearer <Firebase JWT>` header.

    Removes the subject row, every uploaded document under it (pgvector chunks + debug
    artifacts), all skills, BKT mastery state, quiz sessions/questions/responses, and
    subject-profile rows for the owning student. Irreversible.

    Only the OWNER of a private subject may delete it. A non-owner's private subject is
    reported as 404 (to avoid revealing its existence); shared global curriculum cannot
    be deleted via this endpoint (403).
    """
    subject = get_subject_by_id(db, subject_id)

    if not subject or (not subject.is_global and subject.student_uid != firebase_uid):
        raise HTTPException(status_code=404, detail="Subject not found.")
    if subject.is_global:
        raise HTTPException(
            status_code=403,
            detail="Shared global curriculum cannot be deleted here.",
        )

    try:
        delete_subject_cascade(db, subject_id)
        return {
            "status": "success",
            "message": f"Subject {subject_id} and all its data were deleted.",
        }
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))