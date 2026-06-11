"""
Subject Strategy Resolver.

Maps a subject name (in any language/variant) to the correct
SubjectStrategy instance via keyword matching.

Falls back to GeneralStrategy if no keyword matches — this ensures
the system never breaks for unknown subjects, it just uses a generic
cognitive taxonomy instead of subject-specific prompts.

To support a new subject:
  1. Create a strategy class in subject_strategies.py
  2. Add keywords here in _KEYWORD_MAP
"""

from app.services.quiz.strategies import (
    SubjectStrategy,
    MathStrategy,
    EnglishStrategy,
    ArabicLangStrategy,
    ScienceStrategy,
    SocialStudiesStrategy,
    GeneralStrategy,
)

# ── Keyword → Strategy mapping ──────────────────────────────────────
# Each keyword is checked via `keyword in name_lower`.
# Order matters: more specific keywords should come first to avoid
# false positives (e.g., "social" before "science").
# Use an ordered list of tuples instead of a dict for control.
_KEYWORD_MAP = [
    # Math
    ("رياضيات", MathStrategy),
    ("حساب", MathStrategy),
    ("math", MathStrategy),
    # English
    ("انجليزي", EnglishStrategy),
    ("إنجليزي", EnglishStrategy),
    ("connect", EnglishStrategy),
    ("english", EnglishStrategy),
    # Arabic Language
    ("لغة عربية", ArabicLangStrategy),
    ("عربي", ArabicLangStrategy),
    ("نحو", ArabicLangStrategy),
    ("arabic", ArabicLangStrategy),
    # Social Studies (before Science to avoid "social" matching "science")
    ("دراسات", SocialStudiesStrategy),
    ("اجتماعية", SocialStudiesStrategy),
    ("تاريخ", SocialStudiesStrategy),
    ("جغرافيا", SocialStudiesStrategy),
    ("تربية وطنية", SocialStudiesStrategy),
    ("social", SocialStudiesStrategy),
    # Science
    ("علوم", ScienceStrategy),
    ("discover", ScienceStrategy),
    ("science", ScienceStrategy),
]


def resolve_subject_strategy(subject_name: str) -> SubjectStrategy:
    """
    Resolve a subject name to its strategy via keyword matching.

    Handles any naming variant:
      - "الرياضيات" → MathStrategy
      - "Math 5th grade" → MathStrategy
      - "English Connect Plus" → EnglishStrategy
      - "random custom subject" → GeneralStrategy

    Returns:
        The matching SubjectStrategy instance, or GeneralStrategy as fallback.
    """
    if not subject_name:
        return GeneralStrategy()

    name_lower = subject_name.lower().strip()

    for keyword, strategy_cls in _KEYWORD_MAP:
        if keyword in name_lower:
            try:
                print(
                    f"[StrategyResolver] Matched '{subject_name}' -> {strategy_cls.__name__} "
                    f"(keyword='{keyword}')",
                    flush=True,
                )
            except UnicodeEncodeError:
                print(
                    f"[StrategyResolver] Matched subject -> {strategy_cls.__name__}",
                    flush=True,
                )
            return strategy_cls()

    try:
        print(
            f"[StrategyResolver] No keyword match for '{subject_name}' -> GeneralStrategy",
            flush=True,
        )
    except UnicodeEncodeError:
        print(
            "[StrategyResolver] No keyword match -> GeneralStrategy",
            flush=True,
        )
    return GeneralStrategy()
