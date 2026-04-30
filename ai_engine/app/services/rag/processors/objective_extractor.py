"""
Objective Extractor for Egyptian Primary School Textbooks.

Extracts learning objectives from the parsed markdown output using
regex pattern matching on known section structures.

Supports three textbook formats:
  1. Arabic Math (سلاح التلميذ): المفاهيم sections with lesson-grouped objectives
  2. English (المعاصر Connect): Learning Outcomes sections grouped by skill
  3. Ministry Techbook (Discovery Education): هدف التعلم / أهداف التعلم per-lesson

The extractor works on the CLEAN markdown.

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
    r'^#{1,4}\s*المفاهيم\s*$', re.MULTILINE
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
    r')\s*:?\s*$', re.MULTILINE | re.IGNORECASE
)

# Matches: Arabic objective section headers (all publishers, all subjects)
_AR_OBJECTIVES_HEADER = re.compile(
    r'^#{0,4}\s*(?:'
    r'(?:أهداف|هدف)\s+(?:التعلم|الدرس|الوحدة)'
    r'|نواتج\s+التعلم'
    r'|الأهداف\s*(?:السلوكية|التعليمية|الإجرائية)?'
    r'|مخرجات\s+التعلم'
    r'|ماذا\s+(?:سنتعلم|ستتعلم|نتعلم)'
    r'|ماذا\s+سوف\s+(?:نتعلم|أتعلم)'
    r')\s*[:\?؟]?\s*$', re.MULTILINE
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
    r'^#{1,3}\s+(?!المفهوم)', re.MULTILINE  # Any H1-H3 that isn't a concept sub-header
)


# ---------------------------------------------------------------------------
# Unit/Lesson Header Patterns (for tracking context)
# ---------------------------------------------------------------------------

_UNIT_HEADER = re.compile(
    rf'^#{{1,4}}\s*(?:الوحدة)\s*(?:[\(\[<{{]?\s*\d+\s*[\)\]>}}]?|(?:{_ORDINALS_FEM}))',
    re.MULTILINE
)

_LESSON_HEADER = re.compile(
    rf'^#{{1,4}}\s*(?:الدرس(?:ان|وس)?)\s*(?:[\(\[<{{]?\s*[\d\s،,\-/]+\s*[\)\]>}}]?|(?:{_ORDINALS_MASC}))',
    re.MULTILINE
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
    # "أستطيع أن" style (Ministry) — with optional tashkeel
    r'أ(?:َ|ْ)?س(?:ْ)?ت(?:َ)?ط(?:ِ)?ي(?:ْ)?ع(?:ُ)?\s+أ(?:َ)?ن(?:ْ)?\s+.+'
    r'|'
    # "أن يفعل التلميذ/الطالب" style (common in science/Arabic language)
    r'أن\s+(?:ي|يُ|يَ|يّ)\S+\s+.+'
    r'|'
    # "يفعل التلميذ" style (Sela7/generic) — verb starts with ي
    r'(?:ي|يُ|يَ|يّ|يٌ|يً|يِ|يْ)\S+\s+(?:التلميذ|الطالب|المتعلم)\s+.+'
    r'|'
    # Masdar/noun style: "التعرف على", "فهم العلاقة", "تحديد أوجه"
    r'(?:التعرف|التعريف|فهم|تحديد|وصف|مقارنة|تصنيف|استخدام|تطبيق|تحليل|استنتاج|ملاحظة|شرح|كتابة|قراءة|حل|رسم|تمثيل|إيجاد|توضيح)\s+.+'
    r')$', re.MULTILINE
)


# ---------------------------------------------------------------------------
# English Objective Patterns (all publishers)
# ---------------------------------------------------------------------------

# Skill category headers
_EN_SKILL_CATEGORY = re.compile(
    r'^(Speaking|Listening|Reading|Writing|Grammar|Vocabulary|Phonics|Spelling)\s*$',
    re.MULTILINE | re.IGNORECASE
)

# English objective bullet: "- Verb phrase..." or "• Students will..."
_EN_OBJECTIVE = re.compile(
    r'^\s*[-•*]\s+('
    r'[A-Z][a-z].+'           # Capitalized verb phrase: "Read and answer..."
    r'|Students?\s+will\s+.+' # "Students will be able to..."
    r'|Be\s+able\s+to\s+.+'  # "Be able to identify..."
    r'|(?:Identify|Recognize|Understand|Describe|Explain|Apply|Analyze|Evaluate|Create|Compare|Classify|Demonstrate|Use|Write|Read|Listen|Speak|Match|Complete|Draw|Label|Name|List|Define|State|Discuss|Solve|Calculate)\s+.+'
    r')$', re.MULTILINE | re.IGNORECASE
)


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
                objective = obj_match.group(1).strip()
                objective = objective.rstrip('.')
                current_objectives.append(objective)
        
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
    
    Structure:
        # الدرس الأول
        ## الكسور العشرية حتى جزء من الألف
        ### أهداف التعلم
        - أستطيع أن أقرأ الأعداد العشرية حتى جزء من الألف.
        - أستطيع أن أكتب الأعداد العشرية حتى جزء من الألف.
    
    Returns: [{'unit': ..., 'lesson': ..., 'objectives': [...]}]
    """
    results = []
    
    # Track current unit and lesson as we scan the document
    current_unit = "Unknown"
    current_lesson = "Unknown"
    
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
            # Try to get title after colon
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
            # Try to get title from the next header line (h2)
            rest = stripped[stripped.index(current_lesson) + len(current_lesson):]
            title_match = re.match(r'\s*[:\|]\s*(.+?)$', rest)
            if title_match:
                current_lesson = f"{current_lesson}: {title_match.group(1).strip()}"
            else:
                # Check if h2 on next non-empty line has the title
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
            # Collect all objectives following this header
            objectives = []
            for j in range(i + 1, len(lines)):
                obj_line = lines[j]
                obj_match = _AR_GENERIC_OBJECTIVE.match(obj_line)
                if obj_match:
                    obj_text = obj_match.group(1).strip().rstrip('.')
                    objectives.append(obj_text)
                elif obj_line.strip() == '':
                    continue  # Skip blank lines
                elif obj_line.strip().startswith('#') or obj_line.strip().startswith('---'):
                    break  # Next section
                else:
                    break  # Non-objective content
            
            if objectives:
                results.append({
                    'unit': current_unit,
                    'lesson': current_lesson,
                    'objectives': objectives,
                })
            continue
        
        # Check for inline objective intros (e.g., "في هذا الدرس سوف نتعرف على:")
        if _AR_INLINE_OBJECTIVES_INTRO.search(stripped):
            objectives = []
            for j in range(i + 1, len(lines)):
                obj_line = lines[j]
                obj_match = _AR_GENERIC_OBJECTIVE.match(obj_line)
                if obj_match:
                    obj_text = obj_match.group(1).strip().rstrip('.')
                    objectives.append(obj_text)
                elif obj_line.strip() == '':
                    continue
                elif obj_line.strip().startswith('#') or obj_line.strip().startswith('---'):
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
    
    Structure:
        Learning Outcomes
        Speaking
        - Ask and answer questions about ...
        Reading
        - Answer comprehension questions ...
    
    Returns: [{'unit': 'General', 'lesson': skill, 'objectives': [...]}]
    """
    results = []
    
    for match in _EN_OBJECTIVES_HEADER.finditer(text):
        start = match.end()
        current_skill = "General"
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
            
            # Stop if we hit lesson/unit content
            if re.match(r'^(Lesson|UNIT|#)', stripped, re.IGNORECASE):
                break
            if stripped.startswith('|'):
                break
            
            # Check for skill category
            skill_match = _EN_SKILL_CATEGORY.match(stripped)
            if skill_match:
                # Save previous skill
                if current_objectives:
                    results.append({
                        'unit': 'General',
                        'lesson': current_skill,
                        'objectives': current_objectives,
                    })
                current_skill = skill_match.group(1).strip()
                current_objectives = []
                continue
            
            # Check for English objective bullet
            obj_match = _EN_OBJECTIVE.match(line)
            if obj_match:
                current_objectives.append(obj_match.group(1).strip())
        
        # Save the last skill group
        if current_objectives:
            results.append({
                'unit': 'General',
                'lesson': current_skill,
                'objectives': current_objectives,
            })
    
    return results


def extract_all_objectives(text: str) -> List[dict]:
    """
    Extract all learning objectives from a textbook markdown.
    Automatically detects the textbook format and extracts accordingly.
    Deduplicates objectives by (unit, lesson, objective_text).
    
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
    
    # Try generic Arabic extraction (أهداف التعلم, نواتج التعلم, etc.)
    generic_ar = extract_ministry_objectives(text)
    all_objectives.extend(generic_ar)
    
    # Try English extraction
    english = extract_english_objectives(text)
    all_objectives.extend(english)
    
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
