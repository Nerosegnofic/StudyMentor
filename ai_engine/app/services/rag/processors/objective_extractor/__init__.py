"""
Objective Extractor for Egyptian Primary School Textbooks.

Extracts learning objectives from the parsed markdown using regex pattern matching
on known section structures. Language-neutral: Arabic-only, English-only, and
bilingual textbooks.

Supported formats (per submodule):
  - arabic:  Sela7 (المفاهيم) math + Ministry/Discovery (أهداف التعلم)
  - english: "Learning Outcomes" strands + self-assessment ("Now I can...")

Returns structured data: list of dicts with 'unit', 'lesson', 'objectives'.
"""
from typing import List

from .arabic import extract_arabic_objectives, extract_ministry_objectives
from .english import extract_english_objectives, extract_self_assessment_objectives

# Re-exported for pattern-validation scripts/tests.
from .patterns import (  # noqa: F401
    _AR_OBJECTIVES_HEADER,
    _AR_INLINE_OBJECTIVES_INTRO,
    _AR_GENERIC_OBJECTIVE,
    _EN_OBJECTIVES_HEADER,
    _EN_OBJECTIVE,
)


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
    all_objectives.extend(extract_arabic_objectives(text))

    # Try generic Arabic extraction (أهداف التعلم, نواتج التعلم, نتائج التعلم, etc.)
    all_objectives.extend(extract_ministry_objectives(text))

    # Try English extraction (Learning Outcomes, Objectives, etc.)
    all_objectives.extend(extract_english_objectives(text))

    # Try self-assessment extraction ("Now I can...", "التقييم الذاتي", etc.)
    all_objectives.extend(extract_self_assessment_objectives(text))

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


__all__ = [
    "extract_all_objectives",
    "extract_arabic_objectives",
    "extract_ministry_objectives",
    "extract_english_objectives",
    "extract_self_assessment_objectives",
    "_AR_OBJECTIVES_HEADER",
    "_AR_INLINE_OBJECTIVES_INTRO",
    "_AR_GENERIC_OBJECTIVE",
    "_EN_OBJECTIVES_HEADER",
    "_EN_OBJECTIVE",
]