"""
Objective Extractor for Egyptian Primary School Textbooks.

Extracts learning objectives from the parsed markdown output using
regex pattern matching on known section structures.

Supports two textbook formats:
  1. Arabic Math (سلاح التلميذ): المفاهيم sections with lesson-grouped objectives
  2. English (المعاصر Connect): Learning Outcomes sections grouped by skill

The extractor works on the CLEAN markdown (no [OBJ] tags needed).
"""
import re
from typing import Dict, List


# ---------------------------------------------------------------------------
# Section Locators — find where objective sections begin and end
# ---------------------------------------------------------------------------

# Matches: "### المفاهيم" or "المفاهيم" as a standalone header
_MFAHEEM_HEADER = re.compile(
    r'^#{1,4}\s*المفاهيم\s*$', re.MULTILINE
)

# Matches: "Learning Outcomes" or "Learning outcomes"
_LEARNING_OUTCOMES_HEADER = re.compile(
    r'^(?:#{1,4}\s*)?Learning\s+[Oo]utcomes?\s*$', re.MULTILINE
)

# Matches: next major section header (Unit, Concept start, or lesson content start)
_NEXT_SECTION = re.compile(
    r'^#{1,3}\s+(?!المفهوم)', re.MULTILINE  # Any H1-H3 that isn't a concept sub-header
)


# ---------------------------------------------------------------------------
# Arabic Math Objective Patterns (سلاح التلميذ style)
# ---------------------------------------------------------------------------

# Matches lesson header: "- **الدرس (1): title**" or "الدرس (2) و (3): title"
_AR_LESSON_HEADER = re.compile(
    r'-\s*\*{0,2}\s*(?:الدرس(?:ان)?|الدروس)\s*[\(\[\<\{]?\s*[\d\s،,\-/]+\s*[\)\]\>\}]?\s*(?:و\s*[\(\[\<\{]?\s*\d+\s*[\)\]\>\}]?)?\s*:\s*(.+?)(?:\*{0,2})\s*$',
    re.MULTILINE
)

# Matches an Arabic objective: "  - يفعل التلميذ ..." (sub-indented bullet starting with Arabic verb)
_AR_OBJECTIVE = re.compile(
    r'^\s+-\s+((?:ي|يُ|يَ|يّ|يٌ|يً|يِ|يْ)\S+.+)$', re.MULTILINE
)


# ---------------------------------------------------------------------------
# English Objective Patterns (المعاصر Connect style)
# ---------------------------------------------------------------------------

# Skill category headers
_EN_SKILL_CATEGORY = re.compile(
    r'^(Speaking|Listening|Reading|Writing|Grammar|Vocabulary)\s*$',
    re.MULTILINE | re.IGNORECASE
)

# English objective bullet: "- Verb phrase..."
_EN_OBJECTIVE = re.compile(
    r'^\s*-\s+([A-Z][a-z].+)$', re.MULTILINE
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


def extract_arabic_objectives(text: str) -> Dict[str, List[str]]:
    """
    Extract objectives from Arabic Math textbook format.
    
    Structure:
        ### المفاهيم
        #### المفهوم الأول: ...
        - **الدرس (1): title**
          - يكتب التلميذ ...
          - يقرأ التلميذ ...
    
    Returns: {"الدرس (1): title": ["يكتب التلميذ ...", "يقرأ التلميذ ..."]}
    """
    results = {}
    sections = _find_sections(text, _MFAHEEM_HEADER)
    
    for section in sections:
        current_lesson = None
        
        for line in section.split('\n'):
            # Check if this is a lesson header
            lesson_match = _AR_LESSON_HEADER.match(line.strip() if not line.startswith(' ') else line)
            if not lesson_match:
                # Try matching without leading dash (some formats)
                lesson_match = _AR_LESSON_HEADER.search(line)
            
            if lesson_match:
                current_lesson = lesson_match.group(0).strip().strip('-').strip().strip('*').strip()
                if current_lesson not in results:
                    results[current_lesson] = []
                continue
            
            # Check if this is an objective (sub-indented Arabic verb bullet)
            obj_match = _AR_OBJECTIVE.match(line)
            if obj_match and current_lesson:
                objective = obj_match.group(1).strip()
                # Clean up: remove trailing periods
                objective = objective.rstrip('.')
                results[current_lesson].append(objective)
    
    return results


def extract_english_objectives(text: str) -> Dict[str, List[str]]:
    """
    Extract objectives from English textbook format.
    
    Structure:
        Learning Outcomes
        Speaking
        - Ask and answer questions about ...
        Reading
        - Answer comprehension questions ...
    
    Stops at: Lesson headers, UNIT headers, or 3+ consecutive blank lines.
    
    Returns: {"Speaking": ["Ask and answer ..."], "Reading": ["Answer comprehension ..."]}
    """
    results = {}
    
    for match in _LEARNING_OUTCOMES_HEADER.finditer(text):
        start = match.end()
        current_skill = "General"
        blank_count = 0
        
        for line in text[start:].split('\n'):
            stripped = line.strip()
            
            # Stop conditions: we've left the outcomes section
            if not stripped:
                blank_count += 1
                if blank_count >= 3:  # 3+ blank lines = section break
                    break
                continue
            else:
                blank_count = 0
            
            # Stop if we hit lesson/unit content
            if re.match(r'^(Lesson|UNIT|#)', stripped, re.IGNORECASE):
                break
            # Stop if we hit a markdown table
            if stripped.startswith('|'):
                break
            
            # Check for skill category
            skill_match = _EN_SKILL_CATEGORY.match(stripped)
            if skill_match:
                current_skill = skill_match.group(1).strip()
                if current_skill not in results:
                    results[current_skill] = []
                continue
            
            # Check for English objective bullet
            obj_match = _EN_OBJECTIVE.match(line)
            if obj_match:
                objective = obj_match.group(1).strip()
                if current_skill not in results:
                    results[current_skill] = []
                results[current_skill].append(objective)
    
    return results


def extract_all_objectives(text: str) -> Dict[str, List[str]]:
    """
    Extract all learning objectives from a textbook markdown.
    Automatically detects the textbook format (Arabic Math vs English).
    Returns a combined dictionary of all objectives found.
    """
    all_objectives = {}
    
    # Try Arabic extraction
    arabic = extract_arabic_objectives(text)
    all_objectives.update(arabic)
    
    # Try English extraction
    english = extract_english_objectives(text)
    all_objectives.update(english)
    
    total = sum(len(v) for v in all_objectives.values())
    print(f"[ObjectiveExtractor] Extracted {total} objectives across {len(all_objectives)} groups.", flush=True)
    
    return all_objectives
