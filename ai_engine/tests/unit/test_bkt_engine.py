"""
Unit tests for the Bayesian Knowledge Tracing engine.

Covered in isolation (no DB):
  - ``_adjust_parameters``: how item difficulty and response time shape the
    guess/slip noise model.
  - ``_bayesian_update``: the core HMM mastery update.
  - ``update_mastery``: the orchestration entry point — spam detection,
    forgetting decay, hint penalty, the mastered-badge gate, and the
    gradual ``mastery_step`` dampening.

These use a lightweight skill_state built by the ``make_skill_state`` factory with
an attached in-memory skill, so the ``skill_state.skill.default_learn_rate`` lookup
resolves without touching a database.
"""
from datetime import datetime, timedelta

import pytest

from app.services.evaluation.bkt_engine import BKTEngine
from app.services.evaluation.config import BKTConfig
from tests.conftest import make_skill, make_skill_state


def _state(mastery=0.5, attempts=0, last_practiced=None, learn_rate=0.05):
    """A detached StudentSkillState with an attached skill (no DB needed)."""
    skill = make_skill(skill_id=1, default_learn_rate=learn_rate)
    return make_skill_state(
        skill=skill,
        mastery_probability=mastery,
        attempts=attempts,
        last_practiced=last_practiced,
    )


# --- _adjust_parameters -----------------------------------------------------

@pytest.mark.unit
class TestAdjustParameters:
    def test_harder_item_lowers_guess_and_raises_slip(self, bkt_engine):
        easy_guess, easy_slip = bkt_engine._adjust_parameters(difficulty=1, response_time=60)
        hard_guess, hard_slip = bkt_engine._adjust_parameters(difficulty=5, response_time=60)
        assert hard_guess < easy_guess   # harder -> less likely a correct answer is a guess
        assert hard_slip > easy_slip     # harder -> more likely a knower slips

    def test_difficulty_three_is_the_neutral_pivot(self, bkt_engine):
        """At difficulty 3 (delta=0) guess/slip equal their unmodified base values."""
        guess, slip = bkt_engine._adjust_parameters(difficulty=3, response_time=60)
        cfg = bkt_engine.cfg
        assert guess == pytest.approx(cfg.base_guess)
        assert slip == pytest.approx(cfg.base_slip)

    def test_rushed_answer_lowers_guess_and_raises_slip(self, bkt_engine):
        base_guess, base_slip = bkt_engine._adjust_parameters(difficulty=3, response_time=60)
        rush_guess, rush_slip = bkt_engine._adjust_parameters(difficulty=3, response_time=5)
        assert rush_guess < base_guess
        assert rush_slip > base_slip

    def test_slow_answer_raises_guess_and_lowers_slip(self, bkt_engine):
        base_guess, base_slip = bkt_engine._adjust_parameters(difficulty=3, response_time=60)
        slow_guess, slow_slip = bkt_engine._adjust_parameters(difficulty=3, response_time=200)
        assert slow_guess > base_guess
        assert slow_slip < base_slip

    def test_outputs_are_clamped_to_config_bounds(self, bkt_engine):
        cfg = bkt_engine.cfg
        # Extreme difficulty would push values out of range without clamping.
        for difficulty in (1, 2, 3, 4, 5):
            for rt in (0.5, 5, 60, 200):
                guess, slip = bkt_engine._adjust_parameters(difficulty, rt)
                assert cfg.min_prob <= guess <= cfg.max_prob
                assert cfg.min_prob <= slip <= cfg.max_prob


# --- _bayesian_update -------------------------------------------------------

@pytest.mark.unit
class TestBayesianUpdate:
    def test_correct_answer_raises_mastery(self, bkt_engine):
        new = bkt_engine._bayesian_update(0.5, correct=True, guess=0.2, slip=0.1, learn_rate=0.05)
        assert new > 0.5

    def test_incorrect_answer_lowers_mastery(self, bkt_engine):
        new = bkt_engine._bayesian_update(0.5, correct=False, guess=0.2, slip=0.1, learn_rate=0.05)
        assert new < 0.5

    def test_correct_beats_incorrect_from_same_state(self, bkt_engine):
        """Monotonic in the outcome: a correct answer never ends below a wrong one."""
        c = bkt_engine._bayesian_update(0.5, True, 0.2, 0.1, 0.05)
        w = bkt_engine._bayesian_update(0.5, False, 0.2, 0.1, 0.05)
        assert c > w

    def test_result_is_clamped(self, bkt_engine):
        cfg = bkt_engine.cfg
        very_high = bkt_engine._bayesian_update(0.94, True, 0.2, 0.1, 0.5)
        very_low = bkt_engine._bayesian_update(0.02, False, 0.2, 0.1, 0.0)
        assert very_high <= cfg.max_prob
        assert very_low >= cfg.min_prob


# --- update_mastery ---------------------------------------------------------

@pytest.mark.unit
class TestUpdateMastery:
    def test_correct_answer_increases_mastery_and_attempts(self, bkt_engine):
        state = _state(mastery=0.5, attempts=2)
        before = state.mastery_probability
        bkt_engine.update_mastery(state, "skill", difficulty=3, correct=True, response_time=10)
        assert state.mastery_probability > before
        assert state.attempts == 3
        assert state.last_practiced is not None

    def test_incorrect_answer_decreases_mastery(self, bkt_engine):
        state = _state(mastery=0.6, attempts=2)
        bkt_engine.update_mastery(state, "skill", difficulty=3, correct=False, response_time=10)
        assert state.mastery_probability < 0.6

    def test_spam_answer_increments_count_and_skips_growth(self, bkt_engine):
        """A sub-min_read_seconds answer is spam: quality 0, no upward movement."""
        state = _state(mastery=0.5, attempts=2)
        before = state.mastery_probability
        trigger, spam_count = bkt_engine.update_mastery(
            state, "skill", difficulty=3, correct=True,
            response_time=0.5,  # under min_read_seconds (2.0s)
            current_session_spam_count=0,
        )
        assert spam_count == 1
        assert trigger is False
        # effective_quality forced to 0 -> mastery should not climb.
        assert state.mastery_probability == pytest.approx(before)

    def test_reaching_spam_threshold_triggers_punishment(self, bkt_engine):
        state = _state(mastery=0.5, attempts=2)
        # Already two spam clicks this session; a third trips the threshold (3).
        trigger, spam_count = bkt_engine.update_mastery(
            state, "skill", difficulty=3, correct=True,
            response_time=0.5, current_session_spam_count=2,
        )
        assert spam_count == 3
        assert trigger is True

    def test_genuine_answer_resets_spam_count(self, bkt_engine):
        state = _state(mastery=0.5, attempts=2)
        _, spam_count = bkt_engine.update_mastery(
            state, "skill", difficulty=3, correct=True,
            response_time=10, current_session_spam_count=2,
        )
        assert spam_count == 0

    def test_forgetting_decay_lowers_mastery_after_a_break(self, bkt_engine):
        """A skill last practiced long ago decays before the new update is applied."""
        long_ago = datetime.utcnow() - timedelta(days=30)
        decayed_state = _state(mastery=0.8, attempts=5, last_practiced=long_ago)
        fresh_state = _state(mastery=0.8, attempts=5, last_practiced=datetime.utcnow())

        # Same wrong answer to both; the decayed one should end lower.
        bkt_engine.update_mastery(decayed_state, "s", difficulty=3, correct=False, response_time=10)
        bkt_engine.update_mastery(fresh_state, "s", difficulty=3, correct=False, response_time=10)
        assert decayed_state.mastery_probability < fresh_state.mastery_probability

    def test_hints_reduce_growth(self, bkt_engine):
        no_hint = _state(mastery=0.5, attempts=2)
        with_hints = _state(mastery=0.5, attempts=2)
        bkt_engine.update_mastery(no_hint, "s", difficulty=3, correct=True, response_time=10, hints_used=0)
        bkt_engine.update_mastery(with_hints, "s", difficulty=3, correct=True, response_time=10, hints_used=2)
        assert with_hints.mastery_probability < no_hint.mastery_probability

    def test_mastered_flag_requires_threshold_and_min_attempts(self, bkt_engine):
        cfg = bkt_engine.cfg
        # High mastery but too few attempts -> not mastered yet.
        too_few = _state(mastery=cfg.max_prob, attempts=cfg.mastered_min_attempts - 2)
        bkt_engine.update_mastery(too_few, "s", difficulty=3, correct=True, response_time=10)
        assert too_few.is_mastered is False

    def test_mastered_flag_flips_when_both_conditions_met(self, bkt_engine):
        cfg = bkt_engine.cfg
        ready = _state(mastery=cfg.max_prob, attempts=cfg.mastered_min_attempts)
        bkt_engine.update_mastery(ready, "s", difficulty=3, correct=True, response_time=10)
        assert ready.mastery_probability >= cfg.mastered_threshold
        assert ready.is_mastered is True

    def test_custom_config_is_respected(self):
        """The engine reads thresholds from its injected config, not constants."""
        strict = BKTEngine(BKTConfig(mastered_min_attempts=100))
        state = _state(mastery=0.95, attempts=10)
        strict.update_mastery(state, "s", difficulty=3, correct=True, response_time=10)
        assert state.is_mastered is False  # 10 < 100 attempts