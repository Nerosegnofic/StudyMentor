from typing import List
from .base import SubjectStrategy

class GeneralStrategy(SubjectStrategy):
    """
    Fallback strategy using generic cognitive taxonomy.
    Works for any subject by focusing on universal thinking skills
    (recall, comprehension, application, analysis, evaluation)
    without subject-specific assumptions.
    """

    @property
    def subject_key(self) -> str:
        return "general"

    def difficulty_scale(self) -> str:
        return """━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
DIFFICULTY SCALE (CRITICAL — follow strictly)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Each difficulty level has specific cognitive requirements. Questions MUST match these criteria EXACTLY:

Level 1 — Very Easy (Recall):
  • Direct recall of a SINGLE fact, term, or definition from the lesson.
  • ZERO reasoning steps. The student only needs to REMEMBER.
  • The answer should be directly stated in the lesson material.

Level 2 — Easy (Comprehension):
  • Requires understanding a concept enough to apply it in ONE straightforward step.
  • Simple, single-step tasks.

Level 3 — Medium (Application):
  • Apply a learned concept or rule to a new but straightforward scenario.
  • May involve two steps or a short contextual setup.

Level 4 — Hard (Analysis):
  • Multi-step reasoning. The student must break a problem into parts or apply multiple rules.
  • Requires choosing the correct approach.

Level 5 — Very Hard (Evaluation & Synthesis):
  • Combine multiple concepts, evaluate options, or justify a position.
  • Requires significant thought and integration of knowledge."""

    def difficulty_violations(self) -> str:
        return """⚠️ DIFFICULTY VIOLATIONS — These are WRONG and WILL BE REJECTED:
  • Difficulty 1 with any reasoning or application → WRONG (Level 1 is pure recall)
  • Difficulty 1 or 2 with multi-step reasoning → WRONG (multi-step starts at Level 3)
  • Difficulty 1 or 2 with error detection or analysis → WRONG (analysis is Level 4+)
  • Difficulty 5 with a simple single-step question → WRONG (Level 5 requires synthesis)"""

    def self_check_rules(self) -> str:
        return """MANDATORY SELF-CHECK — Before finalizing EACH question, verify:
  1. Count the number of cognitive steps required. Level 1 = exactly 0 steps (just recall).
  2. Does the question require applying a rule or concept? Level 1 = NO application.
  3. Does the question require analysis or comparison? Analysis starts at Level 4.
  4. If ANY check fails, you MUST rewrite the question to match its assigned difficulty."""

    def formatting_rules(self) -> str:
        return """Formatting Rules:
- Write in the same language and script as the curriculum context provided.
- Use proper punctuation for that language.
- Ensure all options are clearly distinct and unambiguous."""

    def pedagogical_tone(self) -> str:
        return """Pedagogical Tone & Style:
- Write in the same language as the curriculum context provided below.
- Adjust vocabulary and complexity to the student's grade level.
- The tone must be clear, encouraging, and exactly like a school exam paper."""

    _FORMAT_POOLS = {
        1: [
            "direct fact recall (what is / what does ... mean?)",
            "identify the correct definition from options",
            "match a term to its meaning",
            "recall a key fact from the lesson",
        ],
        2: [
            "identify the correct example of a concept",
            "classify or categorize a given item",
            "choose the correct statement about a concept",
            "simple fill-in-the-blank",
        ],
        3: [
            "apply a rule or concept to a new scenario",
            "choose the correct outcome in a given situation",
            "complete a task requiring two steps",
            "identify the correct application of a rule",
        ],
        4: [
            "identify an error or inconsistency",
            "compare two concepts or items",
            "analyze a scenario and choose the correct explanation",
            "determine the most important factor",
        ],
        5: [
            "evaluate a claim or statement",
            "combine multiple concepts to solve a problem",
            "compare and evaluate two approaches",
            "justify a position based on lesson content",
        ],
    }

    def get_format_pool(self, difficulty: int) -> List[str]:
        return self._FORMAT_POOLS.get(difficulty, self._FORMAT_POOLS[3])
