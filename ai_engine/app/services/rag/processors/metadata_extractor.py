"""
Content-Based Metadata Extractor for Egyptian Primary School Textbooks.

Supports: Math, Science, English, Arabic, Social Studies, and more.

CRITICAL DESIGN DECISION:
    We do NOT trust markdown header depth (#, ##, ###) because LlamaParse
    often swaps them randomly. Instead, we detect the chunk's role by
    scanning its CONTENT for known Arabic/English pedagogical patterns.

    Example: A chunk containing "الوحدة (5)" is a Unit header regardless
    of whether LlamaParse marked it as # or ###.
"""
import re
import unicodedata


# ===========================================================================
# Shared ordinal list (Arabic ordinal words, masculine + feminine)
# ===========================================================================
_ORDINALS_MASC = (
    'الأول|الثاني|الثالث|الرابع|الخامس|'
    'السادس|السابع|الثامن|التاسع|العاشر|'
    'الحادي عشر|الثاني عشر|الثالث عشر'
)
_ORDINALS_FEM = (
    'الأولى|الثانية|الثالثة|الرابعة|الخامسة|'
    'السادسة|السابعة|الثامنة|التاسعة|العاشرة|'
    'الحادية عشرة|الثانية عشرة|الثالثة عشرة'
)
_ORDINALS = f'{_ORDINALS_MASC}|{_ORDINALS_FEM}'

# ===========================================================================
# Pattern Definitions (Arabic + English, all subjects)
# ===========================================================================

# --- STRUCTURAL PATTERNS (Headers, Navigation) ---

UNIT_PATTERNS = [
    # Arabic numeric: الوحدة (1), الوحدة 1, الفصل (3) - limited to 1-2 digits to avoid years like 2025
    re.compile(r'الوحدة\s*[\(\[\<{]?\s*\d{1,2}(?!\d)\s*[\)\]\>}]?', re.IGNORECASE),
    re.compile(r'الفصل\s*[\(\[\<{]?\s*\d{1,2}(?!\d)\s*[\)\]\>}]?', re.IGNORECASE),
    # Arabic ordinal: الوحدة الأولى, الوحدة الثانية, الوحدة الرابعة
    re.compile(rf'الوحدة\s+({_ORDINALS_FEM})'),
    re.compile(rf'الفصل\s+({_ORDINALS_MASC})'),
    # English: Unit 1, Chapter 3, Module 2
    re.compile(r'\b(Unit|Chapter|Module|Section)\s+\d{1,2}(?!\d)', re.IGNORECASE),
]

CONCEPT_PATTERNS = [
    # Arabic: المفهوم الأول, المفهوم الثاني
    re.compile(rf'المفهوم\s+({_ORDINALS_MASC})', re.IGNORECASE),
    re.compile(r'مفهوم\s+الوحدة', re.IGNORECASE),
    # Numbered: المفهوم 2-2, المفهوم 1
    re.compile(r'المفهوم\s*[\d-]+', re.IGNORECASE),
    # English
    re.compile(r'\bConcept\s+\d+', re.IGNORECASE),
]

LESSON_PATTERNS = [
    # Arabic ordinal FIRST (so الدرس الأول isn't partially matched by the numeric pattern)
    re.compile(rf'الدرس\s+({_ORDINALS_MASC})'),
    # Arabic numeric: الدرس (1), الدرسان (2 ، 3), الدروس (4 - 6)
    re.compile(r'(?:الدرس|الدرسان|الدروس)\s*[\(\[\<{]?\s*[\d\s،,\-/]+\s*[\)\]\>}]?'),
    # English: Lesson 1
    re.compile(r'\bLesson\s+\d+', re.IGNORECASE),
]

TOC_PATTERNS = [
    # Arabic: فهرس الكتاب, أيقونات الكتاب, المحتويات
    re.compile(r'فهرس\s+الكتاب'),
    re.compile(r'أيقونات\s+الكتاب'),
    re.compile(r'المحتويات'),
    # Dotted page refs: "الدرس (1) ...... 136"
    re.compile(r'\.{3,}\s*\d+'),
    # English
    re.compile(r'\b(Table of Contents|Index|Contents)\b', re.IGNORECASE),
]

# --- FRONT MATTER PATTERNS (copyright, intro, letters) ---
FRONT_MATTER_PATTERNS = [
    re.compile(r'حقوق\s+الطبع', re.IGNORECASE),
    re.compile(r'جميع\s+الحقوق\s+محفوظة', re.IGNORECASE),
    re.compile(r'مقدمة\s+الكتاب', re.IGNORECASE),
    re.compile(r'رسالة\s+إلى\s+(ولي|أولياء)', re.IGNORECASE),
    re.compile(r'عزيزي\s+(التلميذ|الطالب|ولي)', re.IGNORECASE),
    re.compile(r'Copyright', re.IGNORECASE),
    re.compile(r'All\s+rights?\s+reserved', re.IGNORECASE),
    re.compile(r'ISBN\s*[\d-]', re.IGNORECASE),
]

# --- CONTENT PATTERNS (Actual learning material) ---

EXERCISE_PATTERNS = [
    # === Universal (All Subjects, All Publishers) ===
    re.compile(r'تحقق\s+من\s+فهمك'),          # Check your understanding
    re.compile(r'تدريبات?'),                    # Practice / Exercises (generic)
    re.compile(r'تمرين\s*\d*'),                 # Exercise N
    re.compile(r'مهارات\s+عليا'),               # Higher-order skills
    re.compile(r'تقييم'),                        # Assessment (generic)
    re.compile(r'اختبار'),                       # Test (generic)
    re.compile(r'سؤال\s*\d*'),                  # Question N
    re.compile(r'أسئلة\s+متنوعة'),             # Varied questions
    re.compile(r'حل\s+(المسائل|التمارين)'),     # Solve problems/exercises
    re.compile(r'أنشطة\s+تقويمية'),            # Evaluation activities
    # English
    re.compile(r'\b(Exercise|Practice|Quiz|Test|Assessment|Homework|Worksheet)\b', re.IGNORECASE),
    re.compile(r'\b(Choose|Circle|Match|Fill\s+in|Complete|Answer)\b', re.IGNORECASE),
    # === English Subject Specific ===
    re.compile(r'\b(Reading\s+Comprehension|Listening\s+Activity)\b', re.IGNORECASE),
    re.compile(r'\b(Write\s+about|Read\s+and\s+answer|Listen\s+and)\b', re.IGNORECASE),
]

EXAMPLE_PATTERNS = [
    # Arabic: مثال 1, مثال (2)
    re.compile(r'مثال\s*\(?\s*\d*\s*\)?'),
    # English
    re.compile(r'\bExample\s*\d*', re.IGNORECASE),
    # Science: تجربة (Experiment)
    re.compile(r'تجربة\s*\(?\s*\d*\s*\)?'),
    re.compile(r'\bExperiment\s*\d*', re.IGNORECASE),
]

RULE_PATTERNS = [
    # === Universal ===
    re.compile(r'(انتبه|تذكر\s+أن|لاحظ\s+أن|القاعدة|ملحوظة)'),
    re.compile(r'\b(Rule|Remember|Note\s+that|Definition|Important)\b', re.IGNORECASE),
    # === Science ===
    re.compile(r'(استنتاج|ملاحظة|تعريف)'),      # Conclusion, Observation, Definition
    re.compile(r'\b(Conclusion|Observation)\b', re.IGNORECASE),
    # === Arabic Subject ===
    re.compile(r'(القاعدة\s+النحوية|قاعدة\s+إملائية)'),  # Grammar/Spelling rules
    re.compile(r'\b(Grammar\s+Rule)\b', re.IGNORECASE),
]

EXPLANATION_PATTERNS = [
    # === Universal ===
    re.compile(r'(تعلّم|تعلم|استكشف|شرح)'),
    re.compile(r'\b(Learn|Explore|Explanation|Introduction)\b', re.IGNORECASE),
    # === Science ===
    re.compile(r'(نشاط|أنشطة)'),                  # Activity/Activities
    re.compile(r'\b(Activity|Activities)\b', re.IGNORECASE),
    # === Arabic Subject ===
    re.compile(r'(القراءة|النحو|الإملاء|التعبير|نص\s+القراءة)'),  # Reading, Grammar, Spelling, Expression
    re.compile(r'(الاستماع|المحفوظات|الأناشيد)'),  # Listening, Poems, Songs
    # === English Subject ===
    re.compile(r'\b(Reading|Writing|Listening|Speaking|Grammar|Vocabulary|Phonics)\b', re.IGNORECASE),
    # === Social Studies ===
    re.compile(r'(خريطة|جغرافيا|تاريخ|تربية\s+وطنية)'),  # Map, Geography, History, Civics
]

# --- GARBAGE PATTERNS (OCR artifacts, scanner noise) ---
GARBAGE_PATTERNS = [
    re.compile(r'CamScann?e?r?', re.IGNORECASE),  # Full and OCR-truncated variants
    re.compile(r'الممسوحة\s+ضوئياً', re.IGNORECASE),
    re.compile(r'لممسوحة\s+ضوئي', re.IGNORECASE),  # OCR-truncated: "لممسوحة ضوئيا ب"
    re.compile(r'لمسوحة\s+ضوئي', re.IGNORECASE),   # Another truncated variant
    re.compile(r'^[ivxlcdm]+$', re.IGNORECASE),  # Roman numerals only
    re.compile(r'^\s*الكود\s+السريع\s*$', re.MULTILINE),
    re.compile(r'^\s*Photo\s+Credit', re.IGNORECASE | re.MULTILINE),
]


# ===========================================================================
# Header Cleaning Utilities
# ===========================================================================

# Regex to strip trailing page numbers: "الدرس السادس: ... 21" → "الدرس السادس: ..."
_TRAILING_PAGE_NUM = re.compile(r'\s+\d{1,3}\s*$')

# Regex to detect pipe-separated composite headers like "الأُولى | جمع وطرح"
_PIPE_SEPARATOR = re.compile(r'\s*\|\s*')


def _clean_header_value(value: str) -> str:
    """
    Clean a header value by stripping noise:
    - Trailing page numbers (e.g., "الدرس السادس: ... 21" → "الدرس السادس: ...")
    - Leading/trailing whitespace and newlines
    """
    if not value:
        return value
    # Strip newlines that sometimes leak from LlamaParse
    value = value.replace('\n', ' ').strip()
    # Strip trailing page numbers
    value = _TRAILING_PAGE_NUM.sub('', value).strip()
    return value


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
    Extract the matched pattern AND any trailing title after a colon or pipe.
    
    Examples:
        "الوحدة (1): القيمة المكانية" → "الوحدة (1): القيمة المكانية"
        "الدرس الأول"                  → "الدرس الأول"
        "الدرس الثالث: تكوين الكسور"   → "الدرس الثالث: تكوين الكسور"
    """
    for pattern in patterns:
        match = pattern.search(text)
        if match:
            base = match.group(0).strip()
            # Try to capture trailing title after colon, pipe, or dash
            rest_of_line = text[match.end():]
            # Grab up to end of line or next markdown header
            title_match = re.match(r'\s*[:\|]\s*(.+?)(?:\n|$)', rest_of_line)
            if title_match:
                title = title_match.group(1).strip().rstrip('*').strip()
                # Strip trailing page numbers from the title
                title = _TRAILING_PAGE_NUM.sub('', title).strip()
                if title:
                    return f"{base}: {title}"
            return base
    return None


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
