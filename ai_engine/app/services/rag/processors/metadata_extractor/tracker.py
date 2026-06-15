"""
Sequential unit/concept/lesson context tracker.

Walks chunks top-to-bottom and maintains the "current" unit/concept/lesson so each
chunk inherits its curriculum location even when its own text isn't a header.
"""
import re

from .patterns import (
    UNIT_PATTERNS,
    CONCEPT_PATTERNS,
    LESSON_PATTERNS,
    TOC_PATTERNS,
    FRONT_MATTER_PATTERNS,
)
from .cleaning import (
    _clean_header_value,
    _is_pipe_composite,
    _scan_header_for_pattern,
    _PIPE_SEPARATOR,
)


class SequentialContextTracker:
    """
    Tracks the "current" unit, concept, and lesson as we process
    chunks in sequential order (top to bottom of the book).

    KEY DESIGN PRINCIPLES:
        1. Once a lesson is set, it persists until a NEW lesson is explicitly detected.
           Non-lesson headers (topic titles, concept names) do NOT reset the lesson.
        2. We scan ALL md_headers (h1, h2, h3) for unit/lesson/concept patterns,
           regardless of the detected chunk_role. This catches cases where a chunk
           has role="explanation" but h1="الدرس الرابع".
        3. Pipe-separated composite headers (e.g., "الأُولى | جمع وطرح") are
           skipped as navigation artifacts, not real lesson/unit names.
    """

    def __init__(self):
        self.current_unit = None
        self.current_concept = None
        self.current_lesson = None

    def update_and_tag(self, chunk_role: str, context_names: dict,
                       md_headers: dict = None) -> dict:
        """
        Update the tracker state and return the full context for this chunk.

        Args:
            chunk_role: The detected role of the chunk
            context_names: Dict with unit_name, concept_name, lesson_name
            md_headers: Optional dict of markdown headers (h1, h2, h3) from
                       the MarkdownHeaderTextSplitter.
        """
        # ===================================================================
        # STEP 1: Extract context from chunk CONTENT (highest priority)
        # ===================================================================

        # 1a. Update Unit from content
        if context_names.get('unit_name'):
            candidate = _clean_header_value(context_names['unit_name'])
            if candidate and not _is_pipe_composite(candidate):
                self.current_unit = candidate
                self.current_concept = None  # Reset child contexts
                self.current_lesson = None

        # 1b. Update Concept from content
        if context_names.get('concept_name'):
            self.current_concept = context_names['concept_name']

        # 1c. Update Lesson from content
        if context_names.get('lesson_name'):
            candidate = _clean_header_value(context_names['lesson_name'])
            if candidate and not _is_pipe_composite(candidate):
                self.current_lesson = candidate

        # ===================================================================
        # STEP 2: Scan md_headers for unit/lesson/concept patterns
        #         (catches cases where content role is "explanation" but
        #          the h1 header is "الدرس الرابع")
        # ===================================================================
        if md_headers:
            for header_key in ('h1', 'h2', 'h3'):
                header_val = md_headers.get(header_key, '')
                if not header_val:
                    continue

                # Skip pipe-composite navigation headers
                if _is_pipe_composite(header_val):
                    # But still try to extract unit/concept from pipe parts
                    parts = _PIPE_SEPARATOR.split(header_val)
                    for part in parts:
                        part = part.strip()
                        unit_from_part = _scan_header_for_pattern(part, UNIT_PATTERNS)
                        if unit_from_part and not self.current_unit:
                            self.current_unit = _clean_header_value(unit_from_part)
                        concept_from_part = _scan_header_for_pattern(part, CONCEPT_PATTERNS)
                        if concept_from_part:
                            self.current_concept = concept_from_part
                    continue

                # Check for unit pattern in this header
                unit_from_header = _scan_header_for_pattern(header_val, UNIT_PATTERNS)
                if unit_from_header:
                    candidate = _clean_header_value(unit_from_header)
                    if candidate:
                        self.current_unit = candidate
                        # Only reset children if this is an h1 unit header
                        if header_key == 'h1':
                            self.current_concept = None
                            self.current_lesson = None

                # Check for concept pattern in this header
                concept_from_header = _scan_header_for_pattern(header_val, CONCEPT_PATTERNS)
                if concept_from_header:
                    self.current_concept = concept_from_header

                # Check for lesson pattern in this header
                lesson_from_header = _scan_header_for_pattern(header_val, LESSON_PATTERNS)
                if lesson_from_header:
                    candidate = _clean_header_value(lesson_from_header)
                    if candidate:
                        self.current_lesson = candidate

        # ===================================================================
        # STEP 3: h1-fallback for topic-based lesson names
        #         Only used when we have a unit but NO lesson yet.
        #         This handles Sela7 books where lessons use topic titles
        #         like "خاصية التوزيع في عملية الضرب" instead of "الدرس".
        #
        #         CRITICAL: Never overwrite an existing valid lesson!
        # ===================================================================
        if (self.current_lesson is None
                and self.current_unit is not None
                and md_headers is not None):
            h1 = md_headers.get('h1', '')
            if h1 and not _is_pipe_composite(h1):
                # Only use h1 if it looks like a real topic title (not a unit/concept/toc header)
                is_structural = any(
                    p.search(h1) for p in UNIT_PATTERNS + CONCEPT_PATTERNS + LESSON_PATTERNS + TOC_PATTERNS + FRONT_MATTER_PATTERNS
                )
                # Additional guards against garbled OCR page titles
                _REJECT_H1_PATTERNS = [
                    re.compile(r'الصف\s+(?:الخامس|الرابع|السادس|الأول|الثاني|الثالث)', re.IGNORECASE),
                    re.compile(r'الابتدائ', re.IGNORECASE),
                    re.compile(r'الفصل\s+الدراس', re.IGNORECASE),
                    re.compile(r'\d{4}\s*[-–]\s*\d{4}', re.IGNORECASE),  # School year: 2025-2026
                    re.compile(r'الرياضيات', re.IGNORECASE),  # "Mathematics" page header
                    re.compile(r'مقدمة', re.IGNORECASE),  # Introduction pages
                    re.compile(r'حقوق\s+الطبع', re.IGNORECASE),  # Copyright pages
                    re.compile(r'مراجعة', re.IGNORECASE),  # Review header (not a lesson)
                ]
                is_page_title = any(p.search(h1) for p in _REJECT_H1_PATTERNS)
                if not is_structural and not is_page_title:
                    cleaned = _clean_header_value(h1)
                    # Check it's not just a number, noise, or very short
                    if cleaned and len(cleaned) > 3 and not cleaned.strip().isdigit():
                        self.current_lesson = cleaned

        # Return the full inherited context
        return {
            'parent_unit': self.current_unit,
            'parent_concept': self.current_concept,
            'parent_lesson': self.current_lesson,
            'chunk_role': chunk_role,
        }