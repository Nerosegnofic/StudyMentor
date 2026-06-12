"""
Quiz Prompt Assembly.

Assembles a ChatPromptTemplate from a subject-neutral BASE_TEMPLATE
plus strategy-provided slot content. Zero subject logic lives here —
the strategy decides what goes into each slot.

Usage:
    from app.services.quiz.strategy_resolver import resolve_subject_strategy
    strategy = resolve_subject_strategy("الرياضيات")
    prompt = build_quiz_prompt(strategy)
"""

from langchain_core.prompts import ChatPromptTemplate
from app.services.quiz.strategies import SubjectStrategy


# ─── Base Template ────────────────────────────────────────────────────
# Contains ONLY universal rules that apply to ALL subjects.
# Subject-specific content is injected via named slots at build time.
#
# Double-pass formatting:
#   • Strategy slots ({difficulty_scale}, etc.) are filled at BUILD time
#     via Python str.format().
#   • LangChain variables ({{topic_instructions}}, etc.) use doubled braces
#     so they survive the first .format() and are filled at INVOKE time.
# ──────────────────────────────────────────────────────────────────────

_BASE_SYSTEM_TEMPLATE = """\
You are an expert educational teacher for Egyptian {{student_grade}}-grade students.
Your subject is: {{subject_name}}
Your task is to generate an educational quiz based strictly on the provided context extracted from the curriculum textbook.
The entire quiz, including questions, options, hints, and explanations, MUST be written in the exact same language as the provided Curriculum Context.

You MUST follow the per-topic instructions below exactly. Each line specifies a topic, its target difficulty, and how many questions to generate for that topic.

Topic Instructions:
{{topic_instructions}}

Total questions to generate: {{total_count}}

{difficulty_scale}

{difficulty_violations}

{self_check_rules}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ANSWER & OPTIONS RULES (CRITICAL)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. Each question MUST have exactly ONE unambiguously correct answer. The other 3 options (distractors) MUST be clearly and definitively wrong.
2. NEVER generate options where two or more could be considered correct, partially correct, or ambiguous.
3. The `correct_answer` field MUST be an EXACT character-for-character copy of one of the 4 options.
4. All 4 options MUST be unique — no duplicates, no semantic equivalents (e.g., "3.70" and "3.7" are NOT allowed together).
5. RANDOMIZE the position of the correct answer across all questions. Do NOT always place it as the first option. Distribute it roughly evenly across all four positions.
6. Distractors must be plausible (common mistakes students make) but never correct.

{formatting_rules}

{pedagogical_tone}

Guidelines:
1. Generate EXACTLY the number of questions specified for each topic at the requested difficulty level.
2. The `difficulty` field of each generated question MUST match the difficulty requested for its topic.
3. Provide exactly 3 progressive `hints` to help the student solve the problem.
4. The questions must be strictly based on the provided curriculum context below.
5. IMPORTANT: Questions MUST be self-contained. DO NOT reference the textbook or "the text." Provide any necessary information inside the question itself.
6. Ensure the vocabulary is perfectly suited for {{student_grade}}-grade Egyptian students.
7. Provide 4 multiple-choice options for each question.
8. Clearly state the correct answer (which must exactly match one of the options).
9. Provide a brief, supportive explanation for why the answer is correct.
10. IMPORTANT: Map each question to the correct `skill_id` provided in the Topic Instructions. If no Skill ID was provided for a topic, leave it as null.
{{variance_block}}"""


def build_quiz_prompt(strategy: SubjectStrategy) -> ChatPromptTemplate:
    """
    Assemble the quiz generation prompt from the base template
    plus strategy-provided slot content.

    The strategy fills subject-specific slots (difficulty scale,
    violations, self-check, formatting, tone). Universal rules
    (answer/options rules, guidelines) are in the base template.

    Args:
        strategy: A SubjectStrategy instance providing slot content.

    Returns:
        A ChatPromptTemplate ready for LangChain invocation.
    """
    # Escape any literal braces in strategy-provided content so they
    # survive the .format() call (strategy content should not contain
    # LangChain-style {variables}, but just in case).
    def _safe(text: str) -> str:
        return text.replace("{", "{{").replace("}", "}}")

    system_text = _BASE_SYSTEM_TEMPLATE.format(
        difficulty_scale=_safe(strategy.difficulty_scale()),
        difficulty_violations=_safe(strategy.difficulty_violations()),
        self_check_rules=_safe(strategy.self_check_rules()),
        formatting_rules=_safe(strategy.formatting_rules()),
        pedagogical_tone=_safe(strategy.pedagogical_tone()),
    )

    return ChatPromptTemplate.from_messages([
        ("system", system_text),
        ("human", "Curriculum Context:\n{context}\n\nPlease generate the adaptive quiz now."),
    ])
