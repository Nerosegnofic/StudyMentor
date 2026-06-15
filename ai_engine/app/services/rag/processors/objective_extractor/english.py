"""
English objective extraction: "Learning Outcomes" sections (grouped by skill
strand) and end-of-unit self-assessment / "Now I can..." checklists.
"""
import re
from typing import List

from .patterns import (
    _EN_OBJECTIVES_HEADER,
    _EN_SKILL_CATEGORY,
    _EN_OBJECTIVE,
    _SELF_ASSESSMENT_HEADER,
    _SELF_ASSESSMENT_ITEM,
)


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