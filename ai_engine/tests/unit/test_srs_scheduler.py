"""
Unit tests for the spaced-repetition scheduler.

All three functions are pure and accept an injectable ``now``, so every test
below is fully deterministic — no wall-clock dependence.

  - ``_compute_review_interval``: SM-2-inspired attempt -> interval tiers.
  - ``count_due_reviews``: how many mastered skills are due right now.
  - ``select_srs_review_skills``: most-overdue-first ranking, capped.
"""
from datetime import datetime, timedelta

import pytest

from app.services.quiz.srs_scheduler import (
    _compute_review_interval,
    count_due_reviews,
    select_srs_review_skills,
)


NOW = datetime(2026, 6, 20, 12, 0, 0)


def _entry(skill="s", mastery=0.9, last_practiced=None, attempts=1):
    return {
        "skill": skill,
        "mastery": mastery,
        "last_practiced": last_practiced,
        "attempts": attempts,
    }


# --- _compute_review_interval -----------------------------------------------

@pytest.mark.unit
@pytest.mark.parametrize(
    "attempts, expected_days",
    [
        (1, 1), (2, 1),     # tier 1
        (3, 3), (4, 3),     # tier 2
        (5, 7), (6, 7),     # tier 3
        (7, 14), (20, 14),  # tier 4 (7+)
    ],
)
def test_interval_tiers(attempts, expected_days):
    assert _compute_review_interval(attempts) == timedelta(days=expected_days)


# --- count_due_reviews ------------------------------------------------------

@pytest.mark.unit
class TestCountDueReviews:
    def test_empty_list_is_zero(self):
        assert count_due_reviews([], now=NOW) == 0

    def test_never_practiced_counts_as_due(self):
        skills = [_entry(last_practiced=None)]
        assert count_due_reviews(skills, now=NOW) == 1

    def test_overdue_skill_is_due(self):
        # 1 attempt -> 1 day interval; practiced 5 days ago -> overdue.
        skills = [_entry(attempts=1, last_practiced=NOW - timedelta(days=5))]
        assert count_due_reviews(skills, now=NOW) == 1

    def test_recently_practiced_skill_is_not_due(self):
        # 7+ attempts -> 14 day interval; practiced 1 day ago -> not due.
        skills = [_entry(attempts=10, last_practiced=NOW - timedelta(days=1))]
        assert count_due_reviews(skills, now=NOW) == 0

    def test_counts_only_the_due_ones(self):
        skills = [
            _entry(attempts=1, last_practiced=NOW - timedelta(days=5)),   # due
            _entry(attempts=10, last_practiced=NOW - timedelta(days=1)),  # not due
            _entry(last_practiced=None),                                  # due
        ]
        assert count_due_reviews(skills, now=NOW) == 2


# --- select_srs_review_skills -----------------------------------------------

@pytest.mark.unit
class TestSelectSrsReviewSkills:
    def test_empty_or_zero_cap_returns_empty(self):
        assert select_srs_review_skills([], max_review=3, now=NOW) == []
        assert select_srs_review_skills([_entry()], max_review=0, now=NOW) == []

    def test_respects_max_review_cap(self):
        skills = [_entry(skill=f"s{i}", last_practiced=None) for i in range(5)]
        result = select_srs_review_skills(skills, max_review=2, now=NOW)
        assert len(result) == 2

    def test_most_overdue_sorts_first(self):
        slightly = _entry(skill="slightly", attempts=1, last_practiced=NOW - timedelta(days=2))
        very = _entry(skill="very", attempts=1, last_practiced=NOW - timedelta(days=20))
        result = select_srs_review_skills([slightly, very], max_review=2, now=NOW)
        assert result[0]["skill"] == "very"

    def test_never_practiced_outranks_merely_overdue(self):
        never = _entry(skill="never", last_practiced=None)
        overdue = _entry(skill="overdue", attempts=1, last_practiced=NOW - timedelta(days=10))
        result = select_srs_review_skills([never, overdue], max_review=2, now=NOW)
        assert result[0]["skill"] == "never"

    def test_lower_mastery_breaks_near_ties(self):
        """Two equally-overdue skills: the more fragile (lower mastery) comes first."""
        fragile = _entry(skill="fragile", mastery=0.50, attempts=1,
                         last_practiced=NOW - timedelta(days=5))
        solid = _entry(skill="solid", mastery=0.95, attempts=1,
                       last_practiced=NOW - timedelta(days=5))
        result = select_srs_review_skills([solid, fragile], max_review=2, now=NOW)
        assert result[0]["skill"] == "fragile"