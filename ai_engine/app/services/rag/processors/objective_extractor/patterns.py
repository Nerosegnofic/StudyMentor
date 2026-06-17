"""
Regex patterns for locating and parsing learning-objective sections across
Egyptian primary school textbook formats (Arabic + English, all subjects).
"""
import re

# ===========================================================================
# Shared ordinals (for matching unit/lesson names)
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

# ---------------------------------------------------------------------------
# Section Locators — find where objective sections begin and end
# ---------------------------------------------------------------------------

# Matches: "### المفاهيم" or "المفاهيم" as a standalone header
_MFAHEEM_HEADER = re.compile(
    r'^#{1,6}\s*المفاهيم\s*$', re.MULTILINE
)

# Matches: English objective section headers (comprehensive)
_EN_OBJECTIVES_HEADER = re.compile(
    r'^(?:#{1,4}\s*)?(?:'
    r'Learning\s+(?:Outcomes?|Objectives?|Goals?|Targets?)'
    r'|(?:Lesson|Unit|Chapter)\s+Objectives?'
    r'|Objectives?'
    r'|Key\s+Learning\s+(?:Points?|Goals?)'
    r'|What\s+(?:You|We)\s+Will\s+Learn'
    r'|What\s+(?:You|Students?)\s+(?:Will|Should)\s+(?:Know|Be\s+Able)'
    r'|By\s+the\s+[Ee]nd\s+of\s+(?:this|the)\s+(?:lesson|unit|chapter)'
    r'|In\s+this\s+(?:lesson|unit|chapter)\s+you\s+will'
    r'|Students?\s+will\s+be\s+able\s+to'
    r'|Scope\s+and\s+Sequence'
    r')\s*:?\s*$', re.MULTILINE | re.IGNORECASE
)

# Matches: Self-assessment section headers (end-of-unit skill checklists)
_SELF_ASSESSMENT_HEADER = re.compile(
    r'^(?:#{1,4}\s*)?(?:'
    # English self-assessment
    r'(?:Self[- ]?Assessment|Now\s+I\s+[Cc]an|I\s+[Cc]an\s+now)'
    r'|(?:Review|Quick\s+Review|Unit\s+Review)'
    # Arabic self-assessment
    r'|التقييم\s+الذاتي'
    r'|الآن\s+(?:يمكنني|أستطيع)'
    r'|مراجعة\s*(?:سريعة|الوحدة)?'
    r')\s*:?\s*\.{0,3}\s*$', re.MULTILINE | re.IGNORECASE
)

# Matches: self-assessment skill items ("Now I can..." / "الآن يمكنني...")
_SELF_ASSESSMENT_ITEM = re.compile(
    r'^\s*[-•*]?\s*(?:'
    # English: "Identify vocabulary...", "Use adverbs...", any capitalized verb phrase
    r'(?:Now\s+I\s+can\s+)?(?:Identify|Use|Read|Write|Listen|Speak|Describe|Explain|Compare|Match|Complete|Draw|Label|Name|Apply|Recognize|Understand|Discuss|Ask|Answer|Tell|Say|Practice|Make|Create)\s+.{10,}'
    r'|'
    # Arabic: plain text skill descriptions (no bullet needed)
    r'(?:تحديد|استخدام|قراءة|كتابة|الاستماع|التحدث|وصف|شرح|مقارنة|التعرف|فهم|مناقشة)\s+.{10,}'
    r')$', re.MULTILINE | re.IGNORECASE
)

# Matches: Arabic objective section headers (all publishers, all subjects)
# Uses #{0,6} to handle arbitrary markdown header depth from OCR.
# Includes translated variants that LlamaParse may produce.
_AR_OBJECTIVES_HEADER = re.compile(
    r'^#{0,6}\s*(?:'
    r'(?:أهداف|هدف)\s+(?:التعلم|الدرس|الوحدة)'
    r'|نواتج\s+التعلم'
    r'|نتائج\s+التعلم'               # LlamaParse-translated "Learning Outcomes"
    r'|الأهداف\s*(?:السلوكية|التعليمية|الإجرائية)?'
    r'|مخرجات\s+التعلم'
    r'|ماذا\s+(?:سنتعلم|ستتعلم|نتعلم)'
    r'|ماذا\s+سوف\s+(?:نتعلم|أتعلم)'
    r'|المهارات\s*(?:اللغوية)?'      # "Language Skills" — common in English/Arabic textbooks
    r')\s*[:\?؟]?\s*$', re.MULTILINE
)

# Matches: Arabic inline objective intros (not headers, but inline text)
# e.g., "في هذا الدرس سوف نتعرف على:"
# e.g., "بعد الانتهاء من دراسة هذا المفهوم، أستطيع أن:"
_AR_INLINE_OBJECTIVES_INTRO = re.compile(
    r'(?:'
    r'في\s+(?:هذا|هذه)\s+(?:الدرس|الوحدة|المفهوم)\s+(?:سوف|سنقوم|ستقوم)?\s*(?:نتعرف|ستتعرف|نتعلم|ستتعلم)\s+(?:على|عن)'
    r'|بنهاية\s+(?:هذا|هذه)\s+(?:الدرس|الوحدة|المفهوم)\s+(?:يستطيع|يكون|يتمكن)'
    r'|في\s+نهاية\s+(?:هذا|هذه)\s+(?:الدرس|الوحدة|المفهوم)'
    r'|بعد\s+(?:دراسة|الانتهاء\s+من\s+دراسة|انتهاء)\s+(?:هذا|هذه)\s+(?:الدرس|الوحدة|المفهوم)'
    r'|(?:يتوقع|ينبغي|يجب)\s+(?:أن|من)\s+(?:التلميذ|الطالب)'
    r')\s*[،,:\s]',
    re.MULTILINE
)

# Matches: Arabic vocabulary/key-terms section headers (to STOP extraction)
_AR_VOCABULARY_HEADER = re.compile(
    r'^#{0,6}\s*(?:'
    r'المفردات\s*(?:الأساسية|الجديدة|الرئيسة|الرئيسية)?'
    r'|الكلمات\s*(?:الأساسية|المفتاحية|الجديدة)?'
    r'|المصطلحات\s*(?:الأساسية|العلمية|الجديدة)?'
    r'|Key\s+(?:Vocabulary|Terms|Words)'
    r')\s*:?\s*$', re.MULTILINE
)

# Matches: next major section header (Unit, Concept start, or lesson content start)
_NEXT_SECTION = re.compile(
    r'^#{1,4}\s+(?!المفهوم)', re.MULTILINE  # Any H1-H4 that isn't a concept sub-header
)


# ---------------------------------------------------------------------------
# Unit/Lesson/Concept Header Patterns (for tracking context)
# ---------------------------------------------------------------------------

_UNIT_HEADER = re.compile(
    rf'^#{{1,6}}\s*(?:الوحدة|Unit|Chapter|Module)\s*(?:[\(\[\\\<{{]?\s*\d+\s*[\)\]\\\>}}]?|(?:{_ORDINALS_FEM}))',
    re.MULTILINE | re.IGNORECASE
)

_LESSON_HEADER = re.compile(
    rf'^#{{1,6}}\s*(?:الدرس(?:ان|وس)?|Lesson)\s*(?:[\(\[\\\<{{]?\s*[\d\s،,\-/]+\s*[\)\]\\\>}}]?|(?:{_ORDINALS_MASC}))',
    re.MULTILINE | re.IGNORECASE
)

# Matches: المفهوم (Concept) headers — used in Discovery Education science textbooks
# e.g., "# المفهوم 1.3 التفاعلات بين الغلاف الحيوي والغلاف المائي"
# e.g., "# 2.3 الماء كأهم الموارد الطبيعية على سطح الأرض"
_CONCEPT_HEADER = re.compile(
    r'^#{1,6}\s*(?:'
    r'(?:المفهوم|Concept)\s*(?:[\d\.]+)?\s*(.*?)'
    r'|'
    # Bare numbered concept: "# 1.3 Title" (requires Arabic text after X.Y number)
    r'(\d+\.\d+)\s+([؀-ۿ].+?)'
    r')\s*$',
    re.MULTILINE | re.IGNORECASE
)

# ---------------------------------------------------------------------------
# Arabic Math Objective Patterns (سلاح التلميذ style)
# ---------------------------------------------------------------------------

# Matches lesson header: "- **الدرس (1): title**" or "الدرس (2) و (3): title"
_AR_LESSON_HEADER = re.compile(
    r'-\s*\*{0,2}\s*(?:الدرس(?:ان)?|الدروس)\s*[\(\[\\<\{]?\s*[\d\s،,\-/]+\s*[\)\]\\>\}]?'
    r'\s*(?:و\s*[\(\[\\<\{]?\s*\d+\s*[\)\]\\>\}]?)?\s*:\s*(.+?)(?:\*{0,2})\s*$',
    re.MULTILINE
)

# Matches an Arabic objective: "  - يفعل التلميذ ..." (sub-indented bullet starting with Arabic verb)
_AR_OBJECTIVE = re.compile(
    r'^\s+-\s+((?:ي|يُ|يَ|يّ|يٌ|يً|يِ|يْ)\S+.+)$', re.MULTILINE
)


# ---------------------------------------------------------------------------
# Generic Arabic Objective Bullet Patterns (all publishers, all subjects)
# ---------------------------------------------------------------------------

# Matches all common Arabic objective bullet formats:
#   - أستطيع أن أقرأ...          (Ministry "I can" style)
#   - أن يشرح التلميذ...          ("That the student explains" style)
#   - يتعرف التلميذ على...        ("The student recognizes" style)
#   - يكتب التلميذ...             ("The student writes" style)
#   - التعرف على...               (Masdar/noun style)
#   - فهم العلاقة بين...           (Masdar/noun style)
#   * [ ] أصنّف الأنظمة...         (Checkbox-style, Discovery Education)
#   * [ ] أطوّر نموذجًا...         (Checkbox-style, first-person verb)
#
# Bullet prefix: handles `-`, `•`, `*`, and `* [ ]` checkbox-style bullets.
_AR_GENERIC_OBJECTIVE = re.compile(
    r'^\s*[-•*]\s+(?:\[\s*\]\s*)?('
    # Optional leading conjunction و (OCR sometimes joins "وأستطيع")
    r'(?:و)?'
    # "أستطيع أن" style (Ministry) — with optional tashkeel
    r'أ(?:َ|ْ)?س(?:ْ)?ت(?:َ)?ط(?:ِ)?ي(?:ْ)?ع(?:ُ)?\s+أ(?:َ)?ن(?:ْ)?\s+.+'
    r'|'
    # "أن يفعل التلميذ/الطالب" style (common in science/Arabic language)
    r'(?:و)?أن\s+(?:ي|يُ|يَ|يّ)\S+\s+.+'
    r'|'
    # "يفعل التلميذ" style (Sela7/generic) — verb starts with ي
    r'(?:و)?(?:ي|يُ|يَ|يّ|يٌ|يً|يِ|يْ)\S+\s+(?:التلميذ|الطالب|المتعلم)\s+.+'
    r'|'
    # First-person present tense: "أصنّف", "أطوّر", "أحدد", "أصف", "أقارن"
    # (Discovery Education "I can" without the أستطيع أن prefix)
    # Pattern: أ + consonant (with optional tashkeel/shaddah)
    r'(?:و)?أ[؀-ۿ]\S+\s+.+'
    r'|'
    # Masdar/noun style: "التعرف على", "فهم العلاقة", "تحديد أوجه"
    r'(?:و)?(?:التعرف|التعريف|فهم|تحديد|وصف|مقارنة|تصنيف|استخدام|تطبيق|تحليل|استنتاج|ملاحظة|شرح|كتابة|قراءة|حل|رسم|تمثيل|إيجاد|توضيح|تقدير|تقريب|حساب|إجراء)\s+.+'
    r')$', re.MULTILINE
)


# ---------------------------------------------------------------------------
# English Objective Patterns (all publishers)
# ---------------------------------------------------------------------------

# Skill category headers (used in English textbook "Learning Outcomes" sections)
_EN_SKILL_CATEGORY = re.compile(
    r'^(?:#{1,4}\s*)?(Speaking|Listening|Reading|Writing|Grammar|Vocabulary|Phonics|Spelling|'
    r'التحدث|الاستماع|القراءة|الكتابة|النحو|المفردات)\s*:?\s*$',
    re.MULTILINE | re.IGNORECASE
)

# English objective bullet: "- Verb phrase..." or "• Students will..."
_EN_OBJECTIVE = re.compile(
    r'^\s*[-•*]\s+('
    r'[A-Z][a-z].+'           # Capitalized verb phrase: "Read and answer..."
    r'|Students?\s+will\s+.+' # "Students will be able to..."
    r'|Be\s+able\s+to\s+.+'  # "Be able to identify..."
    r'|(?:Identify|Recognize|Understand|Describe|Explain|Apply|Analyze|Evaluate|Create|Compare|Classify|Demonstrate|Use|Write|Read|Listen|Speak|Match|Complete|Draw|Label|Name|List|Define|State|Discuss|Solve|Calculate|Ask|Answer|Tell|Practice|Make)\s+.+'
    # Arabic verb-phrase bullets (for translated or bilingual sections)
    r'|(?:طرح|الإجابة|استخدام|التعرف|تحديد|وصف|مناقشة|إكمال|كتابة|قراءة|التمييز|التحدث|الاستماع|إعادة)\s+.+'
    r')$', re.MULTILINE | re.IGNORECASE
)