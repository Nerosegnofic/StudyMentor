"""
Unit tests for the analytics status/trend categorization helpers.

Both are pure functions used to label skills and mastery movement on the
analytics dashboard. The thresholds (0.80 mastered, 0.01 active floor, ±0.02
trend band) come from ``analytics_service`` module constants.
"""
import pytest

from app.services.evaluation.analytics_service import (
    categorise_skill_status,
    compute_mastery_trend,
)


# --- categorise_skill_status ------------------------------------------------

@pytest.mark.unit
@pytest.mark.parametrize(
    "mastery, is_mastered, attempts, expected",
    [
        (0.10, True, 3, "MASTERED"),    # flag wins regardless of mastery
        (0.80, False, 5, "MASTERED"),   # exactly on the 0.80 threshold
        (0.95, False, 5, "MASTERED"),
        (0.79, False, 5, "ACTIVE"),     # below mastered, but attempted
        (0.01, False, 1, "ACTIVE"),     # attempts > 0 -> active
        (0.50, False, 0, "ACTIVE"),     # mastery above the 0.01 floor -> active
        (0.01, False, 0, "LOCKED"),     # initial value, never attempted
    ],
)
def test_categorise_skill_status(mastery, is_mastered, attempts, expected):
    assert categorise_skill_status(mastery, is_mastered, attempts) == expected


# --- compute_mastery_trend --------------------------------------------------

@pytest.mark.unit
class TestComputeMasteryTrend:
    def test_none_previous_is_stable(self):
        assert compute_mastery_trend(0.5, None) == "stable"

    @pytest.mark.parametrize(
        "current, previous, expected",
        [
            (0.60, 0.50, "improving"),   # +0.10 clearly improving
            (0.50, 0.60, "declining"),   # -0.10 clearly declining
            (0.50, 0.50, "stable"),      # no change
            (0.521, 0.50, "improving"),  # +0.021, just over the +0.02 band
            (0.479, 0.50, "declining"),  # -0.021, just under the -0.02 band
            (0.52, 0.50, "stable"),      # exactly +0.02 -> band is exclusive -> stable
            (0.48, 0.50, "stable"),      # exactly -0.02 -> band is exclusive -> stable
        ],
    )
    def test_trend_bands(self, current, previous, expected):
        # The band is exclusive (> 0.02 / < -0.02); exactly ±0.02 is "stable".
        # This boundary is only correct because the implementation rounds away
        # float-subtraction noise (0.52 - 0.50 == 0.020000000000000018 raw).
        assert compute_mastery_trend(current, previous) == expected