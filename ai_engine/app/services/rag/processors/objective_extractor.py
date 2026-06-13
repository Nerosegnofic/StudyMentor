"""
Objective Extractor for Egyptian Primary School Textbooks.

Extracts learning objectives from the parsed markdown output using
regex pattern matching on known section structures.

Supports multiple textbook formats across ALL subjects:
  1. Arabic Math (سلاح التلميذ): المفاهيم sections with lesson-grouped objectives
  2. English (المعاصر Connect / Ministry Connect): Learning Outcomes sections
  3. Ministry Techbook (Discovery Education): هدف التعلم / أهداف التعلم per-lesson
  4. Self-Assessment sections: "Now I can..." / "الآن يمكنني..." skill lists
  5. Science / Social Studies / Arabic Language: أهداف التعلم, نتائج التعلم

Language-neutral: works with Arabic-only, English-only, and bilingual textbooks.

Returns structured data: list of dicts with 'unit', 'lesson', 'objectives'.
"""
import re
from typing import Dict, List, Tuple


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
# Also matches **bold** format (LlamaParse sometimes renders headers as bold text).
# Includes translated variants that LlamaParse may produce.
_AR_OBJECTIVES_HEADER = re.compile(
    r'^#{0,6}\s*\*{0,2}\s*(?:'
    r'(?:أهداف|هدف)\s+(?:التعلم|الدرس|الوحدة)'
    r'|نواتج\s+التعلم'
    r'|نتائج\s+التعلم'               # LlamaParse-translated "Learning Outcomes"
    r'|الأهداف\s*(?:السلوكية|التعليمية|الإجرائية)?'
    r'|مخرجات\s+التعلم'
    r'|ماذا\s+(?:سنتعلم|ستتعلم|نتعلم)'
    r'|ماذا\s+سوف\s+(?:نتعلم|أتعلم)'
    r'|المهارات\s*(?:اللغوية)?'      # "Language Skills" — common in English/Arabic textbooks
    r')\s*\*{0,2}\s*[:\?؟]?\s*$', re.MULTILINE
)

# Matches: Arabic inline objective intros (not headers, but inline text)
# e.g., "في هذا الدرس سوف نتعرف على:"
_AR_INLINE_OBJECTIVES_INTRO = re.compile(
    r'(?:'
    r'في\s+(?:هذا|هذه)\s+(?:الدرس|الوحدة)\s+(?:سوف|سنقوم|ستقوم)?\s*(?:نتعرف|ستتعرف|نتعلم|ستتعلم)\s+(?:على|عن)'
    r'|بنهاية\s+(?:هذا|هذه)\s+(?:الدرس|الوحدة)\s+(?:يستطيع|يكون|يتمكن)'
    r'|في\s+نهاية\s+(?:هذا|هذه)\s+(?:الدرس|الوحدة)'
    r'|بعد\s+(?:دراسة|انتهاء)\s+(?:هذا|هذه)\s+(?:الدرس|الوحدة)'
    r'|(?:يتوقع|ينبغي|يجب)\s+(?:أن|من)\s+(?:التلميذ|الطالب)'
    r')\s*[:\s]',
    re.MULTILINE
)

# Matches: next major section header (Unit, Concept start, or lesson content start)
_NEXT_SECTION = re.compile(
    r'^#{1,4}\s+(?!المفهوم)', re.MULTILINE  # Any H1-H4 that isn't a concept sub-header
)


# ---------------------------------------------------------------------------
# Unit/Lesson Header Patterns (for tracking context)
# ---------------------------------------------------------------------------

_UNIT_HEADER = re.compile(
    rf'^#{{1,6}}\s*(?:الوحدة|Unit|Chapter|Module)\s*(?:[\(\[\<{{]?\s*\d+\s*[\)\]\>}}]?|(?:{_ORDINALS_FEM}))',
    re.MULTILINE | re.IGNORECASE
)

_LESSON_HEADER = re.compile(
    rf'^#{{1,6}}\s*(?:الدرس(?:ان|وس)?|Lesson)\s*(?:[\(\[\<{{]?\s*[\d\s،,\-/]+\s*[\)\]\>}}]?|(?:{_ORDINALS_MASC}))',
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
_AR_GENERIC_OBJECTIVE = re.compile(
    r'^\s*[-•*]\s+('
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


def _clean_objective_text(text: str) -> str:
    """
    Normalize an extracted objective string:
    - Strip <mark>...</mark> tags (LlamaParse highlight artifacts)
    - Strip leading conjunction و (OCR artifact from "وأستطيع أن...")
    - Strip trailing period
    - Normalize whitespace
    """
    text = re.sub(r'</?mark>', '', text)
    text = text.strip().rstrip('.')
    # Strip leading و if followed by أستطيع/أن (conjunction artifact)
    if text.startswith('و') and len(text) > 1 and text[1] in 'أا':
        text = text[1:]
    return ' '.join(text.split())


def _find_sections(text: str, header_pattern: re.Pattern) -> List[str]:
    """
    Find all sections that start with the given header pattern.
    Returns the text of each section (from header to next major section).
    """
    sections = []
    for match in header_pattern.finditer(text):
        start = match.start()
        # Find the end: next major section header or end of text
        next_section = _NEXT_SECTION.search(text, match.end() + 1)
        end = next_section.start() if next_section else len(text)
        sections.append(text[start:end])
    return sections


def _extract_line_title(line: str, keyword_pattern: re.Pattern) -> str:
    """Extract a full title from a line containing a keyword pattern."""
    match = keyword_pattern.search(line)
    if match:
        full = match.group(0).strip()
        # Try to grab colon-separated title
        rest = line[match.end():]
        title_match = re.match(r'\s*[:\|]\s*(.+?)(?:\*{0,2})\s*$', rest)
        if title_match:
            return f"{full}: {title_match.group(1).strip()}"
        return full
    return None


def extract_arabic_objectives(text: str) -> List[dict]:
    """
    Extract objectives from Arabic Math textbook format (سلاح التلميذ).
    
    Structure:
        ### المفاهيم
        #### المفهوم الأول: ...
        - **الدرس (1): title**
          - يكتب التلميذ ...
          - يقرأ التلميذ ...
    
    Returns: [{'unit': ..., 'lesson': ..., 'objectives': [...]}]
    """
    results = []
    sections = _find_sections(text, _MFAHEEM_HEADER)
    
    # Try to determine the current unit from context before the المفاهيم section
    for section_text in sections:
        # Find the position of this section in the full text
        section_start = text.find(section_text)
        
        # Look backward for the nearest unit header
        current_unit = "Unknown"
        preceding_text = text[:section_start] if section_start > 0 else ""
        unit_matches = list(re.finditer(
            rf'(?:الوحدة)\s*(?:[\(\[<{{]?\s*\d+\s*[\)\]>}}]?|(?:{_ORDINALS_FEM}))',
            preceding_text
        ))
        if unit_matches:
            last_unit = unit_matches[-1]
            current_unit = last_unit.group(0).strip()
            # Try to get unit title after colon
            rest = preceding_text[last_unit.end():]
            title_match = re.match(r'\s*[:\|]\s*(.+?)(?:\n|$)', rest)
            if title_match:
                current_unit = f"{current_unit}: {title_match.group(1).strip()}"
        
        current_lesson = None
        current_objectives = []
        
        for line in section_text.split('\n'):
            # Check if this is a lesson header
            lesson_match = _AR_LESSON_HEADER.match(line.strip() if not line.startswith(' ') else line)
            if not lesson_match:
                lesson_match = _AR_LESSON_HEADER.search(line)
            
            if lesson_match:
                # Save previous lesson if it had objectives
                if current_lesson and current_objectives:
                    results.append({
                        'unit': current_unit,
                        'lesson': current_lesson,
                        'objectives': current_objectives,
                    })
                current_lesson = lesson_match.group(0).strip().strip('-').strip().strip('*').strip()
                current_objectives = []
                continue
            
            # Check if this is an objective (sub-indented Arabic verb bullet)
            obj_match = _AR_OBJECTIVE.match(line)
            if obj_match and current_lesson:
                current_objectives.append(_clean_objective_text(obj_match.group(1)))
        
        # Don't forget the last lesson
        if current_lesson and current_objectives:
            results.append({
                'unit': current_unit,
                'lesson': current_lesson,
                'objectives': current_objectives,
            })
    
    return results


def extract_ministry_objectives(text: str) -> List[dict]:
    """
    Extract objectives from Ministry Techbook format (Discovery Education).
    
    Structure (bullet form):
        # الدرس الأول
        ## الكسور العشرية حتى جزء من الألف
        ### أهداف التعلم
        - أستطيع أن أقرأ الأعداد العشرية حتى جزء من الألف.
        - أستطيع أن أكتب الأعداد العشرية حتى جزء من الألف.
    
    Structure (bare-line form — common in scanned copies):
        ##### هدف التعلم
        أستطيع أن أقرب الأعداد العشرية إلى أقرب جزء من عشرة.
    
    Returns: [{'unit': ..., 'lesson': ..., 'objectives': [...]}]
    """
    results = []
    
    # Track current unit and lesson as we scan the document
    current_unit = "Unknown"
    current_lesson = "Unknown"
    
    # Pattern to match bare-line objectives (no bullet prefix)
    # Handles optional leading و (conjunction) which OCR commonly produces
    _AR_BARE_OBJECTIVE = re.compile(
        r'^\s*('
        # Optional leading و + "أستطيع أن" style
        r'(?:و)?أ(?:َ|ْ)?س(?:ْ)?ت(?:َ)?ط(?:ِ)?ي(?:ْ)?ع(?:ُ)?\s+أ(?:َ)?ن(?:ْ)?\s+.+'
        r'|'
        # "أن يفعل" style
        r'(?:و)?أن\s+(?:ي|يُ|يَ|يّ)\S+\s+.+'
        r'|'
        # "يفعل التلميذ" style
        r'(?:و)?(?:ي|يُ|يَ|يّ|يٌ|يً|يِ|يْ)\S+\s+(?:التلميذ|الطالب|المتعلم)\s+.+'
        r'|'
        # Masdar/noun style: "التعرف على", "تقدير الفرق"
        r'(?:و)?(?:التعرف|التعريف|فهم|تحديد|وصف|مقارنة|تصنيف|استخدام|تطبيق|تحليل|استنتاج|ملاحظة|شرح|كتابة|قراءة|حل|رسم|تمثيل|إيجاد|توضيح|تقدير|تقريب|حساب|إجراء)\s+.+'
        r')$', re.MULTILINE
    )
    
    lines = text.split('\n')
    
    for i, line in enumerate(lines):
        stripped = line.strip()
        
        # Check for unit headers
        unit_match = re.search(
            rf'الوحدة\s*(?:[\(\[<{{]?\s*\d+\s*[\)\]>}}]?|(?:{_ORDINALS_FEM}))',
            stripped
        )
        if unit_match and stripped.startswith('#'):
            current_unit = unit_match.group(0).strip()
            rest = stripped[stripped.index(current_unit) + len(current_unit):]
            title_match = re.match(r'\s*[:\|]\s*(.+?)$', rest)
            if title_match:
                current_unit = f"{current_unit}: {title_match.group(1).strip()}"
            continue
        
        # Check for lesson headers (ordinal or numeric)
        lesson_match = re.search(
            rf'(?:الدرس(?:ان|وس)?)\s*(?:[\(\[<{{]?\s*[\d\s،,\-/]+\s*[\)\]>}}]?|(?:{_ORDINALS_MASC}))',
            stripped
        )
        if lesson_match and stripped.startswith('#'):
            current_lesson = lesson_match.group(0).strip()
            rest = stripped[stripped.index(current_lesson) + len(current_lesson):]
            title_match = re.match(r'\s*[:\|]\s*(.+?)$', rest)
            if title_match:
                current_lesson = f"{current_lesson}: {title_match.group(1).strip()}"
            else:
                for j in range(i + 1, min(i + 3, len(lines))):
                    next_line = lines[j].strip()
                    if next_line.startswith('##') and not next_line.startswith('###'):
                        title = next_line.lstrip('#').strip()
                        if title and not any(kw in title for kw in ['هدف', 'أهداف', 'استكشف', 'تعلم']):
                            current_lesson = f"{current_lesson}: {title}"
                        break
            continue
        
        # Check for objectives header (all Arabic formats)
        if _AR_OBJECTIVES_HEADER.match(stripped):
            objectives = []
            for j in range(i + 1, len(lines)):
                obj_line = lines[j]
                obj_stripped = obj_line.strip()
                # Try bullet-prefixed match first
                obj_match = _AR_GENERIC_OBJECTIVE.match(obj_line)
                if obj_match:
                    objectives.append(_clean_objective_text(obj_match.group(1)))
                # Then try bare-line match (no bullet prefix)
                elif _AR_BARE_OBJECTIVE.match(obj_line):
                    bare_match = _AR_BARE_OBJECTIVE.match(obj_line)
                    objectives.append(_clean_objective_text(bare_match.group(1)))
                elif obj_stripped == '':
                    continue
                elif obj_stripped.startswith('#') or obj_stripped.startswith('---'):
                    break
                else:
                    break
            
            if objectives:
                results.append({
                    'unit': current_unit,
                    'lesson': current_lesson,
                    'objectives': objectives,
                })
            continue
        
        # Check for inline objective intros
        if _AR_INLINE_OBJECTIVES_INTRO.search(stripped):
            objectives = []
            for j in range(i + 1, len(lines)):
                obj_line = lines[j]
                obj_stripped = obj_line.strip()
                obj_match = _AR_GENERIC_OBJECTIVE.match(obj_line)
                if obj_match:
                    objectives.append(_clean_objective_text(obj_match.group(1)))
                elif _AR_BARE_OBJECTIVE.match(obj_line):
                    bare_match = _AR_BARE_OBJECTIVE.match(obj_line)
                    objectives.append(_clean_objective_text(bare_match.group(1)))
                elif obj_stripped == '':
                    continue
                elif obj_stripped.startswith('#') or obj_stripped.startswith('---'):
                    break
                else:
                    break
            
            if objectives:
                results.append({
                    'unit': current_unit,
                    'lesson': current_lesson,
                    'objectives': objectives,
                })
    
    return results


def extract_english_objectives(text: str) -> List[dict]:
    """
    Extract objectives from English textbook format.
    
    Supports:
        1. "Learning Outcomes" sections with skill categories (Speaking, Reading, etc.)
        2. Generic objective headers ("By the end of this lesson...")
        3. Bilingual sections where headers are Arabic but bullets are English/Arabic
    
    Tracks the current unit/lesson context so objectives are properly grouped.
    
    Returns: [{'unit': ..., 'lesson': ..., 'objectives': [...]}]
    """
    results = []
    
    # Track current unit/lesson context across the document
    current_unit = "General"
    current_lesson = "General"
    
    # Pre-scan for unit/lesson headers to build context
    lines = text.split('\n')
    unit_lesson_context = {}  # line_index -> (unit, lesson)
    for i, line in enumerate(lines):
        stripped = line.strip()
        # English/bilingual unit header
        unit_match = re.search(
            r'(?:Unit|الوحدة)\s*(?:[\(\[<{]?\s*\d+\s*[\)\]>}]?)',
            stripped, re.IGNORECASE
        )
        if unit_match and stripped.startswith('#'):
            current_unit = stripped.lstrip('#').strip()
            # Try to get the full title after colon
            title_match = re.match(r'.+?(?::|:)\s*(.+)$', current_unit)
            if title_match:
                current_unit = current_unit  # Keep full title
        
        lesson_match = re.search(
            r'(?:Lesson|الدرس)\s*(?:[\(\[<{]?\s*\d+\s*[\)\]>}]?)',
            stripped, re.IGNORECASE
        )
        if lesson_match and (stripped.startswith('#') or stripped.startswith('**')):
            current_lesson = stripped.lstrip('#').strip().strip('*').strip()
        
        unit_lesson_context[i] = (current_unit, current_lesson)
    
    # Reset for extraction pass
    for match in _EN_OBJECTIVES_HEADER.finditer(text):
        # Find which line this header is on
        header_pos = match.start()
        header_line_idx = text[:header_pos].count('\n')
        
        # Get the unit/lesson context at this position
        ctx = unit_lesson_context.get(header_line_idx, ("General", "General"))
        section_unit, section_lesson = ctx
        
        start = match.end()
        current_skill = section_lesson if section_lesson != "General" else "General"
        blank_count = 0
        current_objectives = []
        
        for line in text[start:].split('\n'):
            stripped = line.strip()
            
            # Stop conditions: we've left the outcomes section
            if not stripped:
                blank_count += 1
                if blank_count >= 3:
                    break
                continue
            else:
                blank_count = 0
            
            # Stop if we hit a new major section
            if re.match(r'^#{1,3}\s+(?!#)', stripped):
                # But not if it's a skill category header like ### Speaking
                if not _EN_SKILL_CATEGORY.match(stripped):
                    break
            if stripped.startswith('|'):
                break
            
            # Check for skill category
            skill_match = _EN_SKILL_CATEGORY.match(stripped)
            if skill_match:
                # Save previous skill
                if current_objectives:
                    results.append({
                        'unit': section_unit,
                        'lesson': current_skill,
                        'objectives': current_objectives,
                    })
                current_skill = skill_match.group(1).strip()
                current_objectives = []
                continue
            
            # Check for English/bilingual objective bullet
            obj_match = _EN_OBJECTIVE.match(line)
            if obj_match:
                current_objectives.append(obj_match.group(1).strip())
        
        # Save the last skill group
        if current_objectives:
            results.append({
                'unit': section_unit,
                'lesson': current_skill,
                'objectives': current_objectives,
            })
    
    return results


def extract_self_assessment_objectives(text: str) -> List[dict]:
    """
    Extract skill objectives from self-assessment / review sections.
    
    Many Egyptian textbooks (especially English subject) list skills at the
    end of each unit as self-assessment checklists:
        ## التقييم الذاتي / Self-Assessment
        الآن يمكنني ... / Now I can ...
        - Identify vocabulary related to Nile River life.
        - Use adverbs of frequency.
        - تحديد المفردات المتعلقة بالحياة في نهر النيل.
    
    These are often the ONLY explicit skill declarations in English textbooks.
    
    Returns: [{'unit': ..., 'lesson': 'Self-Assessment', 'objectives': [...]}]
    """
    results = []
    
    # Track current unit context
    current_unit = "General"
    
    lines = text.split('\n')
    for i, line in enumerate(lines):
        stripped = line.strip()
        
        # Track unit headers
        unit_match = re.search(
            r'(?:Unit|الوحدة)\s*(?:[\(\[<{]?\s*\d+\s*[\)\]>}]?)',
            stripped, re.IGNORECASE
        )
        if unit_match and stripped.startswith('#'):
            current_unit = stripped.lstrip('#').strip()
        
        # Check for self-assessment header
        if _SELF_ASSESSMENT_HEADER.match(stripped):
            objectives = []
            
            for j in range(i + 1, min(i + 40, len(lines))):
                obj_line = lines[j].strip()
                
                # Stop at next major section
                if obj_line.startswith('#') and not _SELF_ASSESSMENT_HEADER.match(obj_line):
                    break
                if obj_line.startswith('---'):
                    break
                
                # Skip empty lines and noise
                if not obj_line or obj_line in ('نعم', 'لا', 'Yes', 'No'):
                    continue
                # Skip checklist markers
                if re.match(r'^[-•*]?\s*(?:حصلت عليه|لست متأكد|أحتاج مساعد|Got it|Not sure|Need help)', obj_line, re.IGNORECASE):
                    continue
                # Skip star ratings
                if re.match(r'^[✰★☆⭐\s]+$', obj_line):
                    continue
                
                # Match self-assessment items
                item_match = _SELF_ASSESSMENT_ITEM.match(obj_line)
                if item_match:
                    obj_text = obj_line.lstrip('-•* ').strip()
                    # Clean "Now I can" prefix
                    obj_text = re.sub(r'^(?:Now\s+I\s+can|الآن\s+(?:يمكنني|أستطيع))\s*\.{0,3}\s*', '', obj_text, flags=re.IGNORECASE).strip()
                    if len(obj_text) > 10:  # Skip too-short fragments
                        objectives.append(obj_text)
            
            if objectives:
                results.append({
                    'unit': current_unit,
                    'lesson': 'Self-Assessment',
                    'objectives': objectives,
                })
    
    return results


def extract_all_objectives(text: str) -> List[dict]:
    """
    Extract all learning objectives from a textbook markdown.
    Automatically detects the textbook format and extracts accordingly.
    Deduplicates objectives by (unit, lesson, objective_text).
    
    Supports ALL subjects: Math, English, Arabic Language, Science,
    Social Studies, and any other Egyptian primary school subject.
    
    Returns a list of dicts, each with:
        {
            'unit': str,      # Unit name (e.g., "الوحدة (1): القيمة المكانية")
            'lesson': str,    # Lesson name (e.g., "الدرس (1): الكسور العشرية")
            'objectives': [str, ...]  # List of objective texts
        }
    """
    all_objectives = []
    
    # Try Arabic Sela7 extraction (المفاهيم sections)
    arabic = extract_arabic_objectives(text)
    all_objectives.extend(arabic)
    
    # Try generic Arabic extraction (أهداف التعلم, نواتج التعلم, نتائج التعلم, etc.)
    generic_ar = extract_ministry_objectives(text)
    all_objectives.extend(generic_ar)
    
    # Try English extraction (Learning Outcomes, Objectives, etc.)
    english = extract_english_objectives(text)
    all_objectives.extend(english)
    
    # Try self-assessment extraction ("Now I can...", "التقييم الذاتي", etc.)
    self_assess = extract_self_assessment_objectives(text)
    all_objectives.extend(self_assess)
    
    # Deduplicate: merge groups with same (unit, lesson) and remove duplicate texts
    seen_keys = {}  # (unit, lesson) -> list of unique objectives
    for entry in all_objectives:
        key = (entry.get('unit', 'Unknown'), entry.get('lesson', 'Unknown'))
        if key not in seen_keys:
            seen_keys[key] = []
        for obj in entry.get('objectives', []):
            # Normalize whitespace for comparison
            normalized_obj = ' '.join(obj.split())
            if normalized_obj not in seen_keys[key]:
                seen_keys[key].append(normalized_obj)
    
    # Rebuild the deduplicated list
    deduped = []
    for (unit, lesson), objectives in seen_keys.items():
        if objectives:
            deduped.append({
                'unit': unit,
                'lesson': lesson,
                'objectives': objectives,
            })
    
    total_before = sum(len(entry['objectives']) for entry in all_objectives)
    total_after = sum(len(entry['objectives']) for entry in deduped)
    removed = total_before - total_after
    
    print(f"[ObjectiveExtractor] Extracted {total_after} objectives across {len(deduped)} groups"
          f"{f' (removed {removed} duplicates)' if removed > 0 else ''}.", flush=True)
    
    return deduped
