"""
Content-detection regex patterns for Egyptian primary school textbooks
(Arabic + English, all subjects).

We do NOT trust markdown header depth (#, ##, ###) because LlamaParse often swaps
them randomly. Instead we detect a chunk's role by scanning its CONTENT for these
known pedagogical patterns.
"""
import re

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