"""
Content-based chunk role detection and garbage filtering.
"""
import re
import unicodedata

from .patterns import (
    TOC_PATTERNS,
    FRONT_MATTER_PATTERNS,
    CONCEPT_PATTERNS,
    UNIT_PATTERNS,
    LESSON_PATTERNS,
    EXERCISE_PATTERNS,
    EXAMPLE_PATTERNS,
    RULE_PATTERNS,
    EXPLANATION_PATTERNS,
    GARBAGE_PATTERNS,
)


def detect_chunk_role(text: str) -> str:
    """
    Detect the pedagogical role of a chunk based on its CONTENT,
    NOT its markdown header level.

    Works across all Egyptian primary school subjects:
    Math, Science, English, Arabic, Social Studies.

    Returns one of:
        'toc', 'front_matter', 'unit_header', 'concept_header', 'lesson_header',
        'exercise', 'example', 'rule', 'explanation', 'content'
    """
    normalized = unicodedata.normalize('NFKC', text)
    # Only check the first 500 chars for role detection (headers are at the top)
    head = normalized[:500]

    # Priority order: TOC > Front Matter > Concept > Unit > Lesson > Exercise > Example > Rule > Explanation
    # (Concept before Unit because chunks like 'المفهوم الأول | الوحدة الرابعة'
    #  should be classified as concept_header, not unit_header)
    if any(p.search(head) for p in TOC_PATTERNS):
        return 'toc'
    if any(p.search(head) for p in FRONT_MATTER_PATTERNS):
        return 'front_matter'
    if any(p.search(head) for p in CONCEPT_PATTERNS):
        return 'concept_header'
    if any(p.search(head) for p in UNIT_PATTERNS):
        return 'unit_header'
    if any(p.search(head) for p in LESSON_PATTERNS):
        return 'lesson_header'
    if any(p.search(head) for p in EXERCISE_PATTERNS):
        return 'exercise'
    if any(p.search(head) for p in EXAMPLE_PATTERNS):
        return 'example'
    if any(p.search(head) for p in RULE_PATTERNS):
        return 'rule'
    if any(p.search(head) for p in EXPLANATION_PATTERNS):
        return 'explanation'

    return 'content'


def is_garbage_chunk(text: str, word_count: int) -> bool:
    """
    Detect if a chunk is garbage that should be filtered out.
    Returns True if the chunk should be discarded.
    """
    normalized = unicodedata.normalize('NFKC', text).strip()

    # Very short chunks with no real content
    if word_count <= 5:
        # Allow short chunks only if they have meaningful math or content
        if not re.search(r'[\d+×÷=<>≤≥]', normalized):
            return True

    # Check known garbage patterns
    if any(p.search(normalized) for p in GARBAGE_PATTERNS):
        # Only discard if it's MOSTLY garbage (short)
        if word_count <= 15:
            return True

    return False