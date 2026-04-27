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
# Pattern Definitions (Arabic + English, all subjects)
# ===========================================================================

# --- STRUCTURAL PATTERNS (Headers, Navigation) ---

UNIT_PATTERNS = [
    # Arabic: الوحدة (1), الوحدة 1, الفصل (3)
    re.compile(r'الوحدة\s*\(?\s*\d+\s*\)?', re.IGNORECASE),
    re.compile(r'الفصل\s*\(?\s*\d+\s*\)?', re.IGNORECASE),
    # English: Unit 1, Chapter 3, Module 2
    re.compile(r'\b(Unit|Chapter|Module)\s+\d+', re.IGNORECASE),
]

CONCEPT_PATTERNS = [
    # Arabic: المفهوم الأول, المفهوم الثاني, مفهوم الوحدة
    re.compile(r'المفهوم\s+(الأول|الثاني|الثالث|الرابع|الخامس|السادس)', re.IGNORECASE),
    re.compile(r'مفهوم\s+الوحدة', re.IGNORECASE),
    # English
    re.compile(r'\bConcept\s+\d+', re.IGNORECASE),
]

LESSON_PATTERNS = [
    # Arabic: الدرس (1), الدرسان (2 ، 3)
    re.compile(r'الدرس(?:ان)?\s*\(?\s*[\d\s،,]+\s*\)?', re.IGNORECASE),
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

# === Action verbs used by ChunkClassifier (expanded for all subjects) ===
# These are exported for use by classifier.py if needed
ALL_SUBJECT_ACTION_VERBS_AR = (
    r'(أوجد|احسب|حل|اختر|أكمل|قارن|حدد|استنتج|اكتب|'
    r'صف|فسر|علل|رتب|صنف|لاحظ|ارسم|اقرأ|استمع|عبر|'
    r'اذكر|وضح|ميز|حوط|صل|ضع\s+علامة|أعرب|استخرج|هات)'
)

ALL_SUBJECT_ACTION_VERBS_EN = (
    r'(Find|Solve|Calculate|Choose|Select|Complete|Compare|'
    r'Question|Exercise|Determine|Describe|Explain|Draw|'
    r'Read|Write|Listen|Match|Circle|Fill|Label|Identify|'
    r'Classify|Order|Sort|Underline|Correct|Rewrite)'
)


def _extract_name(text: str, patterns: list) -> str:
    """Extract the matched name from text using the first matching pattern."""
    for pattern in patterns:
        match = pattern.search(text)
        if match:
            return match.group(0).strip()
    return None


def detect_chunk_role(text: str) -> str:
    """
    Detect the pedagogical role of a chunk based on its CONTENT, 
    NOT its markdown header level.
    
    Works across all Egyptian primary school subjects:
    Math, Science, English, Arabic, Social Studies.
    
    Returns one of:
        'toc', 'unit_header', 'concept_header', 'lesson_header',
        'exercise', 'example', 'rule', 'explanation', 'content'
    """
    normalized = unicodedata.normalize('NFKC', text)
    # Only check the first 500 chars for role detection (headers are at the top)
    head = normalized[:500]

    # Priority order: TOC > Unit > Concept > Lesson > Exercise > Example > Rule > Explanation
    if any(p.search(head) for p in TOC_PATTERNS):
        return 'toc'
    if any(p.search(head) for p in UNIT_PATTERNS):
        return 'unit_header'
    if any(p.search(head) for p in CONCEPT_PATTERNS):
        return 'concept_header'
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
    
    return 'content'  # Default: regular instructional content


def extract_context_names(text: str) -> dict:
    """
    Extract unit name, concept name, and lesson name from chunk text.
    Returns a dict with keys that may be None if not found.
    """
    normalized = unicodedata.normalize('NFKC', text)
    return {
        'unit_name': _extract_name(normalized, UNIT_PATTERNS),
        'concept_name': _extract_name(normalized, CONCEPT_PATTERNS),
        'lesson_name': _extract_name(normalized, LESSON_PATTERNS),
    }


class SequentialContextTracker:
    """
    Tracks the "current" unit, concept, and lesson as we process
    chunks in sequential order (top to bottom of the book).
    
    This is the key to Parent-Child: even though a chunk about
    "Example 3" doesn't mention "Unit 5" directly, we know it
    belongs to Unit 5 because we saw the Unit 5 header earlier.
    
    Works identically regardless of subject or language.
    """
    
    def __init__(self):
        self.current_unit = None
        self.current_concept = None
        self.current_lesson = None
    
    def update_and_tag(self, chunk_role: str, context_names: dict) -> dict:
        """
        Update the tracker state and return the full context for this chunk.
        """
        # Update state when we encounter a new header
        if chunk_role == 'unit_header' and context_names.get('unit_name'):
            self.current_unit = context_names['unit_name']
            self.current_concept = None  # Reset child contexts
            self.current_lesson = None
        
        if chunk_role == 'concept_header' and context_names.get('concept_name'):
            self.current_concept = context_names['concept_name']
            self.current_lesson = None  # Reset child context
        
        if chunk_role == 'lesson_header' and context_names.get('lesson_name'):
            self.current_lesson = context_names['lesson_name']
        
        # Return the full inherited context
        return {
            'parent_unit': self.current_unit,
            'parent_concept': self.current_concept,
            'parent_lesson': self.current_lesson,
            'chunk_role': chunk_role,
        }
