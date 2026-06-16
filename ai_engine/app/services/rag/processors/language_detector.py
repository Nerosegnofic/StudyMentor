"""
Content-based language detection.

Determines whether parsed curriculum text is Arabic- or English-medium purely from
its script composition — zero cost, no LLM. Used to (a) drive a corrective re-parse
when the initial OCR mode disagrees with the actual content, and (b) record the
authoritative language of a document for downstream quiz generation.
"""
import re
from typing import Optional, Tuple

# Arabic letter ranges (base block + supplement + extended-A + presentation forms A/B).
_ARABIC_RE = re.compile(
    "[؀-ۿݐ-ݿࢠ-ࣿﭐ-﷿ﹰ-﻿]"
)
_LATIN_RE = re.compile(r"[A-Za-z]")

# Subject-name keywords hinting an English-medium textbook. Used ONLY to seed the
# first OCR pass; the content-based detectors above are authoritative thereafter.
_ENGLISH_SUBJECT_PATTERNS = re.compile(r"(?:english|connect|انجليز|إنجليز)", re.IGNORECASE)


def guess_language_from_subject_name(subject_name: Optional[str]) -> str:
    """
    Best-effort initial OCR-language guess from the parent's subject label.

    Returns "en" for English-medium-looking names, else "ar" (the conservative default,
    since most Egyptian primary textbooks are Arabic). This is only the first-pass seed —
    ingestion verifies it against the parsed content and re-parses if it was wrong.
    """
    if subject_name and _ENGLISH_SUBJECT_PATTERNS.search(subject_name):
        return "en"
    return "ar"


def language_scores(text: Optional[str]) -> Tuple[float, float]:
    """Return (arabic_ratio, latin_ratio) over letter characters. (0.0, 0.0) if no letters."""
    if not text:
        return 0.0, 0.0
    arabic = len(_ARABIC_RE.findall(text))
    latin = len(_LATIN_RE.findall(text))
    total = arabic + latin
    if total == 0:
        return 0.0, 0.0
    return arabic / total, latin / total


def detect_language(text: Optional[str], default: str = "ar") -> str:
    """
    Return "ar" or "en" based on the dominant script.

    Defaults to Arabic (the majority of Egyptian primary textbooks) when the text has
    no decisive signal (e.g. empty / numbers-only).
    """
    arabic_ratio, latin_ratio = language_scores(text)
    if arabic_ratio == 0.0 and latin_ratio == 0.0:
        return default
    return "ar" if arabic_ratio >= latin_ratio else "en"


def dominant_language(text: Optional[str], threshold: float = 0.70) -> Optional[str]:
    """
    Return "ar"/"en" only when that script is a clear majority (>= threshold) of the
    letters; otherwise None.

    The conservative threshold prevents genuinely bilingual books (e.g. an English
    textbook with an Arabic glossary) from flip-flopping the parse mode.
    """
    arabic_ratio, latin_ratio = language_scores(text)
    if arabic_ratio >= threshold:
        return "ar"
    if latin_ratio >= threshold:
        return "en"
    return None