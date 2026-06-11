from typing import List
from .base import SubjectStrategy

class MathStrategy(SubjectStrategy):

    @property
    def subject_key(self) -> str:
        return "math"

    def difficulty_scale(self) -> str:
        return """━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
DIFFICULTY SCALE (CRITICAL — follow strictly)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Each difficulty level has specific cognitive requirements. Questions MUST match these criteria EXACTLY:

Level 1 — Very Easy (تذكّر / Recall):
  • Direct recall or recognition of a SINGLE fact, definition, or value from the lesson.
  • ZERO calculations. ZERO reasoning steps. The student only needs to REMEMBER.
  • NO word problems. NO scenarios. NO story context. Just a direct question.
  • The answer should be directly stated in the lesson material.
  • ✅ CORRECT example: "ما اسم الشكل الذي له 4 أضلاع متساوية؟"
  • ✅ CORRECT example: "ما القيمة المكانية لخانة الجزء من عشرة؟"
  • ❌ WRONG for Level 1: "اشترى أحمد 3 كتب..." (this is a word problem → Level 3+)
  • ❌ WRONG for Level 1: "أوجد ناتج 12 × 3" (this requires calculation → Level 2+)
  • ❌ WRONG for Level 1: "ما الخطأ في الحل التالي..." (this requires analysis → Level 4+)

Level 2 — Easy (فهم / Comprehension):
  • Requires understanding a concept enough to apply it in ONE straightforward step.
  • Simple, single-operation calculations with small, friendly numbers.
  • NO multi-step problems. NO word problems with story context.
  • ✅ CORRECT example: "أوجد ناتج: 12 × 3"
  • ✅ CORRECT example: "ما قيمة الرقم 5 في العدد 3.5؟"
  • ❌ WRONG for Level 2: "اشترى أحمد 5 دفاتر بسعر 7 جنيهات..." (word problem → Level 3+)
  • ❌ WRONG for Level 2: Any question requiring 2+ steps

Level 3 — Medium (تطبيق / Application):
  • Two-step problem OR applying a learned rule to a new but simple scenario.
  • May involve a short word problem that sets up context before asking a question.
  • ✅ CORRECT example: "اشترى أحمد 5 دفاتر بسعر 7 جنيهات للدفتر الواحد. كم دفع أحمد؟"

Level 4 — Hard (تحليل / Analysis):
  • Multi-step reasoning. The student must break a problem into parts or apply multiple rules.
  • Requires choosing the correct approach, not just computing.
  • ✅ CORRECT example: "مستطيل محيطه 30 سم وطوله ضعف عرضه. أوجد مساحته."

Level 5 — Very Hard (تقييم وإبداع / Evaluation & Synthesis):
  • Complex word problems combining multiple concepts from the lesson.
  • May require comparing strategies, detecting errors, or constructing a solution plan.
  • ✅ CORRECT example: "أيهما أكبر: مساحة مربع طول ضلعه 6 سم أم مساحة مستطيل أبعاده 4 سم × 8 سم؟ وضّح إجابتك.\""""

    def difficulty_violations(self) -> str:
        return """⚠️ DIFFICULTY VIOLATIONS — These are WRONG and WILL BE REJECTED:
  • Difficulty 1 with ANY calculation → WRONG (Level 1 is recall only, no math)
  • Difficulty 1 with a word problem or scenario → WRONG (Level 1 is direct fact recall)
  • Difficulty 1 or 2 with multi-step reasoning → WRONG (multi-step starts at Level 3)
  • Difficulty 1 or 2 with error detection → WRONG (error detection is Level 4+)
  • Difficulty 5 with a simple single-step question → WRONG (Level 5 requires synthesis)"""

    def self_check_rules(self) -> str:
        return """MANDATORY SELF-CHECK — Before finalizing EACH question, verify:
  1. Count the number of cognitive steps required to solve it.
     - Level 1 = exactly 0 steps (just recall a fact). Level 2 = exactly 1 step.
  2. Does the question require any calculation? Level 1 = ABSOLUTELY NO calculation.
  3. Does the question have a story/scenario setup? Level 1 and 2 = NO story/scenario.
  4. If ANY check fails, you MUST rewrite the question to match its assigned difficulty."""

    def formatting_rules(self) -> str:
        return """Numeric Formatting:
- Remove unnecessary trailing zeros from decimal numbers (write "3.7" NOT "3.70").
- Be consistent: if one option says "٣.٧", all numeric options in that question must use the same numeral system (Arabic-Indic or Western).

Math Formatting Rules (CRITICAL):
- NEVER use the dollar sign ($) or any LaTeX delimiters like \\( \\) or \\[ \\].
- Write all math as PLAIN TEXT using standard symbols.
- Use ' × ' for multiplication (NOT *, NOT \\times).
- Use ' ÷ ' for division (NOT /, NOT \\div).
- Example of WRONG: "ما ناتج $5 \\times 10$؟"
- Example of RIGHT: "ما ناتج ضرب 5 × 10؟\""""

    def pedagogical_tone(self) -> str:
        return """Pedagogical Tone & Style:
- Write like a professional Egyptian teacher using **Modern Standard Arabic (اللغة العربية الفصحى)**.
- Adjust vocabulary and sentence complexity to the student's grade level.
- Use different question formats. Sometimes use a story (e.g., "اشترى أحمد..."), sometimes a direct calculation.
- Use Egyptian names (أحمد, فاطمة, يوسف, مريم, نور, عمر) and Egyptian contexts (المدرسة, السوق, الحديقة, المكتبة, الملعب) في word problems (Difficulty 3+ only).
- The tone must be clear, encouraging, and exactly like a school exam paper."""

    _FORMAT_POOLS = {
        1: [
            "direct fact recall (e.g., 'ما هو...؟', 'ما اسم...؟')",
            "identify the correct definition from options",
            "match a term to its meaning",
            "recognize a visual representation or value",
        ],
        2: [
            "simple single-step calculation",
            "fill-in-the-blank with one operation",
            "identify the correct example of a concept",
            "classify or categorize a given value",
        ],
        3: [
            "short word problem with a real-world Egyptian scenario",
            "two-step calculation",
            "apply a learned rule to a new scenario",
            "fill-in-the-blank calculation",
        ],
        4: [
            "multi-step reasoning chain",
            "error detection (find the mistake in this solution)",
            "comparison between two values requiring calculation",
            "word problem requiring multiple operations",
        ],
        5: [
            "complex multi-concept word problem",
            "compare and evaluate two strategies",
            "error detection with detailed justification",
            "true/false with justification converted to MCQ",
        ],
    }

    def get_format_pool(self, difficulty: int) -> List[str]:
        return self._FORMAT_POOLS.get(difficulty, self._FORMAT_POOLS[3])
