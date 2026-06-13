"""
Subject Profile Resolver.

Maps a subject name (in any language/variant) to the correct SubjectProfile via
keyword matching. Falls back to the GENERAL profile if no keyword matches — so
the system never breaks for unknown subjects, it just uses a generic cognitive
taxonomy instead of subject-specific prompts.

To support a new subject:
  1. Add a SubjectProfile instance in strategies/<subject>.py
  2. Export it from strategies/__init__.py
  3. Add keywords here in _KEYWORD_MAP
"""

from app.services.quiz.strategies import (
    SubjectProfile,
    MATH,
    ENGLISH,
    ARABIC,
    SCIENCE,
    SOCIAL_STUDIES,
    DEFAULT_PROFILE,
)

# ── Keyword → SubjectProfile mapping ────────────────────────────────
# Each keyword is checked via `keyword in name_lower`.
# Order matters: more specific keywords should come first to avoid
# false positives (e.g., "social" before "science").
_KEYWORD_MAP = [
    # Math
    ("رياضيات", MATH),
    ("حساب", MATH),
    ("math", MATH),
    # English
    ("انجليزي", ENGLISH),
    ("إنجليزي", ENGLISH),
    ("connect", ENGLISH),
    ("english", ENGLISH),
    # Arabic Language
    ("لغة عربية", ARABIC),
    ("عربي", ARABIC),
    ("نحو", ARABIC),
    ("arabic", ARABIC),
    # Social Studies (before Science to avoid "social" matching "science")
    ("دراسات", SOCIAL_STUDIES),
    ("اجتماعية", SOCIAL_STUDIES),
    ("تاريخ", SOCIAL_STUDIES),
    ("جغرافيا", SOCIAL_STUDIES),
    ("تربية وطنية", SOCIAL_STUDIES),
    ("social", SOCIAL_STUDIES),
    # Science
    ("علوم", SCIENCE),
    ("discover", SCIENCE),
    ("science", SCIENCE),
]


def resolve_subject_strategy(subject_name: str) -> SubjectProfile:
    """
    Resolve a subject name to its SubjectProfile via keyword matching.

    Handles any naming variant:
      - "الرياضيات" → MATH
      - "Math 5th grade" → MATH
      - "English Connect Plus" → ENGLISH
      - "random custom subject" → DEFAULT_PROFILE (general)

    Returns:
        The matching SubjectProfile, or the general fallback profile.
    """
    if not subject_name:
        return DEFAULT_PROFILE

    name_lower = subject_name.lower().strip()

    for keyword, profile in _KEYWORD_MAP:
        if keyword in name_lower:
            try:
                print(
                    f"[StrategyResolver] Matched '{subject_name}' -> {profile.subject_key} "
                    f"(keyword='{keyword}')",
                    flush=True,
                )
            except UnicodeEncodeError:
                print(
                    f"[StrategyResolver] Matched subject -> {profile.subject_key}",
                    flush=True,
                )
            return profile

    try:
        print(
            f"[StrategyResolver] No keyword match for '{subject_name}' -> {DEFAULT_PROFILE.subject_key}",
            flush=True,
        )
    except UnicodeEncodeError:
        print(
            f"[StrategyResolver] No keyword match -> {DEFAULT_PROFILE.subject_key}",
            flush=True,
        )
    return DEFAULT_PROFILE