"""
Integration tests for GamificationService reward calculations.

These run the service against a REAL (in-memory SQLite) database with a seeded
Level ladder, so the full path — reward math in the service plus the repository's
``update_student_gamification`` / ``level_for_xp`` queries — is exercised for
real. Only the streak-event audit logger is patched (it's an append-only side
effect, not reward logic). The reward arithmetic is asserted exactly.
"""
from unittest.mock import patch

import pytest

from app.services.gamification.gamification_service import GamificationService
from tests.conftest import seed_levels, make_gamification


@pytest.fixture
def svc():
    return GamificationService()


@pytest.fixture
def gami_db(db_session):
    """A db_session with the Level ladder seeded."""
    seed_levels(db_session)
    return db_session


def _rewards(svc, db, student, **kwargs):
    defaults = dict(
        correct_answers=3, total_questions=5,
        total_time_ms=600_000, quiz_context="VOLUNTARY",
    )
    defaults.update(kwargs)
    result = svc.process_quiz_rewards(db, student.student_uid, None, **defaults)
    db.flush()
    return result


@pytest.mark.integration
class TestXpCalculations:
    def test_base_xp_per_correct_answer(self, svc, gami_db):
        student = make_gamification(gami_db)
        result = _rewards(svc, gami_db, student, correct_answers=3)
        assert result["xp_earned"] == 30   # 3 * 10
        assert result["coins_earned"] == 5
        assert student.xp_total == 30      # persisted aggregate

    def test_perfect_quiz_bonus(self, svc, gami_db):
        student = make_gamification(gami_db)
        result = _rewards(svc, gami_db, student, correct_answers=5, total_questions=5)
        assert result["xp_earned"] == 100  # 50 base + 50 perfect

    def test_speed_bonus(self, svc, gami_db):
        student = make_gamification(gami_db)
        result = _rewards(svc, gami_db, student, correct_answers=3, total_time_ms=240_000)
        assert result["xp_earned"] == 35   # 30 base + 5 speed

    def test_all_bonuses_stack(self, svc, gami_db):
        student = make_gamification(gami_db)
        result = _rewards(svc, gami_db, student,
                          correct_answers=5, total_questions=5,
                          total_time_ms=180_000, quiz_context="FORCED", is_comeback=True)
        # 50 base + 50 perfect + 5 speed + 20 comeback + 5 persistence
        assert result["xp_earned"] == 130
        assert result["coins_earned"] == 10  # 5 base + 5 freedom

    def test_zero_correct_zero_xp(self, svc, gami_db):
        student = make_gamification(gami_db)
        result = _rewards(svc, gami_db, student, correct_answers=0)
        assert result["xp_earned"] == 0
        assert result["coins_earned"] == 5   # completion coins still awarded


@pytest.mark.integration
class TestCoinCalculations:
    def test_voluntary_base_coins(self, svc, gami_db):
        student = make_gamification(gami_db)
        result = _rewards(svc, gami_db, student, quiz_context="VOLUNTARY")
        assert result["coins_earned"] == 5

    def test_forced_quiz_freedom_bonus(self, svc, gami_db):
        student = make_gamification(gami_db)
        result = _rewards(svc, gami_db, student, quiz_context="FORCED")
        assert result["coins_earned"] == 10  # 5 base + 5 freedom


@pytest.mark.integration
class TestLevelUp:
    def test_detects_level_up_via_real_level_lookup(self, svc, gami_db):
        # Seeded so that crossing 150 XP promotes to level 2. Starting at 140 XP,
        # a 30-XP quiz lands at 170 -> level_for_xp() returns 2.
        student = make_gamification(gami_db, xp=140, level=1)
        result = _rewards(svc, gami_db, student, correct_answers=3)
        assert student.xp_total == 170
        assert result["did_level_up"] is True
        assert result["new_level"] == 2

    def test_no_level_up_when_threshold_not_crossed(self, svc, gami_db):
        student = make_gamification(gami_db, xp=0, level=1)
        result = _rewards(svc, gami_db, student, correct_answers=1)  # +10 XP
        assert result["did_level_up"] is False
        assert result["new_level"] == 1


@pytest.mark.integration
class TestStreakCalculations:
    def test_first_quiz_starts_streak(self, svc, gami_db):
        student = make_gamification(gami_db)
        with patch("app.services.gamification.gamification_service.log_streak_event"):
            result = _rewards(svc, gami_db, student, correct_answers=1,
                              client_local_date="2026-06-09")
        assert student.current_streak == 1
        assert student.longest_streak == 1
        assert result["streak_incremented"] is True
        assert result["milestone_hit"] is None

    def test_milestone_hit_awards_coins(self, svc, gami_db):
        import datetime
        yesterday = datetime.datetime.utcnow().date() - datetime.timedelta(days=1)
        student = make_gamification(gami_db, streak=2, longest_streak=2,
                                    last_quiz_date=yesterday)
        with patch("app.services.gamification.gamification_service.log_streak_event"):
            result = _rewards(svc, gami_db, student, correct_answers=1,
                              client_local_date=str(yesterday + datetime.timedelta(days=1)))
        assert student.current_streak == 3
        assert result["streak_incremented"] is True
        assert result["milestone_hit"] == 3
        assert result["coins_earned"] == 25  # 5 base + 20 milestone