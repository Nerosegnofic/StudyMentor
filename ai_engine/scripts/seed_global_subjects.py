"""
Seed admin-published GLOBAL subjects (shared curriculum) by name.

Creates an is_global=True, student_uid=NULL Subject row per name if it does not
already exist. This only registers the subject; upload its curriculum PDF via
POST /documents/upload-global (which reuses get_or_create_global_subject) to
populate skills + chunks.

Usage:
    python scripts/seed_global_subjects.py "الرياضيات" "English Connect" "العلوم"
    python scripts/seed_global_subjects.py            # uses DEFAULT_SUBJECTS below
"""
import sys
import os

# Add the parent directory (ai_engine) to the Python path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.core.database import SessionLocal
from app.repositories.subject_repo import get_or_create_global_subject

DEFAULT_SUBJECTS = [
    "الرياضيات",
    "اللغة العربية",
    "English",
    "العلوم",
    "الدراسات الاجتماعية",
]


def seed_global_subjects(names):
    db = SessionLocal()
    try:
        for name in names:
            name = name.strip()
            if not name:
                continue
            subject = get_or_create_global_subject(db, name)
            print(f"  ✓ global subject ready: id={subject.subject_id}  name={subject.name!r}")
    finally:
        db.close()


if __name__ == "__main__":
    subjects = sys.argv[1:] or DEFAULT_SUBJECTS
    print(f"Seeding {len(subjects)} global subject(s)...")
    seed_global_subjects(subjects)
    print("Done.")