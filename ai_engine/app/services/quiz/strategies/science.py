from typing import List
from .base import SubjectStrategy

class ScienceStrategy(SubjectStrategy):

    @property
    def subject_key(self) -> str:
        return "science"

    def difficulty_scale(self) -> str:
        return """━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
DIFFICULTY SCALE (CRITICAL — follow strictly)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Each difficulty level has specific cognitive requirements. Questions MUST match these criteria EXACTLY:

Level 1 — Very Easy (تذكّر / Recall):
  • Direct recall of a SINGLE scientific fact, term, or definition from the lesson.
  • ZERO reasoning. The student only needs to REMEMBER.
  • ✅ CORRECT: "ما العضو المسؤول عن ضخ الدم في جسم الإنسان؟"
  • ✅ CORRECT: "ما الغاز الذي يحتاجه الإنسان للتنفس؟"
  • ❌ WRONG for Level 1: "ماذا يحدث عند تسخين الماء..." (requires reasoning → Level 2+)

Level 2 — Easy (فهم / Comprehension):
  • Requires understanding a concept enough to identify a simple cause-effect or classification.
  • ✅ CORRECT: "أي مما يلي يُعد من المواد الصلبة؟"
  • ✅ CORRECT: "ما الفرق بين المادة الصلبة والسائلة؟"
  • ❌ WRONG for Level 2: Any question requiring experiment design or multi-step reasoning.

Level 3 — Medium (تطبيق / Application):
  • Apply a scientific concept to predict an outcome or explain a simple phenomenon.
  • ✅ CORRECT: "ماذا يحدث لبخار الماء عند ملامسته لسطح بارد؟"

Level 4 — Hard (تحليل / Analysis):
  • Analyze an experiment, compare phenomena, or explain a causal chain.
  • ✅ CORRECT: "في تجربة وضع نبات في الظلام لمدة أسبوع، ماذا نتوقع أن يحدث لأوراقه؟ ولماذا؟"

Level 5 — Very Hard (تقييم وإبداع / Evaluation & Synthesis):
  • Evaluate a scientific claim, design an experiment, or synthesize multiple concepts.
  • ✅ CORRECT: "أي التجارب التالية تثبت أن النبات يحتاج إلى ضوء الشمس للنمو؟\""""

    def difficulty_violations(self) -> str:
        return """⚠️ DIFFICULTY VIOLATIONS — These are WRONG and WILL BE REJECTED:
  • Difficulty 1 with cause-effect reasoning → WRONG (Level 1 is pure recall of a term/fact)
  • Difficulty 1 with "ماذا يحدث عند..." → WRONG (prediction requires reasoning → Level 2+)
  • Difficulty 1 or 2 with experiment analysis → WRONG (experiment analysis is Level 4+)
  • Difficulty 5 with a simple term recall → WRONG (Level 5 requires synthesis or evaluation)"""

    def self_check_rules(self) -> str:
        return """MANDATORY SELF-CHECK — Before finalizing EACH question, verify:
  1. Does the question require more than recalling a single fact? Level 1 = ONLY recall a term or definition.
  2. Does the question ask "ماذا يحدث" or "ما النتيجة"? These require reasoning → Level 2+ minimum.
  3. Does the question involve experiment analysis? Experiment analysis starts at Level 4.
  4. If ANY check fails, you MUST rewrite the question to match its assigned difficulty."""

    def formatting_rules(self) -> str:
        return """Science Formatting Rules:
- Write scientific terms accurately in Arabic with optional English in parentheses for clarity (e.g., التمثيل الضوئي (Photosynthesis)).
- Use proper Arabic punctuation.
- When mentioning measurements, use standard units (سم, م, كجم, °م)."""

    def pedagogical_tone(self) -> str:
        return """Pedagogical Tone & Style:
- Write like a professional Egyptian science teacher using Modern Standard Arabic.
- Adjust vocabulary and scientific depth to the student's grade level.
- Use real-world Egyptian examples where appropriate (e.g., نهر النيل, الصحراء, المحاصيل المصرية).
- The tone must be clear, encouraging, and exactly like a school science exam paper."""

    _FORMAT_POOLS = {
        1: [
            "recall a scientific fact or term (ما هو / ما اسم...)",
            "identify an organ, body part, or organism",
            "match a scientific term to its definition",
            "recall a property of a material or substance",
        ],
        2: [
            "classify an object, material, or organism",
            "identify a simple cause from a single fact",
            "choose the correct scientific comparison",
            "identify which statement about a concept is true",
        ],
        3: [
            "predict an outcome of a simple phenomenon",
            "apply a scientific concept to a new scenario",
            "explain a simple cause-and-effect relationship",
            "identify what would happen if a variable changes",
        ],
        4: [
            "analyze an experiment's results",
            "compare two phenomena or processes",
            "identify the correct explanation for an observation",
            "determine the variable in an experiment",
        ],
        5: [
            "evaluate a scientific claim or hypothesis",
            "choose the best experiment design to test a hypothesis",
            "synthesize information from multiple concepts",
            "compare and evaluate two experimental approaches",
        ],
    }

    def get_format_pool(self, difficulty: int) -> List[str]:
        return self._FORMAT_POOLS.get(difficulty, self._FORMAT_POOLS[3])
