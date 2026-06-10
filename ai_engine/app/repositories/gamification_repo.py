"""
Gamification repository — data-access functions for the gamification tables.
"""
from datetime import datetime
from sqlalchemy.orm import Session

from app.models.domain.gamification import (
    StudentGamification,
    XpTransaction,
    CoinTransaction,
    Level,
    StreakEvent,
)


# ── Student gamification state ────────────────────────────────────────────

def get_or_create_student_gamification(db: Session, student_uid: str) -> StudentGamification:
    """
    Fetch the student's gamification row.  If it doesn't exist yet, create
    one with all defaults (0 XP, 0 coins, level 1).
    """
    row = (
        db.query(StudentGamification)
        .filter(StudentGamification.student_uid == student_uid)
        .with_for_update()   # lock for atomic update
        .first()
    )
    if row is None:
        row = StudentGamification(student_uid=student_uid)
        db.add(row)
        db.flush()           # materialize the row so callers can read columns
    return row


def update_student_gamification(
    db: Session,
    row: StudentGamification,
    *,
    xp_delta: int = 0,
    coins_delta: int = 0,
) -> None:
    """Apply XP / coin deltas and recalculate the level."""
    row.xp_total += xp_delta
    row.coins_total += coins_delta
    row.current_level = level_for_xp(db, row.xp_total)
    row.updated_at = datetime.utcnow()


# ── Transaction logs ─────────────────────────────────────────────────────

def log_xp_transaction(
    db: Session,
    student_uid: str,
    amount: int,
    reason: str,
    quiz_session_id=None,
) -> None:
    db.add(XpTransaction(
        student_uid=student_uid,
        amount=amount,
        reason=reason,
        quiz_session_id=quiz_session_id,
    ))


def log_coin_transaction(
    db: Session,
    student_uid: str,
    amount: int,
    reason: str,
) -> None:
    db.add(CoinTransaction(
        student_uid=student_uid,
        amount=amount,
        reason=reason,
    ))


def log_streak_event(
    db: Session,
    student_uid: str,
    event_type: str,
    streak_value: int,
) -> None:
    db.add(StreakEvent(
        student_uid=student_uid,
        event_type=event_type,
        streak_value=streak_value,
    ))


# ── Levels ────────────────────────────────────────────────────────────────

def seed_levels(db: Session) -> None:
    """Insert the canonical level rows if the table is empty."""
    if db.query(Level).count() > 0:
        return

    levels = [
        Level(level_number=1,  level_name="Seedling",     xp_required=0),
        Level(level_number=2,  level_name="Sprout",        xp_required=150),
        Level(level_number=3,  level_name="Explorer",      xp_required=350),
        Level(level_number=4,  level_name="Curious Mind",  xp_required=650),
        Level(level_number=5,  level_name="Scholar",       xp_required=1050),
        Level(level_number=6,  level_name="Achiever",      xp_required=1600),
        Level(level_number=7,  level_name="Champion",      xp_required=2300),
        Level(level_number=8,  level_name="Sage",          xp_required=3200),
        Level(level_number=9,  level_name="Luminary",      xp_required=4500),
        Level(level_number=10, level_name="Master",        xp_required=6000),
    ]
    db.add_all(levels)
    db.commit()
    print("[Gamification] Seeded 10 levels.", flush=True)


def get_all_levels(db: Session) -> list[Level]:
    return db.query(Level).order_by(Level.level_number).all()


def level_for_xp(db: Session, xp: int) -> int:
    """Return the highest level_number the student qualifies for."""
    level = (
        db.query(Level)
        .filter(Level.xp_required <= xp)
        .order_by(Level.xp_required.desc())
        .first()
    )
    return level.level_number if level else 1
