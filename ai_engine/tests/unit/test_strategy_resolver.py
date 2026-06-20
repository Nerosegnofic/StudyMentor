"""
Unit tests for the subject-strategy resolver.

``resolve_subject_strategy`` maps a free-text subject name (Arabic or English,
any variant) to a SubjectProfile via keyword matching, falling back to the
general profile for unknown subjects. It also prefers a content-detected subject
over the parent-supplied label when both are given.
"""
import pytest

from app.services.quiz.strategy_resolver import resolve_subject_strategy


@pytest.mark.unit
@pytest.mark.parametrize(
    "name, expected_key",
    [
        # English variants
        ("Math 5th grade", "math"),
        ("الرياضيات", "math"),
        ("English Connect Plus", "english"),
        ("لغة عربية", "arabic_lang"),
        ("علوم", "science"),
        ("Science Discover", "science"),
        ("الدراسات الاجتماعية", "social_studies"),
        ("social studies", "social_studies"),
    ],
)
def test_known_subjects_resolve_to_their_profile(name, expected_key):
    assert resolve_subject_strategy(name).subject_key == expected_key


@pytest.mark.unit
def test_unknown_subject_falls_back_to_general():
    assert resolve_subject_strategy("random custom subject").subject_key == "general"


@pytest.mark.unit
def test_matching_is_case_insensitive():
    assert resolve_subject_strategy("MATH").subject_key == "math"
    assert resolve_subject_strategy("EnGlIsH").subject_key == "english"


@pytest.mark.unit
def test_social_studies_wins_over_science_for_social_keyword():
    """'social' is checked before 'science' so it doesn't false-match science."""
    assert resolve_subject_strategy("Social Science").subject_key == "social_studies"


@pytest.mark.unit
class TestDetectedSubjectPreference:
    def test_detected_subject_takes_priority_over_label(self):
        # A Math book mislabeled "English" by the parent, detected as Math.
        result = resolve_subject_strategy("English", detected_subject="Mathematics")
        assert result.subject_key == "math"

    def test_falls_back_to_label_when_detected_does_not_match(self):
        # Detected value matches nothing; the parent's label still resolves.
        result = resolve_subject_strategy("Math", detected_subject="zzz-unknown")
        assert result.subject_key == "math"

    def test_general_when_neither_matches(self):
        result = resolve_subject_strategy("mystery", detected_subject="also-mystery")
        assert result.subject_key == "general"