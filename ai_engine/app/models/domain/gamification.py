"""
Gamification domain models — Phase 1: Core Economy (XP, Coins, Levels).

Tables:
  • student_gamification — aggregate XP/coin/level state per student
  • xp_transactions      — append-only audit log of every XP award
  • coin_transactions    — append-only audit log of every coin award
  • levels               — static seed table defining level thresholds
"""
import uuid
from datetime import datetime
from sqlalchemy import (
    Column, Integer, String, DateTime, ForeignKey, UniqueConstraint,
)
from sqlalchemy.dialects.postgresql import UUID as PG_UUID
from sqlalchemy import Date
from .base import Base


# ── Enums (stored as strings for Postgres readability) ────────────────────

XP_REASONS = (
    "CORRECT_ANSWER",
    "PERFECT_QUIZ_BONUS",
    "SPEED_BONUS",
    "COMEBACK_BONUS",
    "PERSISTENCE_BONUS",
)

COIN_REASONS = (
    "QUIZ_COMPLETION",
    "DAILY_LOGIN",
    "STREAK_MILESTONE",
    "FREEDOM_BONUS",
)


# ── Aggregate state ──────────────────────────────────────────────────────

class StudentGamification(Base):
    __tablename__ = "student_gamification"

    student_uid = Column(String, primary_key=True, index=True)
    xp_total = Column(Integer, nullable=False, default=0)
    coins_total = Column(Integer, nullable=False, default=0)
    current_level = Column(Integer, nullable=False, default=1)
    current_streak = Column(Integer, nullable=False, default=0)
    longest_streak = Column(Integer, nullable=False, default=0)
    last_quiz_date = Column(Date, nullable=True)
    last_login_date = Column(Date, nullable=True)
    last_active_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


# ── Transaction logs ─────────────────────────────────────────────────────

class XpTransaction(Base):
    __tablename__ = "xp_transactions"

    id = Column(PG_UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    student_uid = Column(String, nullable=False, index=True)
    amount = Column(Integer, nullable=False)
    reason = Column(String, nullable=False)  # one of XP_REASONS
    quiz_session_id = Column(
        PG_UUID(as_uuid=True),
        ForeignKey("quiz_sessions.session_id"),
        nullable=True,
    )
    created_at = Column(DateTime, default=datetime.utcnow)


class CoinTransaction(Base):
    __tablename__ = "coin_transactions"

    id = Column(PG_UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    student_uid = Column(String, nullable=False, index=True)
    amount = Column(Integer, nullable=False)
    reason = Column(String, nullable=False)  # one of COIN_REASONS
    created_at = Column(DateTime, default=datetime.utcnow)


class StreakEvent(Base):
    __tablename__ = "streak_events"

    id = Column(PG_UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    student_uid = Column(String, nullable=False, index=True)
    event_type = Column(String, nullable=False)  # "INCREMENT" or "BREAK"
    streak_value = Column(Integer, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)


# ── Static level definitions ─────────────────────────────────────────────

class Level(Base):
    __tablename__ = "levels"

    level_number = Column(Integer, primary_key=True)
    level_name = Column(String, nullable=False)
    xp_required = Column(Integer, nullable=False)
    unlock_description = Column(String, nullable=True)
