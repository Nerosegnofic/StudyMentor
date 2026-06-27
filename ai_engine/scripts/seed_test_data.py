"""
Seed realistic TEST learning data for the parent Reports / AI Daily Summary QA.

Creates per-student subjects + skills, ~30 days of quiz sessions/questions/
responses, skill mastery states, gamification, garden plants, and a mastery
snapshot backfill — for 3 students with distinct profiles so every report state
shows up. Re-runnable: it wipes each student's prior seeded data first.

Student accounts must already exist (created via the app). This script resolves
each student's Firebase UID by email via the Admin SDK, then writes only to the
AI-engine Postgres. Run from the ai_engine directory with the project venv:

    .venv\\Scripts\\python scripts\\seed_test_data.py
"""
import os
import sys
import random
from datetime import datetime, timedelta

# Add ai_engine root to path so `app...` imports resolve.
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from firebase_admin import auth

from app.core.database import SessionLocal, init_db
from app.core.auth import init_firebase
from app.models.domain import (
    Subject,
    Skill,
    QuizSession,
    Question,
    QuestionResponse,
    StudentSkillState,
    StudentSubjectProfile,
    GardenPlant,
    MasterySnapshot,
    StudentGamification,
    XpTransaction,
    CoinTransaction,
    StreakEvent,
)
from app.repositories.gamification_repo import (
    seed_levels,
    level_for_xp,
    log_xp_transaction,
    log_coin_transaction,
    log_streak_event,
)
from app.repositories.garden_repo import upsert_garden_plant

random.seed(42)

# ── Test students (email → profile) ──────────────────────────────────────────
STUDENTS = [
    {"email": "sabry109191@gmail.com", "label": "Ali", "profile": "high"},
    {"email": "sabry109192@gmail.com", "label": "Sara", "profile": "struggling"},
    {"email": "sabry109193@gmail.com", "label": "Omar", "profile": "inactive"},
]

# ── Curriculum template (subject name, color, units → lessons → skills) ───────
CURRICULUM = [
    ("Mathematics", "#1E88E5", [
        ("Numbers & Operations", [
            ("Fractions", ["Adding Fractions", "Comparing Fractions"]),
            ("Decimals", ["Decimal Place Value", "Rounding Decimals"]),
        ]),
        ("Geometry", [
            ("Shapes", ["Area of Rectangles", "Perimeter"]),
            ("Angles", ["Measuring Angles", "Angle Types"]),
        ]),
    ]),
    ("Science", "#43A047", [
        ("Living Things", [
            ("Plants", ["Photosynthesis", "Plant Parts"]),
            ("Animals", ["Food Chains", "Habitats"]),
        ]),
        ("Matter", [
            ("States of Matter", ["Solids & Liquids", "Changes of State"]),
            ("Energy", ["Forms of Energy", "Heat Transfer"]),
        ]),
    ]),
    ("Arabic", "#8E24AA", [
        ("Grammar", [
            ("Nouns", ["Definite Article", "Plurals"]),
            ("Verbs", ["Past Tense", "Present Tense"]),
        ]),
        ("Reading", [
            ("Comprehension", ["Main Idea", "Vocabulary"]),
            ("Writing", ["Sentence Structure", "Spelling"]),
        ]),
    ]),
]

GUESS_MS = 2000  # matches settings.MINIMUM_GENUINE_TIME_MS


# ── Teardown of prior seeded rows (so the script is re-runnable) ──────────────

def wipe_student(db, uid: str) -> None:
    db.query(XpTransaction).filter_by(student_uid=uid).delete(synchronize_session=False)
    db.query(CoinTransaction).filter_by(student_uid=uid).delete(synchronize_session=False)
    db.query(StreakEvent).filter_by(student_uid=uid).delete(synchronize_session=False)
    db.query(StudentGamification).filter_by(student_uid=uid).delete(synchronize_session=False)
    db.query(MasterySnapshot).filter_by(student_uid=uid).delete(synchronize_session=False)
    db.query(StudentSkillState).filter_by(student_uid=uid).delete(synchronize_session=False)
    db.query(StudentSubjectProfile).filter_by(student_uid=uid).delete(synchronize_session=False)
    db.query(GardenPlant).filter_by(student_uid=uid).delete(synchronize_session=False)
    # Sessions: delete via ORM so questions + responses cascade.
    for s in db.query(QuizSession).filter_by(student_uid=uid).all():
        db.delete(s)
    # Subjects owned by this student: cascade to skills → states/chunks/questions.
    for subj in db.query(Subject).filter_by(student_uid=uid).all():
        db.delete(subj)
    db.flush()


# ── Profile knobs ────────────────────────────────────────────────────────────

def skill_mastery(profile: str, idx: int) -> float:
    """Deterministic-ish mastery per skill index for a profile."""
    if profile == "high":
        base = [0.9, 0.85, 0.82, 0.88, 0.79, 0.45, 0.91, 0.76][idx % 8]
    elif profile == "struggling":
        base = [0.35, 0.48, 0.3, 0.55, 0.42, 0.6, 0.28, 0.5][idx % 8]
    else:  # inactive
        base = [0.62, 0.55, 0.48, 0.7, 0.4, 0.58, 0.65, 0.5][idx % 8]
    return round(min(0.95, max(0.05, base + random.uniform(-0.04, 0.04))), 3)


def session_schedule(profile: str):
    """Yield (day_offset, hour, base_accuracy, context, guessing) per session."""
    if profile == "high":
        # Active most of the last 14 days; this week heavier + higher accuracy.
        for d in range(0, 14):
            if d in (1, 4, 9, 12):       # a few rest days
                continue
            acc = 0.9 if d <= 6 else 0.82  # this week slightly higher → +delta
            n = 2 if d <= 6 and d % 2 == 0 else 1
            for _ in range(n):
                yield d, random.choice([16, 17, 18, 19, 20]), acc, "VOLUNTARY", False
    elif profile == "struggling":
        # Active over 3 weeks; this week LOWER accuracy than last → -delta;
        # several forced + guessing sessions.
        for d in range(0, 21):
            if d in (2, 6, 8, 13, 17):
                continue
            acc = 0.45 if d <= 6 else 0.62  # this week worse → negative delta
            guessing = (d <= 6 and d % 2 == 0)
            ctx = "FORCED" if d % 3 == 0 else "VOLUNTARY"
            yield d, random.choice([13, 14, 15, 19, 21]), acc, ctx, guessing
    else:  # inactive — nothing in the last ~4 days
        for d in range(4, 12):
            if d in (5, 9):
                continue
            yield d, random.choice([10, 11, 17]), 0.6, "VOLUNTARY", False


GAM = {
    "high":       dict(xp=2600, coins=820, streak=8, longest=11, last_quiz=0,  last_login=0),
    "struggling": dict(xp=720,  coins=240, streak=2, longest=5,  last_quiz=0,  last_login=0),
    "inactive":   dict(xp=1100, coins=310, streak=0, longest=6,  last_quiz=4,  last_login=4),
}

SNAP_TREND = {  # (start%, end%) over the backfill window
    "high":       (55.0, 85.0),
    "struggling": (62.0, 43.0),
    "inactive":   (50.0, 58.0),
}


# ── Seeding ──────────────────────────────────────────────────────────────────

def make_curriculum(db, uid: str):
    """Create per-student subjects + skills. Returns [(subject, [skills])]."""
    out = []
    for name, color, units in CURRICULUM:
        subj = Subject(name=name, color_hex=color, is_global=False, student_uid=uid)
        db.add(subj)
        db.flush()
        skills = []
        for unit_idx, (unit_name, lessons) in enumerate(units):
            for lesson_idx, (lesson_name, skill_names) in enumerate(lessons):
                for sk_name in skill_names:
                    sk = Skill(
                        subject_id=subj.subject_id,
                        name=sk_name,
                        unit_name=unit_name,
                        lesson_name=lesson_name,
                        lesson_index=lesson_idx,
                        weight=1.0,
                        default_difficulty=2.0,
                        default_learn_rate=0.05,
                    )
                    db.add(sk)
                    skills.append(sk)
        db.flush()
        out.append((subj, skills))
    return out


def make_skill_states(db, uid: str, profile: str, subjects):
    now = datetime.utcnow()
    idx = 0
    for _subj, skills in subjects:
        for sk in skills:
            mastery = skill_mastery(profile, idx)
            attempts = random.randint(20, 40) if profile != "inactive" else random.randint(10, 26)
            last = now - timedelta(days=(random.randint(0, 6) if profile != "inactive" else random.randint(4, 12)))
            db.add(StudentSkillState(
                student_uid=uid,
                skill_id=sk.skill_id,
                mastery_probability=mastery,
                is_mastered=mastery >= 0.80 and attempts >= 20,
                attempts=attempts,
                last_practiced=last,
            ))
            idx += 1


def make_sessions(db, uid: str, profile: str, subjects):
    now = datetime.utcnow()
    subj_cycle = 0
    total = 0
    for day_offset, hour, base_acc, ctx, guessing in session_schedule(profile):
        subj, skills = subjects[subj_cycle % len(subjects)]
        subj_cycle += 1

        start = (now - timedelta(days=day_offset)).replace(
            hour=hour, minute=random.randint(0, 59), second=0, microsecond=0
        )
        if start >= now:
            start = now - timedelta(hours=random.randint(1, 5))
        n_q = 5
        end = start + timedelta(minutes=random.randint(4, 18))

        session = QuizSession(
            student_uid=uid,
            subject_id=subj.subject_id,
            start_time=start,
            end_time=end,
            total_questions=n_q,
            quiz_context=ctx,
        )
        db.add(session)
        db.flush()

        difficulties = [1, 2, 3, 4, 5]
        correct = 0
        spam = 0
        for qi in range(n_q):
            diff = difficulties[qi]
            p_correct = min(0.97, max(0.05, base_acc - (diff - 3) * 0.12))
            is_correct = random.random() < p_correct
            if is_correct:
                correct += 1
                t = random.randint(4000, 22000)
            else:
                if guessing:
                    t = random.randint(400, 1700)
                elif diff <= 2 and random.random() < 0.5:
                    t = random.randint(2200, 8000)   # careless
                else:
                    t = random.randint(11000, 38000)  # concept gap
            if t < GUESS_MS:
                spam += 1

            sk = random.choice(skills)
            q = Question(
                skill_id=sk.skill_id,
                session_id=session.session_id,
                text_content=f"[TEST] Question on {sk.name} (difficulty {diff}).",
                options=["A", "B", "C", "D"],
                correct_answer="A",
                difficulty=float(diff),
                source_enum=random.choice(["AI", "AI", "BANK"]),
                explanation="Seeded test question.",
                hints=[],
                created_at=start,
                submitted_at=end,
            )
            db.add(q)
            db.flush()
            db.add(QuestionResponse(
                question_id=q.question_id,
                student_uid=uid,
                selected_option="A" if is_correct else random.choice(["B", "C", "D"]),
                is_correct=is_correct,
                time_taken_ms=t,
                hints_used=random.choice([0, 0, 0, 1, 2]),
            ))

        session.score = round(100.0 * correct / n_q, 1)
        session.consecutive_spam_clicks = spam
        total += 1
    return total


def make_gamification(db, uid: str, profile: str):
    cfg = GAM[profile]
    today = datetime.utcnow().date()
    row = db.query(StudentGamification).filter_by(student_uid=uid).first()
    if row is None:
        row = StudentGamification(student_uid=uid)
        db.add(row)
    row.xp_total = cfg["xp"]
    row.coins_total = cfg["coins"]
    row.current_level = level_for_xp(db, cfg["xp"])
    row.current_streak = cfg["streak"]
    row.longest_streak = cfg["longest"]
    row.last_quiz_date = today - timedelta(days=cfg["last_quiz"])
    row.last_login_date = today - timedelta(days=cfg["last_login"])
    row.last_active_at = datetime.utcnow() - timedelta(days=cfg["last_quiz"])
    row.updated_at = datetime.utcnow()
    db.flush()

    # A few audit-log rows for completeness.
    log_xp_transaction(db, uid, 50, "CORRECT_ANSWER")
    log_coin_transaction(db, uid, 10, "QUIZ_COMPLETION")
    if cfg["streak"] > 0:
        log_streak_event(db, uid, "INCREMENT", cfg["streak"])
    else:
        log_streak_event(db, uid, "BREAK", 0)


def backfill_snapshots(db, uid: str, profile: str, subjects):
    today = datetime.utcnow().date()
    start_pct, end_pct = SNAP_TREND[profile]
    oldest = 29
    newest = 4 if profile == "inactive" else 1  # inactive stops ~4 days ago
    span = max(1, oldest - newest)
    for subj, _skills in subjects:
        for d in range(oldest, newest - 1, -1):
            frac = (oldest - d) / span
            pct = start_pct + (end_pct - start_pct) * frac + random.uniform(-2.5, 2.5)
            pct = round(min(100.0, max(0.0, pct)), 1)
            db.add(MasterySnapshot(
                student_uid=uid,
                subject_id=subj.subject_id,
                mastery_percent=pct,
                recorded_on=today - timedelta(days=d),
            ))
    db.flush()


def seed_student(db, uid: str, label: str, profile: str):
    wipe_student(db, uid)
    subjects = make_curriculum(db, uid)
    for subj, _ in subjects:
        db.add(StudentSubjectProfile(student_uid=uid, subject_id=subj.subject_id))
    make_skill_states(db, uid, profile, subjects)
    n_sessions = make_sessions(db, uid, profile, subjects)
    make_gamification(db, uid, profile)
    for subj, _ in subjects:
        upsert_garden_plant(db, uid, subj.subject_id)  # mastery_percent + today's snapshot
    backfill_snapshots(db, uid, profile, subjects)
    print(f"  [{label}/{profile}] uid={uid}: {len(subjects)} subjects, {n_sessions} sessions seeded.")


def main():
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")

    init_firebase()
    init_db()
    db = SessionLocal()
    try:
        seed_levels(db)
        for s in STUDENTS:
            try:
                uid = auth.get_user_by_email(s["email"]).uid
            except Exception as e:
                print(f"  [SKIP] {s['email']}: could not resolve Firebase uid ({e})")
                continue
            seed_student(db, uid, s["label"], s["profile"])
        db.commit()
        print("Seeding complete.")
    except Exception:
        db.rollback()
        raise
    finally:
        db.close()


if __name__ == "__main__":
    main()