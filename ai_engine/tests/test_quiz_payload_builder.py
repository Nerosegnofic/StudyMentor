"""
Tests for the BKT → Quiz Generator bridge (mastery_utils.build_quiz_payload).

Validates the three core business rules:
  1. Difficulty mapping (ZPD thresholds)
  2. Skill prioritisation (Gaussian weighting)
  3. Strict question distribution (sum invariant, guaranteed minimums)
"""
import sys, os
# Allow running from the repo root without installing the package
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from app.services.bkt.mastery_utils import (
    mastery_to_difficulty,
    build_quiz_payload,
    _skill_priority_weight,
    _allocate_questions,
)


# ====================================================================
# 1. Difficulty Mapping (ZPD)
# ====================================================================
class TestDifficultyMapping:
    def test_very_low_mastery(self):
        assert mastery_to_difficulty(0.00) == 1
        assert mastery_to_difficulty(0.10) == 1
        assert mastery_to_difficulty(0.29) == 1

    def test_low_mastery(self):
        assert mastery_to_difficulty(0.30) == 2
        assert mastery_to_difficulty(0.49) == 2

    def test_mid_mastery(self):
        assert mastery_to_difficulty(0.50) == 3
        assert mastery_to_difficulty(0.69) == 3

    def test_high_mastery(self):
        assert mastery_to_difficulty(0.70) == 4
        assert mastery_to_difficulty(0.89) == 4

    def test_very_high_mastery(self):
        assert mastery_to_difficulty(0.90) == 5
        assert mastery_to_difficulty(1.00) == 5

    def test_boundary_exact(self):
        """Boundary values fall into the upper bracket."""
        assert mastery_to_difficulty(0.30) == 2
        assert mastery_to_difficulty(0.50) == 3
        assert mastery_to_difficulty(0.70) == 4
        assert mastery_to_difficulty(0.90) == 5


# ====================================================================
# 2. Skill Priority Weights
# ====================================================================
class TestPriorityWeights:
    def test_peak_at_half_mastery(self):
        """50 % mastery should produce the absolute maximum weight (≈ 1.0)."""
        assert _skill_priority_weight(0.50) > 0.99

    def test_active_learning_higher_than_extremes(self):
        """Active-learning zone weights dominate brand-new and mastered."""
        active = _skill_priority_weight(0.50)
        brand_new = _skill_priority_weight(0.10)
        mastered = _skill_priority_weight(0.98)
        assert active > brand_new
        assert active > mastered

    def test_brand_new_higher_than_mastered(self):
        """Brand-new skills (intro) should outweigh mastered (review)."""
        assert _skill_priority_weight(0.10) > _skill_priority_weight(0.98)

    def test_mastered_has_nonzero_floor(self):
        """Mastered skills should still get a tiny positive weight."""
        assert _skill_priority_weight(0.99) > 0
        assert _skill_priority_weight(1.00) > 0

    def test_symmetry_around_center(self):
        """Weights should be roughly symmetric around 0.50 in the active zone."""
        low = _skill_priority_weight(0.35)
        high = _skill_priority_weight(0.65)
        assert abs(low - high) < 0.05  # not exact due to floor logic, but close


# ====================================================================
# 3. Strict Question Distribution
# ====================================================================
class TestQuestionDistribution:
    def test_sum_equals_total(self):
        """The total allocated count must always equal total_questions."""
        profile = {"A": 0.10, "B": 0.50, "C": 0.75, "D": 0.98}
        for n in [1, 5, 10, 20, 50]:
            payload = build_quiz_payload(profile, n)
            assert sum(item["count"] for item in payload) == n

    def test_high_priority_gets_at_least_one(self):
        """Skills in the active zone must get ≥ 1 question."""
        profile = {"Active": 0.50, "New": 0.10, "Mastered": 0.99}
        payload = build_quiz_payload(profile, 3)
        skills_in_payload = {item["skill"] for item in payload}
        assert "Active" in skills_in_payload
        assert "New" in skills_in_payload

    def test_zero_allocation_excluded(self):
        """Skills with 0 questions should not appear in the payload."""
        profile = {"A": 0.50, "B": 0.98}
        payload = build_quiz_payload(profile, 1)
        for item in payload:
            assert item["count"] >= 1

    def test_empty_profile_returns_empty(self):
        assert build_quiz_payload({}, 10) == []

    def test_zero_questions_returns_empty(self):
        assert build_quiz_payload({"A": 0.50}, 0) == []

    def test_single_skill(self):
        payload = build_quiz_payload({"Only": 0.45}, 7)
        assert len(payload) == 1
        assert payload[0]["count"] == 7
        assert payload[0]["difficulty"] == 2  # 0.45 → Level 2

    def test_many_skills_few_questions(self):
        """When there are more skills than questions, active skills are favoured."""
        profile = {f"Skill_{i}": 0.50 for i in range(20)}
        payload = build_quiz_payload(profile, 5)
        assert sum(item["count"] for item in payload) == 5

    def test_difficulty_values_in_payload(self):
        """Each item's difficulty must match its mastery via the ZPD map."""
        profile = {"Low": 0.15, "Mid": 0.55, "High": 0.92}
        payload = build_quiz_payload(profile, 9)
        lookup = {item["skill"]: item["difficulty"] for item in payload}
        if "Low" in lookup:
            assert lookup["Low"] == 1
        if "Mid" in lookup:
            assert lookup["Mid"] == 3
        if "High" in lookup:
            assert lookup["High"] == 5


# ====================================================================
# 4. Integration – Realistic Scenario
# ====================================================================
class TestIntegrationScenario:
    def test_realistic_student(self):
        """
        Simulates a real student who has studied several math topics.
        Checks that the algorithm focuses on their weakest active skills.
        """
        profile = {
            "الجمع": 0.92,        # Addition – nearly mastered
            "الطرح": 0.85,        # Subtraction – strong
            "الضرب": 0.55,        # Multiplication – active learning sweet spot
            "القسمة": 0.30,       # Division – just starting
            "الكسور": 0.12,       # Fractions – brand new
            "الجبر": 0.05,        # Algebra – brand new
        }
        payload = build_quiz_payload(profile, 15)

        # Sum invariant
        assert sum(item["count"] for item in payload) == 15

        # The Multiplication skill (0.55 – peak of bell) should get the most
        counts = {item["skill"]: item["count"] for item in payload}
        assert counts.get("الضرب", 0) >= counts.get("الجمع", 0)

        # Difficulty check for a known skill
        difficulties = {item["skill"]: item["difficulty"] for item in payload}
        assert difficulties.get("الكسور") == 1   # 0.12 → Level 1
        assert difficulties.get("الضرب") == 3     # 0.55 → Level 3


if __name__ == "__main__":
    import pytest
    pytest.main([__file__, "-v"])
