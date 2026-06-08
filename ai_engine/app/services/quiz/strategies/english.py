from typing import List
from .base import SubjectStrategy

class EnglishStrategy(SubjectStrategy):

    @property
    def subject_key(self) -> str:
        return "english"

    def difficulty_scale(self) -> str:
        return """━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
DIFFICULTY SCALE (CRITICAL — follow strictly)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Each difficulty level has specific cognitive requirements. Questions MUST match these criteria EXACTLY:

Level 1 — Very Easy (Recall):
  • Direct recall of a SINGLE vocabulary word, spelling, or grammar fact from the lesson.
  • The student only needs to REMEMBER — no sentence construction, no context clues needed.
  • ✅ CORRECT: "What is the meaning of the word 'generous'?"
  • ✅ CORRECT: "Which word is spelled correctly?"
  • ❌ WRONG for Level 1: "Complete the sentence: She ___ to school yesterday." (requires application → Level 2+)

Level 2 — Easy (Comprehension):
  • Requires understanding a grammar rule or vocabulary word enough to use it in ONE step.
  • Simple fill-in-the-blank, choosing the correct form, or identifying a part of speech.
  • ✅ CORRECT: "Choose the correct form: She ___ (go/goes/going) to school every day."
  • ✅ CORRECT: "What part of speech is the word 'quickly'?"
  • ❌ WRONG for Level 2: Any question requiring reading a passage or multiple reasoning steps.

Level 3 — Medium (Application):
  • Apply a grammar or vocabulary rule in a new sentence or short context.
  • May involve completing a short dialogue or choosing the correct sentence.
  • ✅ CORRECT: "Which sentence is grammatically correct? A) He don't like... B) He doesn't like..."

Level 4 — Hard (Analysis):
  • Analyze sentence structure, identify errors in context, or distinguish similar rules.
  • ✅ CORRECT: "Find the grammatical error in this sentence: 'The children was playing in the park.'"

Level 5 — Very Hard (Evaluation & Synthesis):
  • Combine multiple grammar/vocabulary concepts or evaluate nuanced language use.
  • ✅ CORRECT: "Which sentence uses both the past tense and a prepositional phrase correctly?\""""

    def difficulty_violations(self) -> str:
        return """⚠️ DIFFICULTY VIOLATIONS — These are WRONG and WILL BE REJECTED:
  • Difficulty 1 with sentence completion → WRONG (Level 1 is pure recall of a word/definition)
  • Difficulty 1 requiring any grammar application → WRONG (grammar application starts at Level 2)
  • Difficulty 1 or 2 with error detection → WRONG (error detection is Level 4+)
  • Difficulty 5 with a simple vocabulary meaning question → WRONG (Level 5 requires synthesis)"""

    def self_check_rules(self) -> str:
        return """MANDATORY SELF-CHECK — Before finalizing EACH question, verify:
  1. Does the question require more than simple recall? Level 1 = ONLY recall a word meaning or spelling.
  2. Does the question require applying a rule? Level 1 = NO rule application. Level 2 = ONE rule only.
  3. Does the question require error analysis? Error detection starts at Level 4.
  4. If ANY check fails, you MUST rewrite the question to match its assigned difficulty."""

    def formatting_rules(self) -> str:
        return """Language Formatting Rules:
- ALL questions, options, hints, and explanations MUST be written in ENGLISH.
- Use proper English capitalization and punctuation.
- When showing a word to define, put it in quotation marks (e.g., "generous").
- Keep sentences age-appropriate for the student's grade level."""

    def pedagogical_tone(self) -> str:
        return """Pedagogical Tone & Style:
- Write like a professional English teacher for Egyptian students.
- ALL questions, options, hints, and explanations must be in ENGLISH — do NOT mix Arabic.
- Adjust vocabulary and sentence complexity to the student's grade level.
- Use simple, clear instructions (e.g., "Choose the correct word", "Which sentence is correct?").
- The tone must be clear, encouraging, and exactly like a school English exam paper."""

    _FORMAT_POOLS = {
        1: [
            "vocabulary word meaning (What does '...' mean?)",
            "identify the correct spelling of a word",
            "match a word to its definition",
            "recall a grammar term (e.g., noun, verb, adjective)",
        ],
        2: [
            "choose the correct grammar form (fill-in-the-blank)",
            "identify the part of speech of a given word",
            "complete a sentence with the correct word",
            "choose the correct pronoun or preposition",
        ],
        3: [
            "choose the grammatically correct sentence from options",
            "complete a short dialogue with the correct response",
            "rearrange words to form a correct sentence",
            "fill-in-the-blank using context clues",
        ],
        4: [
            "identify the grammatical error in a sentence",
            "choose the sentence that uses a grammar rule correctly",
            "distinguish between commonly confused words in context",
            "correct an error in a given sentence",
        ],
        5: [
            "combine multiple grammar concepts in one sentence",
            "evaluate which sentence is stylistically or grammatically best",
            "identify the sentence that uses both tense and agreement correctly",
            "choose the most appropriate formal/informal register",
        ],
    }

    def get_format_pool(self, difficulty: int) -> List[str]:
        return self._FORMAT_POOLS.get(difficulty, self._FORMAT_POOLS[3])
