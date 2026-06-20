"""
Unit tests for the ZPD difficulty mapper.

``mastery_to_difficulty`` is a pure function mapping a BKT mastery probability
(0.0–1.0) to a 1–5 difficulty tier with boundaries at 0.20/0.40/0.60/0.80. The
interesting behavior lives entirely at those boundaries, so the table below
tests each one from both sides.

(This test suite originally surfaced a docstring that disagreed with the
implementation; the docstring was corrected to match the intended
0.20/0.40/0.60/0.80 bands.)
"""
import pytest

from app.services.quiz.difficulty_mapper import mastery_to_difficulty


@pytest.mark.unit
@pytest.mark.parametrize(
    "mastery, expected",
    [
        (0.00, 1),   # floor of tier 1
        (0.19, 1),   # just below the 0.20 boundary
        (0.20, 2),   # exactly on the boundary -> next tier
        (0.39, 2),   # just below the 0.40 boundary
        (0.40, 3),
        (0.59, 3),
        (0.60, 4),
        (0.79, 4),
        (0.80, 5),
        (1.00, 5),   # ceiling of tier 5
    ],
)
def test_mastery_maps_to_expected_difficulty(mastery, expected):
    assert mastery_to_difficulty(mastery) == expected


@pytest.mark.unit
@pytest.mark.parametrize("mastery", [0.0, 0.123, 0.5, 0.777, 0.95, 1.0])
def test_output_is_always_in_range_1_to_5(mastery):
    """Invariant: every valid mastery yields a difficulty in [1, 5]."""
    assert 1 <= mastery_to_difficulty(mastery) <= 5


@pytest.mark.unit
def test_difficulty_is_monotonic_non_decreasing_in_mastery():
    """Higher mastery never maps to an easier question."""
    masteries = [i / 100 for i in range(0, 101)]
    difficulties = [mastery_to_difficulty(m) for m in masteries]
    assert difficulties == sorted(difficulties)


@pytest.mark.unit
def test_all_five_tiers_are_reachable():
    """Sweeping the full mastery range must surface every difficulty 1..5."""
    reached = {mastery_to_difficulty(i / 100) for i in range(0, 101)}
    assert reached == {1, 2, 3, 4, 5}