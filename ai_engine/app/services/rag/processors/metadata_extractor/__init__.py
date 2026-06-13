"""
Content-Based Metadata Extractor for Egyptian Primary School Textbooks.

Supports: Math, Science, English, Arabic, Social Studies, and more.

We do NOT trust markdown header depth (#, ##, ###) because LlamaParse often swaps
them randomly. Instead we detect a chunk's role by scanning its CONTENT for known
Arabic/English pedagogical patterns.

Submodules:
  - patterns:  the content-detection regex pattern lists
  - cleaning:  header-value cleaning + unit/lesson/concept name extraction
  - roles:     chunk role detection + garbage filtering
  - tracker:   SequentialContextTracker (inherited curriculum context)
"""
from .patterns import (
    UNIT_PATTERNS,
    LESSON_PATTERNS,
    CONCEPT_PATTERNS,
    TOC_PATTERNS,
    FRONT_MATTER_PATTERNS,
)
from .cleaning import extract_context_names, _extract_full_title
from .roles import detect_chunk_role, is_garbage_chunk
from .tracker import SequentialContextTracker

__all__ = [
    "SequentialContextTracker",
    "detect_chunk_role",
    "extract_context_names",
    "is_garbage_chunk",
    # Exposed for pattern-validation scripts/tests:
    "UNIT_PATTERNS",
    "LESSON_PATTERNS",
    "CONCEPT_PATTERNS",
    "TOC_PATTERNS",
    "FRONT_MATTER_PATTERNS",
    "_extract_full_title",
]