"""
Unit tests for the GamificationService reward calculations.

These tests verify the XP/coin business rules independently of the database
by using a mock SQLAlchemy session with in-memory student records.
"""
import pytest
from unittest.mock import MagicMock, patch
from app.services.gamification.gamification_service import GamificationService
from app.models.domain.gamification import StudentGamification, Level


@pytest.fixture
def svc():
    return GamificationService()


@pytest.fixture
def mock_db():
    """Create a mock DB session with seeded levels."""
    db = MagicMock()
    return db


def _make_student(uid="test-student", xp=0, coins=0, level=1, streak=0, longest_streak=0, last_quiz_date=None):
    row = StudentGamification(
        student_uid=uid,
        xp_total=xp,
        coins_total=coins,
        current_level=level,
        current_streak=streak,
        longest_streak=longest_streak,
        last_quiz_date=last_quiz_date,
    )
    return row


def _make_levels():
    return [
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


class TestXpCalculations:
    """Verify XP reward rules."""

    @patch("app.services.gamification.gamification_service.log_xp_transaction")
    @patch("app.services.gamification.gamification_service.log_coin_transaction")
    @patch("app.services.gamification.gamification_service.get_or_create_student_gamification")
    @patch("app.services.gamification.gamification_service.level_for_xp")
    def test_base_xp_per_correct_answer(self, mock_level_for_xp, mock_get, mock_coin_log, mock_xp_log, svc, mock_db):
        student = _make_student()
        mock_get.return_value = student
        mock_level_for_xp.return_value = 1

        result = svc.process_quiz_rewards(
            mock_db, "test-student", None,
            correct_answers=3,
            total_questions=5,
            total_time_ms=600_000,   # 10 min, no speed bonus
            quiz_context="VOLUNTARY",
        )

        assert result["xp_earned"] == 30  # 3 * 10
        assert result["coins_earned"] == 5  # base completion only

    @patch("app.services.gamification.gamification_service.log_xp_transaction")
    @patch("app.services.gamification.gamification_service.log_coin_transaction")
    @patch("app.services.gamification.gamification_service.get_or_create_student_gamification")
    @patch("app.services.gamification.gamification_service.level_for_xp")
    def test_perfect_quiz_bonus(self, mock_level_for_xp, mock_get, mock_coin_log, mock_xp_log, svc, mock_db):
        student = _make_student()
        mock_get.return_value = student
        mock_level_for_xp.return_value = 1

        result = svc.process_quiz_rewards(
            mock_db, "test-student", None,
            correct_answers=5,
            total_questions=5,
            total_time_ms=600_000,
            quiz_context="VOLUNTARY",
        )

        # 5*10=50 base + 50 perfect = 100
        assert result["xp_earned"] == 100

    @patch("app.services.gamification.gamification_service.log_xp_transaction")
    @patch("app.services.gamification.gamification_service.log_coin_transaction")
    @patch("app.services.gamification.gamification_service.get_or_create_student_gamification")
    @patch("app.services.gamification.gamification_service.level_for_xp")
    def test_speed_bonus(self, mock_level_for_xp, mock_get, mock_coin_log, mock_xp_log, svc, mock_db):
        student = _make_student()
        mock_get.return_value = student
        mock_level_for_xp.return_value = 1

        result = svc.process_quiz_rewards(
            mock_db, "test-student", None,
            correct_answers=3,
            total_questions=5,
            total_time_ms=240_000,  # 4 min, under 5 min target
            quiz_context="VOLUNTARY",
        )

        # 30 base + 5 speed = 35
        assert result["xp_earned"] == 35

    @patch("app.services.gamification.gamification_service.log_xp_transaction")
    @patch("app.services.gamification.gamification_service.log_coin_transaction")
    @patch("app.services.gamification.gamification_service.get_or_create_student_gamification")
    @patch("app.services.gamification.gamification_service.level_for_xp")
    def test_all_bonuses_stack(self, mock_level_for_xp, mock_get, mock_coin_log, mock_xp_log, svc, mock_db):
        student = _make_student()
        mock_get.return_value = student
        mock_level_for_xp.return_value = 1

        result = svc.process_quiz_rewards(
            mock_db, "test-student", None,
            correct_answers=5,
            total_questions=5,
            total_time_ms=180_000,  # 3 min
            quiz_context="FORCED",
            is_comeback=True,
        )

        # 50 base + 50 perfect + 5 speed + 20 comeback + 5 persistence = 130
        assert result["xp_earned"] == 130
        # 5 base + 5 freedom = 10
        assert result["coins_earned"] == 10

    @patch("app.services.gamification.gamification_service.log_xp_transaction")
    @patch("app.services.gamification.gamification_service.log_coin_transaction")
    @patch("app.services.gamification.gamification_service.get_or_create_student_gamification")
    @patch("app.services.gamification.gamification_service.level_for_xp")
    def test_zero_correct_zero_xp(self, mock_level_for_xp, mock_get, mock_coin_log, mock_xp_log, svc, mock_db):
        student = _make_student()
        mock_get.return_value = student
        mock_level_for_xp.return_value = 1

        result = svc.process_quiz_rewards(
            mock_db, "test-student", None,
            correct_answers=0,
            total_questions=5,
            total_time_ms=600_000,
            quiz_context="VOLUNTARY",
        )

        assert result["xp_earned"] == 0
        assert result["coins_earned"] == 5  # still get completion coins


class TestCoinCalculations:
    """Verify coin reward rules."""

    @patch("app.services.gamification.gamification_service.log_xp_transaction")
    @patch("app.services.gamification.gamification_service.log_coin_transaction")
    @patch("app.services.gamification.gamification_service.get_or_create_student_gamification")
    @patch("app.services.gamification.gamification_service.level_for_xp")
    def test_voluntary_quiz_base_coins(self, mock_level_for_xp, mock_get, mock_coin_log, mock_xp_log, svc, mock_db):
        student = _make_student()
        mock_get.return_value = student
        mock_level_for_xp.return_value = 1

        result = svc.process_quiz_rewards(
            mock_db, "test-student", None,
            correct_answers=3,
            total_questions=5,
            total_time_ms=600_000,
            quiz_context="VOLUNTARY",
        )
        assert result["coins_earned"] == 5

    @patch("app.services.gamification.gamification_service.log_xp_transaction")
    @patch("app.services.gamification.gamification_service.log_coin_transaction")
    @patch("app.services.gamification.gamification_service.get_or_create_student_gamification")
    @patch("app.services.gamification.gamification_service.level_for_xp")
    def test_forced_quiz_freedom_bonus(self, mock_level_for_xp, mock_get, mock_coin_log, mock_xp_log, svc, mock_db):
        student = _make_student()
        mock_get.return_value = student
        mock_level_for_xp.return_value = 1

        result = svc.process_quiz_rewards(
            mock_db, "test-student", None,
            correct_answers=3,
            total_questions=5,
            total_time_ms=600_000,
            quiz_context="FORCED",
        )
        assert result["coins_earned"] == 10  # 5 base + 5 freedom


class TestLevelUp:
    """Verify level-up detection."""

    @patch("app.services.gamification.gamification_service.log_xp_transaction")
    @patch("app.services.gamification.gamification_service.log_coin_transaction")
    @patch("app.services.gamification.gamification_service.get_or_create_student_gamification")
    @patch("app.services.gamification.gamification_service.level_for_xp")
    def test_detects_level_up(self, mock_level_for_xp, mock_get, mock_coin_log, mock_xp_log, svc, mock_db):
        student = _make_student(xp=140, level=1)
        mock_get.return_value = student
        # After adding XP, the level_for_xp should return 2
        mock_level_for_xp.return_value = 2

        result = svc.process_quiz_rewards(
            mock_db, "test-student", None,
            correct_answers=3,
            total_questions=5,
            total_time_ms=600_000,
            quiz_context="VOLUNTARY",
        )

        assert result["did_level_up"] is True
        assert result["new_level"] == 2

    @patch("app.services.gamification.gamification_service.log_xp_transaction")
    @patch("app.services.gamification.gamification_service.log_coin_transaction")
    @patch("app.services.gamification.gamification_service.get_or_create_student_gamification")
    @patch("app.services.gamification.gamification_service.level_for_xp")
    def test_no_level_up_same_level(self, mock_level_for_xp, mock_get, mock_coin_log, mock_xp_log, svc, mock_db):
        student = _make_student(xp=0, level=1)
        mock_get.return_value = student
        mock_level_for_xp.return_value = 1

        result = svc.process_quiz_rewards(
            mock_db, "test-student", None,
            correct_answers=1,
            total_questions=5,
            total_time_ms=600_000,
            quiz_context="VOLUNTARY",
        )

        assert result["did_level_up"] is False

class TestStreakCalculations:
    """Verify streak increments and milestone coin awards."""

    @patch("app.services.gamification.gamification_service.log_streak_event")
    @patch("app.services.gamification.gamification_service.log_xp_transaction")
    @patch("app.services.gamification.gamification_service.log_coin_transaction")
    @patch("app.services.gamification.gamification_service.get_or_create_student_gamification")
    @patch("app.services.gamification.gamification_service.level_for_xp")
    def test_first_quiz_starts_streak(self, mock_level_for_xp, mock_get, mock_coin_log, mock_xp_log, mock_streak_log, svc, mock_db):
        student = _make_student()
        mock_get.return_value = student
        mock_level_for_xp.return_value = 1

        result = svc.process_quiz_rewards(
            mock_db, "test-student", None,
            correct_answers=1,
            total_questions=5,
            total_time_ms=600_000,
            quiz_context="VOLUNTARY",
            client_local_date="2026-06-09",
        )

        assert student.current_streak == 1
        assert student.longest_streak == 1
        assert result["streak_incremented"] is True
        assert result["milestone_hit"] is None

    @patch("app.services.gamification.gamification_service.log_streak_event")
    @patch("app.services.gamification.gamification_service.log_xp_transaction")
    @patch("app.services.gamification.gamification_service.log_coin_transaction")
    @patch("app.services.gamification.gamification_service.get_or_create_student_gamification")
    @patch("app.services.gamification.gamification_service.level_for_xp")
    def test_milestone_hit_awards_coins(self, mock_level_for_xp, mock_get, mock_coin_log, mock_xp_log, mock_streak_log, svc, mock_db):
        import datetime
        yesterday = datetime.datetime.utcnow().date() - datetime.timedelta(days=1)
        student = _make_student(streak=2, longest_streak=2, last_quiz_date=yesterday)
        mock_get.return_value = student
        mock_level_for_xp.return_value = 1

        result = svc.process_quiz_rewards(
            mock_db, "test-student", None,
            correct_answers=1,
            total_questions=5,
            total_time_ms=600_000,
            quiz_context="VOLUNTARY",
            client_local_date=str(yesterday + datetime.timedelta(days=1)),
        )

        assert student.current_streak == 3
        assert result["streak_incremented"] is True
        assert result["milestone_hit"] == 3
        assert result["coins_earned"] == 25  # 5 base + 20 milestone

