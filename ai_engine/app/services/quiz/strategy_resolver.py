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

from typing import Optional

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


def resolve_subject_strategy(subject_name: str, detected_subject: Optional[str] = None) -> SubjectProfile:
    """
    Resolve a subject to its SubjectProfile via keyword matching.

    Tries the content-classified ``detected_subject`` FIRST (e.g. "Mathematics" from
    ingestion), then falls back to the parent-typed ``subject_name``. So a mislabeled
    upload (an English-medium Math book named "English") resolves correctly via the
    detected subject, and — crucially — if the detected value somehow fails to match,
    we still fall back to the parent's label rather than dropping to GENERAL. Detection
    can therefore only help, never make resolution worse.

    Handles any naming variant:
      - "الرياضيات" → MATH
      - "Math 5th grade" → MATH
      - "English Connect Plus" → ENGLISH
      - "random custom subject" → DEFAULT_PROFILE (general)

    Returns:
        The matching SubjectProfile, or the general fallback profile.
    """
    # Candidate order matters: content-detected subject first, parent label second.
    for candidate in (detected_subject, subject_name):
        if not candidate:
            continue
        name_lower = candidate.lower().strip()
        for keyword, profile in _KEYWORD_MAP:
            if keyword in name_lower:
                try:
                    print(
                        f"[StrategyResolver] Matched '{candidate}' (detected={detected_subject!r}, "
                        f"label={subject_name!r}) -> {profile.subject_key} (keyword='{keyword}')",
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
            f"[StrategyResolver] No keyword match (detected={detected_subject!r}, "
            f"label={subject_name!r}) -> {DEFAULT_PROFILE.subject_key}",
            flush=True,
        )
    except UnicodeEncodeError:
        print(
            f"[StrategyResolver] No keyword match -> {DEFAULT_PROFILE.subject_key}",
            flush=True,
        )
    return DEFAULT_PROFILE