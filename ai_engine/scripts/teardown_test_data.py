"""
Remove all AI-engine TEST data seeded by seed_test_data.py for the 3 test
students (resolved by email). Wipes gamification, skill states, subject
profiles, garden plants, mastery snapshots, quiz sessions (cascade →
questions/responses), and the students' per-student subjects (cascade → skills).

This does NOT delete the Firebase Auth / Data Connect accounts — remove those
from the app afterward.

Run from the ai_engine directory with the project venv:

    .venv\\Scripts\\python scripts\\teardown_test_data.py
"""
import os
import sys

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from firebase_admin import auth

from app.core.database import SessionLocal
from app.core.auth import init_firebase
from app.models.domain import (
    Subject,
    QuizSession,
    GardenPlant,
    MasterySnapshot,
    StudentSkillState,
    StudentSubjectProfile,
    StudentGamification,
    XpTransaction,
    CoinTransaction,
    StreakEvent,
)

EMAILS = [
    "sabry109191@gmail.com",
    "sabry109192@gmail.com",
    "sabry109193@gmail.com",
]


def wipe_student(db, uid: str) -> None:
    db.query(XpTransaction).filter_by(student_uid=uid).delete(synchronize_session=False)
    db.query(CoinTransaction).filter_by(student_uid=uid).delete(synchronize_session=False)
    db.query(StreakEvent).filter_by(student_uid=uid).delete(synchronize_session=False)
    db.query(StudentGamification).filter_by(student_uid=uid).delete(synchronize_session=False)
    db.query(MasterySnapshot).filter_by(student_uid=uid).delete(synchronize_session=False)
    db.query(StudentSkillState).filter_by(student_uid=uid).delete(synchronize_session=False)
    db.query(StudentSubjectProfile).filter_by(student_uid=uid).delete(synchronize_session=False)
    db.query(GardenPlant).filter_by(student_uid=uid).delete(synchronize_session=False)
    for s in db.query(QuizSession).filter_by(student_uid=uid).all():
        db.delete(s)
    for subj in db.query(Subject).filter_by(student_uid=uid).all():
        db.delete(subj)
    db.flush()


def main():
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")

    init_firebase()
    db = SessionLocal()
    try:
        for email in EMAILS:
            try:
                uid = auth.get_user_by_email(email).uid
            except Exception as e:
                print(f"  [SKIP] {email}: could not resolve Firebase uid ({e})")
                continue
            wipe_student(db, uid)
            print(f"  Wiped test data for {email} (uid={uid}).")
        db.commit()
        print("Teardown complete. Remove the student accounts from the app to finish.")
    except Exception:
        db.rollback()
        raise
    finally:
        db.close()


if __name__ == "__main__":
    main()