"""
Latency / throughput benchmarks (Chapter 6.3b).

These are ENVIRONMENT-DEPENDENT — the absolute numbers vary by machine, so they
are reported as indicative and the assertions only check loose sanity bounds
(the point is to show the core algorithm loop is cheap and the DB-backed
endpoints respond in tens of milliseconds, not to gate on a hard threshold).

Run with output captured:

    pytest -m benchmark -s tests/benchmark/test_latency_benchmarks.py

NOTE: /quizzes/generate real latency is dominated by the external LLM call and is
therefore NOT micro-benchmarked here — it is measured manually and reported
separately in the chapter. Here the generation service is mocked so we time only
the framework + routing overhead.
"""
import timeit
import platform
import time

import pytest

from app.services.quiz.difficulty_mapper import mastery_to_difficulty
from app.services.evaluation.bkt_engine import BKTEngine
from app.services.quiz.srs_scheduler import select_srs_review_skills
from tests.conftest import make_skill, make_skill_state

pytestmark = pytest.mark.benchmark


def _print_env_once():
    print(f"\n[env] {platform.python_version()} on {platform.system()} "
          f"{platform.machine()}")


# --- Pure-function micro-benchmarks -----------------------------------------

def test_micro_benchmarks_core_functions():
    _print_env_once()
    results = {}

    # difficulty mapper
    results["mastery_to_difficulty"] = timeit.timeit(
        lambda: mastery_to_difficulty(0.55), number=100_000
    ) / 100_000

    # BKT bayesian update (the inner hot path of update_mastery)
    engine = BKTEngine()
    results["_bayesian_update"] = timeit.timeit(
        lambda: engine._bayesian_update(0.5, True, 0.2, 0.1, 0.05), number=100_000
    ) / 100_000

    # SRS ranking over a small mastered set
    from datetime import datetime, timedelta
    now = datetime(2026, 6, 20)
    skills = [
        {"skill": f"s{i}", "mastery": 0.8, "attempts": 3,
         "last_practiced": now - timedelta(days=i)}
        for i in range(20)
    ]
    results["select_srs_review_skills(20)"] = timeit.timeit(
        lambda: select_srs_review_skills(skills, max_review=5, now=now), number=10_000
    ) / 10_000

    print("[micro-benchmarks] mean time per call:")
    for name, secs in results.items():
        print(f"  {name:<34} {secs * 1e6:8.2f} us")

    # Sanity: each of these pure calls is far under a millisecond.
    for name, secs in results.items():
        assert secs < 1e-3, f"{name} unexpectedly slow: {secs * 1e6:.1f} us"


# --- BKT update throughput --------------------------------------------------

def test_bkt_update_throughput():
    """Sustained update_mastery calls/sec on a single skill state."""
    engine = BKTEngine()
    skill = make_skill(skill_id=1, default_learn_rate=0.05)
    state = make_skill_state(skill=skill, mastery_probability=0.01)

    n = 20_000
    start = time.perf_counter()
    for _ in range(n):
        engine.update_mastery(state, "s", difficulty=3, correct=True, response_time=10)
    elapsed = time.perf_counter() - start
    per_call_us = (elapsed / n) * 1e6
    print(f"\n[BKT throughput] {n} update_mastery calls in {elapsed:.3f}s "
          f"-> {n / elapsed:,.0f} calls/sec ({per_call_us:.2f} us/call)")
    assert elapsed < 5.0  # very loose ceiling


# --- Endpoint latency (framework overhead, LLM mocked) ----------------------

def test_submit_endpoint_latency(client, db_session):
    """
    Median/p95 latency of POST /quizzes/submit over several runs (real DB,
    no LLM). Indicative only — reported with the machine spec in the chapter.
    """
    from tests.conftest import (
        seed_levels, make_subject, make_skill as mk_skill,
        make_quiz_session, make_question, TEST_UID,
    )

    seed_levels(db_session)
    subject = make_subject(db_session, name="Math")
    skill = mk_skill(db_session, subject_id=subject.subject_id, name="Fractions")

    def _one_submit():
        session = make_quiz_session(db_session, student_uid=TEST_UID,
                                    subject_id=subject.subject_id, total_questions=1)
        q = make_question(db_session, skill_id=skill.skill_id,
                          session_id=session.session_id, correct_answer="A")
        db_session.flush()
        body = {"quiz_session_id": str(session.session_id),
                "answers": [{"question_id": str(q.question_id),
                             "selected_option": "A", "time_taken_ms": 10000}]}
        t0 = time.perf_counter()
        resp = client.post("/api/v1/quizzes/submit", json=body)
        dt = time.perf_counter() - t0
        assert resp.status_code == 200
        return dt

    # Warm up, then measure.
    _one_submit()
    samples = sorted(_one_submit() for _ in range(15))
    median = samples[len(samples) // 2] * 1000
    p95 = samples[int(len(samples) * 0.95) - 1] * 1000
    print(f"\n[POST /quizzes/submit latency] n=15  median={median:.1f}ms  p95={p95:.1f}ms")
    assert median < 2000  # loose: should be tens of ms, well under 2s


def test_analytics_endpoint_latency(client, db_session):
    from tests.conftest import make_subject, TEST_UID

    make_subject(db_session, name="Astronomy", is_global=False, student_uid=TEST_UID)
    db_session.flush()

    client.get("/api/v1/analytics/subjects")  # warm up

    samples = []
    for _ in range(15):
        t0 = time.perf_counter()
        resp = client.get("/api/v1/analytics/subjects")
        samples.append(time.perf_counter() - t0)
        assert resp.status_code == 200
    samples.sort()
    median = samples[len(samples) // 2] * 1000
    print(f"\n[GET /analytics/subjects latency] n=15  median={median:.1f}ms")
    assert median < 2000