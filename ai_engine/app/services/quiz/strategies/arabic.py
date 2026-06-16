from .profile import SubjectProfile

PROFILE = SubjectProfile(
    subject_key="arabic_lang",
    difficulty_scale="""━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
DIFFICULTY SCALE (CRITICAL — follow strictly)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Each difficulty level has specific cognitive requirements. Questions MUST match these criteria EXACTLY:

Level 1 — Very Easy (تذكّر / Recall):
  • Direct recall of a SINGLE vocabulary word, grammar term, or spelling rule from the lesson.
  • ZERO reasoning steps. The student only needs to REMEMBER.
  • ✅ CORRECT: "ما نوع كلمة 'كتاب'؟ (اسم / فعل / حرف)"
  • ✅ CORRECT: "ما معنى كلمة 'يتجول'؟"
  • ❌ WRONG for Level 1: "أعرب كلمة 'الكتاب' في الجملة..." (requires analysis → Level 3+)

Level 2 — Easy (فهم / Comprehension):
  • Requires understanding a grammar or spelling rule enough to apply it in ONE step.
  • Simple identification of word types, choosing the correct form, or basic spelling.
  • ✅ CORRECT: "اختر الكلمة التي تحتوي على تاء مربوطة"
  • ✅ CORRECT: "ما جمع كلمة 'معلم'؟"
  • ❌ WRONG for Level 2: Any question requiring parsing (إعراب) or multi-step reasoning.

Level 3 — Medium (تطبيق / Application):
  • Apply a grammar rule in a new sentence or choose the correct sentence structure.
  • ✅ CORRECT: "اختر الجملة الصحيحة نحويًا: أ) ذهبَ الولدان... ب) ذهبوا الولدان..."

Level 4 — Hard (تحليل / Analysis):
  • Analyze sentence structure, identify grammatical errors, or parse (إعراب) words.
  • ✅ CORRECT: "ما إعراب كلمة 'التلميذُ' في الجملة: 'نجحَ التلميذُ المجتهدُ'؟"

Level 5 — Very Hard (تقييم وإبداع / Evaluation & Synthesis):
  • Combine multiple grammar concepts or evaluate nuanced language use.
  • ✅ CORRECT: "أي الجمل التالية تحتوي على حال ومفعول به معًا؟\"""",
    difficulty_violations="""⚠️ DIFFICULTY VIOLATIONS — These are WRONG and WILL BE REJECTED:
  • Difficulty 1 with إعراب (parsing) → WRONG (Level 1 is pure recall)
  • Difficulty 1 requiring grammar application → WRONG (grammar application starts at Level 2)
  • Difficulty 1 or 2 with error detection → WRONG (error detection is Level 4+)
  • Difficulty 5 with a simple vocabulary meaning question → WRONG (Level 5 requires synthesis)""",
    self_check_rules="""MANDATORY SELF-CHECK — Before finalizing EACH question, verify:
  1. Does the question require more than recalling a definition? Level 1 = ONLY recall.
  2. Does the question require applying a grammar rule? Level 1 = NO rule application. Level 2 = ONE rule only.
  3. Does the question require إعراب or error analysis? These start at Level 4.
  4. If ANY check fails, you MUST rewrite the question to match its assigned difficulty.""",
    formatting_rules="""Language Formatting Rules:
- ALL questions must be written in Modern Standard Arabic (اللغة العربية الفصحى).
- Use proper Arabic punctuation (، ؛ ؟ !) and diacritical marks (تشكيل) where needed for clarity.
- When showing a word to analyze, put it in quotation marks or bold.
- Ensure grammatical examples are fully vowelized (مُشَكَّلة) when the question tests diacritics.""",
    pedagogical_tone="""Pedagogical Tone & Style:
- Write like a professional Egyptian Arabic language teacher using Modern Standard Arabic.
- Adjust vocabulary and sentence complexity to the student's grade level.
- Use clear, encouraging language exactly like a school exam paper.
- Use diverse question formats: vocabulary, grammar, spelling, sentence structure.""",
    format_pools={
        1: [
            "recall vocabulary meaning (ما معنى كلمة '...'؟)",
            "identify word type (اسم / فعل / حرف)",
            "recall a spelling rule (e.g., تاء مربوطة vs مفتوحة)",
            "match a word to its synonym or antonym",
        ],
        2: [
            "choose the correct plural or singular form",
            "identify the word with the correct spelling",
            "choose the correct diacritical mark (تشكيل)",
            "classify a word (e.g., مذكر/مؤنث, مفرد/جمع)",
        ],
        3: [
            "choose the grammatically correct sentence from options",
            "apply a grammar rule to complete a sentence",
            "rearrange words to form a correct sentence",
            "fill-in-the-blank with the correct word form",
        ],
        4: [
            "identify the grammatical error in a sentence",
            "إعراب (parse) a word in a given sentence",
            "distinguish between similar grammar rules in context",
            "correct an error in a given sentence",
        ],
        5: [
            "identify a sentence containing multiple grammar concepts",
            "evaluate which sentence best uses a complex grammar rule",
            "combine multiple grammar rules in analysis",
            "choose the most rhetorically effective sentence",
        ],
    },
)