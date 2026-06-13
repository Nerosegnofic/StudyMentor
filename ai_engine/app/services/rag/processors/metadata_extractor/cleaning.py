"""
Header-value cleaning and unit/lesson/concept name extraction.
"""
import re
import unicodedata

from .patterns import UNIT_PATTERNS, CONCEPT_PATTERNS, LESSON_PATTERNS


# Regex to strip trailing page numbers: "الدرس السادس: ... 21" → "الدرس السادس: ..."
_TRAILING_PAGE_NUM = re.compile(r'\s+\d{1,3}\s*$')

# Regex to detect pipe-separated composite headers like "الأُولى | جمع وطرح"
_PIPE_SEPARATOR = re.compile(r'\s*\|\s*')

# Bare structural keyword (no title/index) — used to avoid stripping a header's
# structural index as if it were a page number (e.g. "Unit 1" must not become "Unit").
_BARE_STRUCTURAL_KEYWORD = re.compile(
    r'(?:Unit|Chapter|Module|Section|Lesson|الوحدة|الفصل|الدرس|المفهوم)',
    re.IGNORECASE,
)

# Trailing cross-reference to another structural element, e.g. a lesson header that
# repeats its parent unit: "Lesson 1  Life Along The Nile  Unit 1" → drop "  Unit 1".
# Requires 2+ spaces before the cross-ref so mid-title words aren't clipped.
_TRAILING_XREF = re.compile(
    r'\s{2,}(?:Unit|Chapter|Module|Section|Lesson|الوحدة|الفصل|الدرس)\s+\S+\s*$',
    re.IGNORECASE,
)


def _clean_header_value(value: str) -> str:
    """
    Clean a header value by stripping noise:
    - Trailing page numbers (e.g., "الدرس السادس: ... 21" → "الدرس السادس: ...")
    - Leading/trailing whitespace and newlines

    Guards the structural index: stripping the trailing number must not reduce a
    title-less header to a bare keyword (e.g. "Unit 1" → "Unit"). In that case the
    index IS the meaningful part, so keep it.
    """
    if not value:
        return value
    # Strip newlines that sometimes leak from LlamaParse, then collapse internal
    # whitespace runs so OCR variants like "Lesson              3" → "Lesson 3"
    # don't become distinct lesson buckets.
    value = ' '.join(value.replace('\n', ' ').split())
    # Strip trailing page numbers — but not if it leaves only a bare structural keyword
    stripped = _TRAILING_PAGE_NUM.sub('', value).strip()
    if _BARE_STRUCTURAL_KEYWORD.fullmatch(stripped):
        return value
    return stripped


def _is_pipe_composite(value: str) -> bool:
    """
    Check if a header value is a pipe-separated composite like:
    "الأُولى | جمع وطرح الكسور العشرية" or "المفهوم الأول | الوحدة الثالثة"

    These are navigation headers, NOT lesson names.
    """
    if not value:
        return False
    return bool(_PIPE_SEPARATOR.search(value))


def _extract_name(text: str, patterns: list) -> str:
    """Extract the matched name from text using the first matching pattern."""
    for pattern in patterns:
        match = pattern.search(text)
        if match:
            return match.group(0).strip()
    return None


def _extract_full_title(text: str, patterns: list) -> str:
    """
    Extract the matched pattern AND any trailing title.

    The title may be separated from the structural index by a colon/pipe/dash OR by
    plain whitespace — many English/ministry books use "Unit 1  Food, Nature, and
    Culture" (index + spaces + title, no colon) rather than the Arabic colon style.

    Examples:
        "الوحدة (1): القيمة المكانية"        → "الوحدة (1): القيمة المكانية"
        "الدرس الأول"                         → "الدرس الأول"
        "الدرس الثالث: تكوين الكسور"          → "الدرس الثالث: تكوين الكسور"
        "Unit 1  Food, Nature, and Culture"  → "Unit 1: Food, Nature, and Culture"
        "Lesson 1  Life Along The Nile  Unit 1" → "Lesson 1: Life Along The Nile"
        "Lesson 3"                            → "Lesson 3"
    """
    for pattern in patterns:
        match = pattern.search(text)
        if match:
            base = match.group(0).strip()
            rest_of_line = text[match.end():]
            # Capture the title on the SAME line after an optional explicit separator
            # (:, |, -, –) OR horizontal whitespace. Uses [^\S\n] (not \s) so the match
            # never crosses a newline into the next markdown header, and requires a
            # non-space start so a title-less header (trailing spaces only) yields base.
            title_match = re.match(
                r'[^\S\n]*(?:[:\|\-–][^\S\n]*)?(\S.*?)[^\S\n]*(?:\n|$)', rest_of_line
            )
            if title_match:
                # Strip stray markdown markers / leading separators that leak from the
                # parser (e.g. "**: الضرب…" → "الضرب…", "## Lesson" handled by same-line).
                title = title_match.group(1)
                title = re.sub(r'^[\s#*:\-–—]+', '', title)   # leading markers/separators
                title = re.sub(r'[\s#*]+$', '', title)        # trailing markdown noise
                # Drop a trailing cross-reference to another structural element
                # (e.g. a lesson header repeating its parent "  Unit 1").
                title = _TRAILING_XREF.sub('', title).strip()
                # Strip trailing page numbers from the title
                title = _TRAILING_PAGE_NUM.sub('', title).strip()
                if title:
                    return f"{base}: {title}"
            return base
    return None


def extract_context_names(text: str) -> dict:
    """
    Extract unit name, concept name, and lesson name from chunk text.
    Returns a dict with keys that may be None if not found.
    Uses _extract_full_title for richer context (e.g., with lesson topic).
    """
    normalized = unicodedata.normalize('NFKC', text)

    unit_name = _extract_full_title(normalized, UNIT_PATTERNS)
    concept_name = _extract_name(normalized, CONCEPT_PATTERNS)
    lesson_name = _extract_full_title(normalized, LESSON_PATTERNS)

    # Clean extracted names
    if unit_name:
        unit_name = _clean_header_value(unit_name)
    if lesson_name:
        lesson_name = _clean_header_value(lesson_name)

    return {
        'unit_name': unit_name,
        'concept_name': concept_name,
        'lesson_name': lesson_name,
    }


def _scan_header_for_pattern(header_value: str, patterns: list) -> str:
    """
    Check if a markdown header value matches any of the given patterns.
    Returns the extracted name or None.
    """
    if not header_value:
        return None
    normalized = unicodedata.normalize('NFKC', header_value)
    return _extract_full_title(normalized, patterns)