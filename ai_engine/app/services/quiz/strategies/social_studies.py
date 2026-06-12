from typing import List
from .base import SubjectStrategy

class SocialStudiesStrategy(SubjectStrategy):

    @property
    def subject_key(self) -> str:
        return "social_studies"

    def difficulty_scale(self) -> str:
        return """━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
DIFFICULTY SCALE (CRITICAL — follow strictly)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Each difficulty level has specific cognitive requirements. Questions MUST match these criteria EXACTLY:

Level 1 — Very Easy (تذكّر / Recall):
  • Direct recall of a SINGLE fact: a date, a name, a place, or a definition from the lesson.
  • ZERO reasoning. The student only needs to REMEMBER.
  • ✅ CORRECT: "ما عاصمة جمهورية مصر العربية؟"
  • ✅ CORRECT: "في أي عام تم افتتاح قناة السويس؟"
  • ❌ WRONG for Level 1: "ما أثر بناء السد العالي على الزراعة..." (requires reasoning → Level 2+)

Level 2 — Easy (فهم / Comprehension):
  • Requires understanding a concept enough to explain a simple relationship or identify a cause.
  • ✅ CORRECT: "لماذا يتركز السكان حول وادي النيل؟"
  • ✅ CORRECT: "ما الفرق بين الموقع الفلكي والموقع الجغرافي؟"
  • ❌ WRONG for Level 2: Any question requiring comparison of multiple factors or analysis.

Level 3 — Medium (تطبيق / Application):
  • Apply a concept to a new context or interpret a map/chart.
  • ✅ CORRECT: "إذا كانت دولة تقع على خط عرض 30 شمالاً، في أي نطاق مناخي تقع؟"

Level 4 — Hard (تحليل / Analysis):
  • Analyze causes and effects of historical events or geographic phenomena.
  • ✅ CORRECT: "قارن بين أسباب الحملة الفرنسية والحملة الإنجليزية على مصر."

Level 5 — Very Hard (تقييم وإبداع / Evaluation & Synthesis):
  • Evaluate historical decisions, synthesize multiple factors, or justify a position.
  • ✅ CORRECT: "أي العوامل التالية كان الأكثر تأثيرًا في نهضة مصر الحديثة؟ وضّح إجابتك.\""""

    def difficulty_violations(self) -> str:
        return """⚠️ DIFFICULTY VIOLATIONS — These are WRONG and WILL BE REJECTED:
  • Difficulty 1 with cause-effect reasoning → WRONG (Level 1 is pure recall of a fact/date/name)
  • Difficulty 1 with "ما أثر" or "لماذا" → WRONG (these require reasoning → Level 2+)
  • Difficulty 1 or 2 with comparison of multiple factors → WRONG (comparison is Level 3+)
  • Difficulty 5 with a simple fact recall → WRONG (Level 5 requires evaluation/synthesis)"""

    def self_check_rules(self) -> str:
        return """MANDATORY SELF-CHECK — Before finalizing EACH question, verify:
  1. Does the question require more than recalling a single fact/date/place? Level 1 = ONLY recall.
  2. Does the question ask "لماذا" or "ما أثر"? These require reasoning → Level 2+ minimum.
  3. Does the question require comparing multiple factors? Comparison starts at Level 3.
  4. If ANY check fails, you MUST rewrite the question to match its assigned difficulty."""

    def formatting_rules(self) -> str:
        return """Social Studies Formatting Rules:
- Write all dates using Western numerals (e.g., 1869 not ١٨٦٩) for clarity.
- Use proper Arabic punctuation.
- When mentioning historical figures, use their full commonly-known name."""

    def pedagogical_tone(self) -> str:
        return """Pedagogical Tone & Style:
- Write like a professional Egyptian social studies teacher using Modern Standard Arabic.
- Adjust vocabulary and depth to the student's grade level.
- Focus on Egyptian geography, history, and civic concepts as appropriate for the curriculum.
- The tone must be clear, encouraging, and exactly like a school exam paper."""

    _FORMAT_POOLS = {
        1: [
            "recall a historical date or event (متى / في أي عام...)",
            "identify a place or location (ما عاصمة / أين تقع...)",
            "recall a definition or term (ما المقصود بـ...)",
            "identify a historical figure and their role",
        ],
        2: [
            "explain a simple cause-effect relationship",
            "identify the reason behind a geographic or historical fact",
            "choose the correct description of a concept",
            "match a historical event to its cause or result",
        ],
        3: [
            "apply a geographic concept to a new context",
            "interpret information from a described map or chart",
            "identify the result of a historical decision",
            "classify a region based on given criteria",
        ],
        4: [
            "compare two historical events or geographic phenomena",
            "analyze the causes of a historical event",
            "identify the most significant factor among several",
            "explain the relationship between multiple historical factors",
        ],
        5: [
            "evaluate a historical decision and justify a position",
            "synthesize multiple factors to explain a complex event",
            "compare and evaluate two historical interpretations",
            "propose a solution to a civic/geographic problem",
        ],
    }

    def get_format_pool(self, difficulty: int) -> List[str]:
        return self._FORMAT_POOLS.get(difficulty, self._FORMAT_POOLS[3])
