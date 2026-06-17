"""
Arabic objective extraction: Sela7 (سلاح التلميذ) math format and the generic
Ministry / Discovery-Education format (أهداف التعلم / هدف التعلم per lesson).
"""
import re
from typing import List

from .patterns import (
    _ORDINALS_MASC,
    _ORDINALS_FEM,
    _MFAHEEM_HEADER,
    _NEXT_SECTION,
    _AR_LESSON_HEADER,
    _AR_OBJECTIVE,
    _CONCEPT_HEADER,
    _AR_OBJECTIVES_HEADER,
    _AR_GENERIC_OBJECTIVE,
    _AR_VOCABULARY_HEADER,
    _AR_INLINE_OBJECTIVES_INTRO,
)


def _clean_objective_text(text: str) -> str:
    """
    Normalize an extracted objective string:
    - Strip leading conjunction و (OCR artifact from "وأستطيع أن...")
    - Strip trailing period
    - Normalize whitespace
    """
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
        # First-person present tense: "أصنّف", "أطوّر", "أحدد" (Discovery Education)
        r'(?:و)?أ[؀-ۿ]\S+\s+.+'
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

        # Check for concept headers (المفهوم) — used in science textbooks
        concept_match = _CONCEPT_HEADER.match(stripped)
        if concept_match:
            concept_title = concept_match.group(0).lstrip('#').strip()
            current_lesson = concept_title
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

                # Stop at vocabulary/key-terms sections (NOT objectives)
                if _AR_VOCABULARY_HEADER.match(obj_stripped):
                    break

                # Try bullet-prefixed match first (handles - • * and * [ ] checkbox)
                obj_match = _AR_GENERIC_OBJECTIVE.match(obj_line)
                if obj_match:
                    objectives.append(_clean_objective_text(obj_match.group(1)))
                # Then try bare-line match (no bullet prefix)
                elif _AR_BARE_OBJECTIVE.match(obj_line):
                    bare_match = _AR_BARE_OBJECTIVE.match(obj_line)
                    objectives.append(_clean_objective_text(bare_match.group(1)))
                elif obj_stripped == '':
                    continue
                # Skip intro lines like "بعد الانتهاء من دراسة هذا المفهوم، أستطيع أن:"
                elif _AR_INLINE_OBJECTIVES_INTRO.search(obj_stripped):
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
                elif _AR_VOCABULARY_HEADER.match(obj_stripped):
                    break
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