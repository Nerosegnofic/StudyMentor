from typing import Optional
from sqlalchemy.orm import Session
from app.models.domain import Subject, QuizSession, StudentSubjectProfile, Question, QuestionResponse

def get_subject_by_id(db: Session, subject_id: int) -> Subject:
    return db.query(Subject).filter(Subject.subject_id == subject_id).first()

def get_accessible_subject(db: Session, subject_id: int, student_uid: str) -> Optional[Subject]:
    """
    Returns the subject if the student may access it at all: either it is admin-published
    shared curriculum (is_global) or it is owned by this student. This is the pure access
    check (no focus filter) — used when toggling selection, where a currently-deselected
    subject must still be reachable so it can be re-selected.
    """
    return (
        db.query(Subject)
        .filter(
            Subject.subject_id == subject_id,
            (Subject.is_global == True) | (Subject.student_uid == student_uid),
        )
        .first()
    )

def get_quizzable_subject(db: Session, subject_id: int, student_uid: str) -> Optional[Subject]:
    """
    Returns the subject only if the student is allowed to be quizzed on it: accessible
    (global or owned) AND currently ACTIVE for the student. Returns None otherwise —
    callers treat that as 404, so a student can never target another student's private
    subject (preventing cross-student context leakage), an un-added/deselected global, or
    a deselected private subject, even when the id is supplied explicitly.
    """
    subject = get_accessible_subject(db, subject_id, student_uid)
    if subject and subject.subject_id in get_active_subject_ids(db, student_uid):
        return subject
    return None

def get_deselected_subject_ids(db: Session, student_uid: str) -> set:
    """
    Subject ids the parent has explicitly DESELECTED for this student (a profile row
    exists with is_selected=False). For PRIVATE subjects this is the opt-out "hidden"
    filter (absence of a row = selected). For globals, deselection is handled by the
    opt-in rules in get_active_subject_ids, not by this set.
    """
    rows = (
        db.query(StudentSubjectProfile.subject_id)
        .filter(
            StudentSubjectProfile.student_uid == student_uid,
            StudentSubjectProfile.is_selected == False,
        )
        .all()
    )
    return {r.subject_id for r in rows}

def get_selected_global_subject_ids(db: Session, student_uid: str) -> set:
    """
    Global subject ids ACTIVE for this student: a profile row exists with is_selected=True.
    These are the opt-in globals visible to the child and quizzable. Toggled-off globals
    (row with is_selected=False) and un-added globals (no row) are excluded.
    """
    rows = (
        db.query(StudentSubjectProfile.subject_id)
        .join(Subject, Subject.subject_id == StudentSubjectProfile.subject_id)
        .filter(
            StudentSubjectProfile.student_uid == student_uid,
            StudentSubjectProfile.is_selected == True,
            Subject.is_global == True,
        )
        .all()
    )
    return {r.subject_id for r in rows}

def get_added_global_subject_ids(db: Session, student_uid: str) -> set:
    """
    Global subject ids the parent has ADDED for this student — ANY profile row exists
    (selected or toggled-off). Added globals show in the parent's subject list; globals
    with no row remain in the Add-Subjects catalog.
    """
    rows = (
        db.query(StudentSubjectProfile.subject_id)
        .join(Subject, Subject.subject_id == StudentSubjectProfile.subject_id)
        .filter(
            StudentSubjectProfile.student_uid == student_uid,
            Subject.is_global == True,
        )
        .all()
    )
    return {r.subject_id for r in rows}

def get_active_subject_ids(db: Session, student_uid: str) -> set:
    """
    Subject ids ACTIVE for the student — the set shown in the garden and allowed for
    quizzes. Globals are OPT-IN (only selected ones); private subjects are OPT-OUT (all
    owned minus those explicitly deselected).
    """
    selected_globals = get_selected_global_subject_ids(db, student_uid)
    owned_ids = {
        r.subject_id
        for r in db.query(Subject.subject_id)
        .filter(Subject.student_uid == student_uid)
        .all()
    }
    active_privates = owned_ids - get_deselected_subject_ids(db, student_uid)
    return selected_globals | active_privates


def get_active_subjects(db: Session, student_uid: str) -> list:
    """
    The student's ACTIVE subjects as full Subject rows (globals they selected + their own
    private subjects minus deselected). Same membership rule as get_active_subject_ids;
    used wherever the rows themselves are needed (e.g. the ingestion-status endpoint).
    """
    active_ids = get_active_subject_ids(db, student_uid)
    if not active_ids:
        return []
    return (
        db.query(Subject)
        .filter(Subject.subject_id.in_(active_ids))
        .all()
    )

def set_subject_selection(
    db: Session, student_uid: str, subject_id: int, is_selected: bool
) -> StudentSubjectProfile:
    """
    Upsert the per-student focus flag for a subject (parent select / deselect). Reuses the
    existing StudentSubjectProfile row if present, otherwise creates one — mirroring
    upsert_student_subject_profile_last_quizzed.
    """
    profile = (
        db.query(StudentSubjectProfile)
        .filter(
            StudentSubjectProfile.student_uid == student_uid,
            StudentSubjectProfile.subject_id == subject_id,
        )
        .first()
    )
    if profile:
        profile.is_selected = is_selected
    else:
        profile = StudentSubjectProfile(
            student_uid=student_uid,
            subject_id=subject_id,
            is_selected=is_selected,
        )
        db.add(profile)
    db.commit()
    return profile

def find_or_create_subject(db: Session, subject_name: str, student_uid: str) -> Subject:
    """
    Finds a private subject by name for the given student. If it doesn't exist, creates it.
    """
    subject = db.query(Subject).filter(
        Subject.name == subject_name,
        Subject.student_uid == student_uid
    ).first()

    if not subject:
        subject = Subject(name=subject_name, student_uid=student_uid, is_global=False)
        db.add(subject)
        db.commit()
        db.refresh(subject)

    return subject

def get_or_create_global_subject(db: Session, subject_name: str) -> Subject:
    """
    Finds (or creates) an admin-published GLOBAL subject by name. Global subjects
    are shared across all students (is_global=True, student_uid=None); their
    curriculum chunks are owner-less and retrieved by subject_id alone.
    """
    subject = db.query(Subject).filter(
        Subject.name == subject_name,
        Subject.is_global == True,
    ).first()

    if not subject:
        subject = Subject(name=subject_name, student_uid=None, is_global=True)
        db.add(subject)
        db.commit()
        db.refresh(subject)

    return subject


def delete_subject_cascade(db: Session, subject_id: int) -> bool:
    """
    Hard-delete a subject and ALL of its stored data, in FK-safe order.

    Tables with plain FKs (no ORM cascade) must be cleared before the subject row:
        XpTransaction → QuizSession → StudentSubjectProfile
        GardenPlant, MasterySnapshot

    Deleting the subject then ORM-cascades:
        Skill → {StudentSkillState, Question → QuestionResponse} + Document rows.

    pgvector chunks and on-disk debug artifacts live outside the ORM and are removed
    explicitly. Returns False if the subject doesn't exist.
    """
    # Lazy imports avoid an import cycle: this repo is loaded by repositories/__init__,
    # and ingestion imports the repositories package.
    from app.repositories.document_repo import get_documents_for_subject
    from app.repositories.vector_repo import (
        delete_vector_embeddings,
        delete_vector_embeddings_by_subject,
    )
    from app.services.rag.ingestion import delete_debug_artifacts
    from app.models.domain.gamification import XpTransaction
    from app.models.domain.garden import GardenPlant
    from app.models.domain.mastery_snapshot import MasterySnapshot

    subject = db.query(Subject).filter(Subject.subject_id == subject_id).first()
    if not subject:
        return False

    # 1. Vector chunks + debug artifacts per document, plus a subject_id safety net for
    #    any legacy chunks without a documents row.
    for doc in get_documents_for_subject(db, subject_id):
        delete_vector_embeddings(doc.document_id)
        delete_debug_artifacts(doc.document_id)
    delete_vector_embeddings_by_subject(subject_id)

    # 2. Delete quiz sessions and their children in FK-safe order.
    #    Bulk DELETE bypasses ORM cascade, so we must walk the tree manually:
    #    XpTransaction → QuestionResponse → Question → QuizSession
    session_ids = [
        row.session_id
        for row in db.query(QuizSession.session_id)
        .filter(QuizSession.subject_id == subject_id)
        .all()
    ]
    if session_ids:
        question_ids = [
            row.question_id
            for row in db.query(Question.question_id)
            .filter(Question.session_id.in_(session_ids))
            .all()
        ]
        if question_ids:
            db.query(QuestionResponse).filter(
                QuestionResponse.question_id.in_(question_ids)
            ).delete(synchronize_session=False)
            db.query(Question).filter(
                Question.question_id.in_(question_ids)
            ).delete(synchronize_session=False)
        db.query(XpTransaction).filter(
            XpTransaction.quiz_session_id.in_(session_ids)
        ).delete(synchronize_session=False)
        db.flush()
        db.query(QuizSession).filter(
            QuizSession.subject_id == subject_id
        ).delete(synchronize_session=False)
        db.flush()

    # 3. Garden plants and mastery snapshots reference subject_id with no ORM cascade.
    db.query(GardenPlant).filter(
        GardenPlant.subject_id == subject_id
    ).delete(synchronize_session=False)
    db.query(MasterySnapshot).filter(
        MasterySnapshot.subject_id == subject_id
    ).delete(synchronize_session=False)

    # 4. Student subject profiles (no cascade from subjects).
    db.query(StudentSubjectProfile).filter(
        StudentSubjectProfile.subject_id == subject_id
    ).delete(synchronize_session=False)

    # 5. The subject itself → ORM-cascades Skill (→ states, questions→responses) + Documents.
    db.delete(subject)
    db.commit()
    return True


def delete_student_subject_data(db: Session, student_uid: str, subject_id: int) -> bool:
    """
    Wipe ONE student's data/progress for a subject WITHOUT deleting the subject itself.

    Used when a parent "removes" a GLOBAL subject from a child: the shared Subject/Skills/
    Documents/vector chunks are preserved (other students keep them), but this student's
    quiz history, mastery, garden plant, snapshots and selection row are cleared. Dropping
    the StudentSubjectProfile row also returns the global to the Add-Subjects catalog.

    Returns False if the subject doesn't exist.
    """
    from app.models.domain import Skill, StudentSkillState
    from app.models.domain.gamification import XpTransaction
    from app.models.domain.garden import GardenPlant
    from app.models.domain.mastery_snapshot import MasterySnapshot

    subject = db.query(Subject).filter(Subject.subject_id == subject_id).first()
    if not subject:
        return False

    # 1. This student's quiz sessions for the subject, children first (XpTransaction →
    #    QuestionResponse → Question → QuizSession).
    session_ids = [
        row.session_id
        for row in db.query(QuizSession.session_id)
        .filter(
            QuizSession.student_uid == student_uid,
            QuizSession.subject_id == subject_id,
        )
        .all()
    ]
    if session_ids:
        question_ids = [
            row.question_id
            for row in db.query(Question.question_id)
            .filter(Question.session_id.in_(session_ids))
            .all()
        ]
        if question_ids:
            db.query(QuestionResponse).filter(
                QuestionResponse.question_id.in_(question_ids)
            ).delete(synchronize_session=False)
            db.query(Question).filter(
                Question.question_id.in_(question_ids)
            ).delete(synchronize_session=False)
        db.query(XpTransaction).filter(
            XpTransaction.quiz_session_id.in_(session_ids)
        ).delete(synchronize_session=False)
        db.flush()
        db.query(QuizSession).filter(
            QuizSession.session_id.in_(session_ids)
        ).delete(synchronize_session=False)
        db.flush()

    # 2. This student's BKT mastery state for the subject's skills (Skill rows preserved).
    skill_ids = [
        row.skill_id
        for row in db.query(Skill.skill_id).filter(Skill.subject_id == subject_id).all()
    ]
    if skill_ids:
        db.query(StudentSkillState).filter(
            StudentSkillState.student_uid == student_uid,
            StudentSkillState.skill_id.in_(skill_ids),
        ).delete(synchronize_session=False)

    # 3. This student's garden plant + mastery snapshots for the subject.
    db.query(GardenPlant).filter(
        GardenPlant.student_uid == student_uid,
        GardenPlant.subject_id == subject_id,
    ).delete(synchronize_session=False)
    db.query(MasterySnapshot).filter(
        MasterySnapshot.student_uid == student_uid,
        MasterySnapshot.subject_id == subject_id,
    ).delete(synchronize_session=False)

    # 4. The selection/profile row — its removal returns a global to the catalog.
    db.query(StudentSubjectProfile).filter(
        StudentSubjectProfile.student_uid == student_uid,
        StudentSubjectProfile.subject_id == subject_id,
    ).delete(synchronize_session=False)

    db.commit()
    return True
