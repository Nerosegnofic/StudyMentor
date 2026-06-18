from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.core.auth import get_current_user
from app.core.database import get_db
from app.models.domain import Subject
from app.repositories.subject_repo import (
    get_subject_by_id,
    get_accessible_subject,
    get_added_global_subject_ids,
    set_subject_selection,
    delete_subject_cascade,
    delete_student_subject_data,
)

router = APIRouter(prefix="/subjects", tags=["Subjects"])


@router.get("/available")
async def list_available_global_subjects(
    student_uid: str = Query(...),
    firebase_uid: str = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Add-Subjects catalog: GLOBAL subjects the parent has NOT yet added for this student
    (no StudentSubjectProfile row). Adding one is just
    `PATCH /subjects/{id}/selection {is_selected: true}`.
    """
    added = get_added_global_subject_ids(db, student_uid)
    return [
        {
            "subject_id": s.subject_id,
            "name": s.name,
            "color_hex": s.color_hex,
        }
        for s in db.query(Subject).filter(Subject.is_global == True).all()
        if s.subject_id not in added
    ]


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


class _SubjectSelectionBody(BaseModel):
    student_uid: str
    is_selected: bool


@router.patch("/{subject_id}/selection")
async def set_subject_selection_endpoint(
    subject_id: int,
    body: _SubjectSelectionBody,
    firebase_uid: str = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Parent focus control: select / deselect a subject for a student WITHOUT deleting it.

    A deselected subject is hidden from the student's Knowledge Garden and excluded from
    both auto-selected and explicitly-targeted quizzes. Works for global and student-
    specific subjects alike (the flag is per-student, stored on StudentSubjectProfile).
    Re-selecting restores it. Uses the access check (not the quizzable check) so a
    currently-deselected subject is still reachable to turn back on.
    """
    subject = get_accessible_subject(db, subject_id, body.student_uid)
    if not subject:
        raise HTTPException(status_code=404, detail="Subject not found.")

    set_subject_selection(db, body.student_uid, subject_id, body.is_selected)
    return {"subject_id": subject_id, "is_selected": body.is_selected}


@router.delete("/{subject_id}/student-data")
async def remove_student_subject_data(
    subject_id: int,
    student_uid: str = Query(...),
    firebase_uid: str = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Remove a GLOBAL subject from a child: wipe this student's data/progress for it and drop
    the selection row (returning the global to the Add-Subjects catalog), WITHOUT deleting
    the shared global Subject. Private subjects are hard-deleted via the analytics delete
    endpoint, so this rejects non-global subjects.
    """
    subject = get_accessible_subject(db, subject_id, student_uid)
    if not subject:
        raise HTTPException(status_code=404, detail="Subject not found.")
    if not subject.is_global:
        raise HTTPException(
            status_code=400,
            detail="Use the subject delete endpoint for student-specific subjects.",
        )

    try:
        delete_student_subject_data(db, student_uid, subject_id)
        return {"status": "success", "subject_id": subject_id, "student_uid": student_uid}
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))