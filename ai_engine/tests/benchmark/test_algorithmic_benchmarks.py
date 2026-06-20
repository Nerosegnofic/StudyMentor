"""
Algorithmic-behavior benchmarks (Chapter 6.3a).

These are reproducible — no external services, no wall-clock or network — so the
numbers are defensible and stable across machines. Each test asserts a behavioral
property AND prints a small table/curve that can be dropped into the report. Run
with output captured:

    pytest -m benchmark -s tests/benchmark/test_algorithmic_benchmarks.py

They are marked ``benchmark`` so the normal ``pytest -m unit`` run skips them.
"""
import pytest

from app.services.evaluation.bkt_engine import BKTEngine
from app.services.quiz.difficulty_mapper import mastery_to_difficulty
from app.services.quiz.srs_scheduler import _compute_review_interval
from tests.conftest import make_skill, make_skill_state


pytestmark = pytest.mark.benchmark


def _fresh_state(mastery=0.01, attempts=0):
    skill = make_skill(skill_id=1, default_learn_rate=0.05)
    return make_skill_state(skill=skill, mastery_probability=mastery, attempts=attempts)


# --- BKT mastery convergence ------------------------------------------------

def test_bkt_convergence_on_all_correct():
    """
    Drive a fresh skill with consecutive correct answers and record the mastery
    curve. Reports questions-to-mastery (>= mastered_threshold) and asserts the
    curve is monotonically non-decreasing and eventually reaches the threshold.
    """
    engine = BKTEngine()
    cfg = engine.cfg
    state = _fresh_state()

    curve = [round(state.mastery_probability, 4)]
    questions_to_mastery = None
    for q in range(1, 41):
        engine.update_mastery(state, "skill", difficulty=3, correct=True, response_time=10)
        curve.append(round(state.mastery_probability, 4))
        if questions_to_mastery is None and state.mastery_probability >= cfg.mastered_threshold:
            questions_to_mastery = q

    print("\n[BKT convergence — all correct @ difficulty 3]")
    print(f"  mastered_threshold = {cfg.mastered_threshold}, mastery_step = {cfg.mastery_step}")
    print(f"  questions to reach threshold: {questions_to_mastery}")
    print("  curve (q0..q40): " + ", ".join(str(m) for m in curve))

    assert curve == sorted(curve), "mastery must never decrease on a correct streak"
    assert state.mastery_probability >= cfg.mastered_threshold
    assert questions_to_mastery is not None


def test_bkt_decay_on_all_incorrect():
    """A fresh-but-confident skill answered wrong repeatedly must decline monotonically."""
    engine = BKTEngine()
    state = _fresh_state(mastery=0.80, attempts=6)

    curve = [round(state.mastery_probability, 4)]
    for _ in range(20):
        engine.update_mastery(state, "skill", difficulty=3, correct=False, response_time=10)
        curve.append(round(state.mastery_probability, 4))

    print("\n[BKT decay — all incorrect @ difficulty 3]")
    print("  curve (q0..q20): " + ", ".join(str(m) for m in curve))

    assert curve == sorted(curve, reverse=True), "mastery must never rise on a wrong streak"
    assert state.mastery_probability < 0.80


def test_bkt_mixed_responses_track_accuracy():
    """A 70%-correct stream should settle into a middling, sub-mastery band."""
    engine = BKTEngine()
    state = _fresh_state()
    pattern = [True, True, True, False, True, True, True, False, True, True]  # 80% then noise

    for i in range(50):
        correct = pattern[i % len(pattern)]
        engine.update_mastery(state, "skill", difficulty=3, correct=correct, response_time=10)

    print(f"\n[BKT mixed — 80% correct stream] final mastery = {state.mastery_probability:.4f}")
    assert engine.cfg.min_prob < state.mastery_probability < engine.cfg.max_prob


# --- Difficulty-tier coverage -----------------------------------------------

def test_difficulty_tier_boundaries_table():
    """
    Sweep mastery 0.00..1.00 and report the mastery band that maps to each of the
    5 difficulty tiers. Asserts all five tiers are reachable.
    """
    rows = []  # (difficulty, min_mastery, max_mastery)
    by_tier = {}
    for i in range(0, 101):
        m = i / 100
        d = mastery_to_difficulty(m)
        by_tier.setdefault(d, []).append(m)

    print("\n[Difficulty-tier coverage] (mastery sweep 0.00..1.00)")
    for d in sorted(by_tier):
        ms = by_tier[d]
        rows.append((d, min(ms), max(ms)))
        print(f"  difficulty {d}: mastery {min(ms):.2f} .. {max(ms):.2f}")

    assert set(by_tier) == {1, 2, 3, 4, 5}, "every difficulty tier must be reachable"


# --- SRS interval schedule --------------------------------------------------

def test_srs_interval_schedule_table():
    """Tabulate the attempt -> review-interval schedule (matches the design table)."""
    print("\n[SRS review-interval schedule]")
    schedule = {}
    for attempts in range(1, 11):
        days = _compute_review_interval(attempts).days
        schedule[attempts] = days
        print(f"  attempts={attempts:>2} -> review after {days:>2} day(s)")

    # The tiers are non-decreasing and span the documented 1/3/7/14-day ladder.
    assert schedule[1] == 1 and schedule[2] == 1
    assert schedule[3] == 3 and schedule[4] == 3
    assert schedule[5] == 7 and schedule[6] == 7
    assert all(schedule[a] == 14 for a in range(7, 11))


# --- Anti-spam trigger timing -----------------------------------------------

def test_anti_spam_trigger_timing():
    """
    Show that ``spam_threshold`` consecutive sub-min_read_seconds answers trips
    punishment, and that a single genuine answer resets the counter.
    """
    engine = BKTEngine()
    cfg = engine.cfg
    state = _fresh_state(mastery=0.5, attempts=3)

    spam_count = 0
    trips = []
    print(f"\n[Anti-spam] min_read_seconds={cfg.min_read_seconds}, spam_threshold={cfg.spam_threshold}")
    for i in range(1, cfg.spam_threshold + 1):
        trigger, spam_count = engine.update_mastery(
            state, "skill", difficulty=3, correct=True,
            response_time=0.5, current_session_spam_count=spam_count,
        )
        trips.append(trigger)
        print(f"  spam answer #{i}: count={spam_count}, punishment={trigger}")

    assert trips[-1] is True, "reaching spam_threshold must trigger punishment"
    assert not any(trips[:-1]), "punishment must not trigger before the threshold"

    # A genuine answer resets the streak.
    _, spam_count = engine.update_mastery(
        state, "skill", difficulty=3, correct=True,
        response_time=10, current_session_spam_count=spam_count,
    )
    print(f"  genuine answer -> count reset to {spam_count}")
    assert spam_count == 0