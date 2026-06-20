"""
Shared pytest fixtures for the ai_engine test suite.

The single most important enabler here is ``db_session``: a real SQLAlchemy
session backed by the project's pgvector **Postgres** (the same engine used in
production), so the integration tests run the actual ORM queries — real UUID
columns, ``FOR UPDATE`` locks, and SQL semantics — with no dialect shims.

Isolation is per-test via an outer transaction that is rolled back on teardown:
the schema is created once for the session, each test runs inside a SAVEPOINT-
backed transaction, and nothing it writes survives. This is fast (no per-test
DDL) and fully isolated.

Prerequisites (documented in CLAUDE.md):
    docker-compose up -d                      # start pgvector Postgres
    # a dedicated test database must exist; create once with:
    #   CREATE DATABASE vectordb_test;  CREATE EXTENSION vector;

The connection URL comes from ``TEST_DATABASE_URL`` (falls back to the local
docker-compose Postgres, ``vectordb_test`` database). DB-backed tests are skipped
with a clear message if the database is unreachable, so the pure unit tests and
benchmarks still run anywhere.
"""
import os
import uuid
from datetime import datetime

import pytest
from sqlalchemy import create_engine, event
from sqlalchemy.orm import sessionmaker


TEST_DATABASE_URL = os.environ.get(
    "TEST_DATABASE_URL",
    "postgresql+psycopg://admin:password123@localhost:5433/vectordb_test",
)


def _make_engine():
    """Create the test engine, or return None if the DB is unreachable."""
    try:
        engine = create_engine(TEST_DATABASE_URL, pool_pre_ping=True)
        # Probe connectivity up front so we can skip cleanly rather than error
        # deep inside a test.
        with engine.connect():
            pass
        return engine
    except Exception:
        return None


@pytest.fixture(scope="session")
def _engine():
    """Session-wide Postgres engine with the ORM schema created once."""
    engine = _make_engine()
    if engine is None:
        pytest.skip(
            "Test Postgres is unreachable. Start it with `docker-compose up -d` "
            "and create the test DB (CREATE DATABASE vectordb_test; "
            "CREATE EXTENSION vector;). Override with TEST_DATABASE_URL."
        )

    from app.models.domain import Base

    Base.metadata.create_all(bind=engine)
    yield engine
    Base.metadata.drop_all(bind=engine)
    engine.dispose()


@pytest.fixture
def db_session(_engine):
    """
    A transactional session rolled back after each test for perfect isolation.

    Uses the classic "join an external transaction" pattern: open a connection,
    begin a transaction, bind the session to that connection, and restart a
    SAVEPOINT whenever the code under test commits — so even service code that
    calls ``db.commit()`` stays inside the outer transaction and is rolled back.
    """
    connection = _engine.connect()
    trans = connection.begin()
    SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=connection)
    session = SessionLocal()

    # Start a SAVEPOINT and restart it after each inner commit, so the outer
    # transaction is never actually committed.
    session.begin_nested()

    @event.listens_for(session, "after_transaction_end")
    def _restart_savepoint(sess, transaction):
        if transaction.nested and not transaction._parent.nested:
            sess.begin_nested()

    try:
        yield session
    finally:
        event.remove(session, "after_transaction_end", _restart_savepoint)
        session.close()
        trans.rollback()
        connection.close()


@pytest.fixture
def bkt_engine():
    """A BKTEngine with default BKTConfig. Override config per-test when needed."""
    from app.services.evaluation.bkt_engine import BKTEngine

    return BKTEngine()


# --- API test client --------------------------------------------------------

# A fixed identity used by the auth override in the API tests.
TEST_UID = "api-test-student"


@pytest.fixture
def client(db_session):
    """
    A FastAPI TestClient with auth and DB dependencies overridden.

    - ``get_current_user`` is overridden to return a fixed UID, so no real
      Firebase token verification happens (the routes' auth contract is tested
      separately by clearing the override to assert 401/403 behavior).
    - ``get_db`` is overridden to yield the test's transactional ``db_session``,
      so anything the endpoint writes lives in the same rolled-back transaction.

    The client is NOT used as a context manager, so the app's lifespan (Firebase
    init, vector store, scheduler) does not run — those are external concerns
    mocked or skipped in API tests.
    """
    from app.main import app
    from app.core.auth import get_current_user
    from app.core.database import get_db

    def _override_get_db():
        yield db_session

    app.dependency_overrides[get_current_user] = lambda: TEST_UID
    app.dependency_overrides[get_db] = _override_get_db

    from fastapi.testclient import TestClient
    test_client = TestClient(app, raise_server_exceptions=False)
    test_client.test_uid = TEST_UID  # convenience handle for assertions
    try:
        yield test_client
    finally:
        app.dependency_overrides.clear()


# --- Factory helpers --------------------------------------------------------
# Mirror the hand-built helper style used in the original test_gamification.py.
# They build (and optionally persist) ORM rows with sensible defaults so each
# test only has to specify the fields it actually cares about.

def make_subject(db=None, *, name="Math", is_global=True, student_uid=None, **kw):
    from app.models.domain import Subject

    subject = Subject(name=name, is_global=is_global, student_uid=student_uid, **kw)
    if db is not None:
        db.add(subject)
        db.flush()  # assigns subject_id without committing
    return subject


def make_skill(db=None, *, subject_id=None, name="Adding fractions",
               unit_name="Unit 1", lesson_name="Lesson 1", lesson_index=0,
               default_learn_rate=0.05, **kw):
    from app.models.domain import Skill

    skill = Skill(
        subject_id=subject_id,
        name=name,
        unit_name=unit_name,
        lesson_name=lesson_name,
        lesson_index=lesson_index,
        default_learn_rate=default_learn_rate,
        **kw,
    )
    if db is not None:
        db.add(skill)
        db.flush()
    return skill


def make_skill_state(db=None, *, student_uid="student-1", skill_id=None, skill=None,
                     mastery_probability=0.01, is_mastered=False, attempts=0,
                     last_practiced=None, **kw):
    """
    Build a StudentSkillState.

    ``skill`` can be passed directly so the BKT engine's ``skill_state.skill``
    relationship (used to read ``default_learn_rate``) resolves without a DB —
    handy for pure unit tests that don't use ``db_session``.
    """
    from app.models.domain import StudentSkillState

    state = StudentSkillState(
        student_uid=student_uid,
        skill_id=skill_id if skill_id is not None else (skill.skill_id if skill else None),
        mastery_probability=mastery_probability,
        is_mastered=is_mastered,
        attempts=attempts,
        last_practiced=last_practiced,
        **kw,
    )
    if skill is not None:
        state.skill = skill
    if db is not None:
        db.add(state)
        db.flush()
    return state


def make_quiz_session(db=None, *, student_uid="student-1", subject_id=None,
                      total_questions=5, quiz_context="VOLUNTARY", **kw):
    from app.models.domain import QuizSession

    qs = QuizSession(
        student_uid=student_uid,
        subject_id=subject_id,
        total_questions=total_questions,
        quiz_context=quiz_context,
        **kw,
    )
    if db is not None:
        db.add(qs)
        db.flush()
    return qs


def make_question(db=None, *, skill_id=None, session_id=None,
                  text_content="What is 1/2 + 1/2?", options=None,
                  correct_answer="1", difficulty=3.0, source_enum="AI", **kw):
    from app.models.domain import Question

    q = Question(
        skill_id=skill_id,
        session_id=session_id,
        text_content=text_content,
        options=options if options is not None else ["1", "0.5", "2", "1/4"],
        correct_answer=correct_answer,
        difficulty=difficulty,
        source_enum=source_enum,
        **kw,
    )
    if db is not None:
        db.add(q)
        db.flush()
    return q


def make_response(db=None, *, question_id=None, student_uid="student-1",
                  selected_option="1", is_correct=True, time_taken_ms=10_000,
                  hints_used=0, **kw):
    from app.models.domain import QuestionResponse

    r = QuestionResponse(
        question_id=question_id,
        student_uid=student_uid,
        selected_option=selected_option,
        is_correct=is_correct,
        time_taken_ms=time_taken_ms,
        hints_used=hints_used,
        **kw,
    )
    if db is not None:
        db.add(r)
        db.flush()
    return r


# --- Gamification helpers ---------------------------------------------------

# The default level ladder used by the gamification tests (mirrors production
# seed data). level_for_xp() picks the highest level whose xp_required <= xp.
_DEFAULT_LEVELS = [
    (1, "Seedling", 0),
    (2, "Sprout", 150),
    (3, "Explorer", 350),
    (4, "Curious Mind", 650),
    (5, "Scholar", 1050),
    (6, "Achiever", 1600),
    (7, "Champion", 2300),
    (8, "Sage", 3200),
    (9, "Luminary", 4500),
    (10, "Master", 6000),
]


def seed_levels(db, levels=None):
    """Insert the static Level ladder so level_for_xp() resolves real values."""
    from app.models.domain import Level

    for number, name, xp_required in (levels or _DEFAULT_LEVELS):
        db.add(Level(level_number=number, level_name=name, xp_required=xp_required))
    db.flush()


def make_gamification(db=None, *, student_uid="test-student", xp=0, coins=0,
                      level=1, streak=0, longest_streak=0, last_quiz_date=None, **kw):
    from app.models.domain import StudentGamification

    row = StudentGamification(
        student_uid=student_uid,
        xp_total=xp,
        coins_total=coins,
        current_level=level,
        current_streak=streak,
        longest_streak=longest_streak,
        last_quiz_date=last_quiz_date,
        **kw,
    )
    if db is not None:
        db.add(row)
        db.flush()
    return row


# Expose factories as fixtures too, for tests that prefer dependency injection.
@pytest.fixture
def factories():
    """Bundle of factory helpers for tests that want them injected."""
    return {
        "subject": make_subject,
        "skill": make_skill,
        "skill_state": make_skill_state,
        "quiz_session": make_quiz_session,
        "question": make_question,
        "response": make_response,
    }