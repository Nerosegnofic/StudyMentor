import random
import string
from typing import List, Dict, Set, Tuple
from sqlalchemy.orm import Session
from app.models.domain.quiz import QuizSession as QuizSessionModel
from app.models.domain import Question
from app.models.schemas import QuestionSchema


# ---------------------------------------------------------------------------
# Difficulty-aware question format pools.
# Each tier only contains formats whose cognitive complexity matches the level.
# ---------------------------------------------------------------------------
_FORMATS_BY_DIFFICULTY: Dict[int, List[str]] = {
    1: [  # Very Easy — pure recall / recognition
        "direct fact recall (e.g., 'ما هو...؟', 'ما اسم...؟')",
        "identify the correct definition from options",
        "match a term to its meaning",
        "recognize a visual representation or value",
    ],
    2: [  # Easy — single-step comprehension
        "simple single-step calculation",
        "fill-in-the-blank with one operation",
        "identify the correct example of a concept",
        "classify or categorize a given value",
    ],
    3: [  # Medium — application
        "short word problem with a real-world Egyptian scenario",
        "two-step calculation",
        "apply a learned rule to a new scenario",
        "fill-in-the-blank calculation",
    ],
    4: [  # Hard — analysis
        "multi-step reasoning chain",
        "error detection (find the mistake in this solution)",
        "comparison between two values requiring calculation",
        "word problem requiring multiple operations",
    ],
    5: [  # Very Hard — evaluation & synthesis
        "complex multi-concept word problem",
        "compare and evaluate two strategies",
        "error detection with detailed justification",
        "true/false with justification converted to MCQ",
    ],
}


def generate_variance_block(difficulty_levels: List[int] = None) -> str:
    """
    Generate a unique variance seed and difficulty-appropriate question format
    requirements for each quiz generation call.

    Args:
        difficulty_levels: List of difficulty levels present in this quiz.
                           Formats are selected only from pools matching these
                           levels, preventing hard formats from leaking into
                           easy questions.
    """
    seed = ''.join(random.choices(string.ascii_uppercase + string.digits, k=8))

    # Build per-difficulty format instructions
    if difficulty_levels:
        unique_levels = sorted(set(difficulty_levels))
    else:
        unique_levels = [3]  # Default to medium if unknown

    format_lines = []
    for level in unique_levels:
        pool = _FORMATS_BY_DIFFICULTY.get(level, _FORMATS_BY_DIFFICULTY[3])
        chosen = random.sample(pool, k=min(2, len(pool)))
        label = {1: "Very Easy", 2: "Easy", 3: "Medium", 4: "Hard", 5: "Very Hard"}.get(level, "Medium")
        for fmt in chosen:
            format_lines.append(f"  - For Difficulty {level} ({label}) questions: {fmt}")

    return (
        f"\n\nVARIANCE SEED: {seed}\n"
        "For this specific generation, use these question formats matched to each difficulty level:\n"
        + "\n".join(format_lines)
        + "\n\nIMPORTANT: Only use formats appropriate for each question's difficulty level. "
        "Do NOT use multi-step or word-problem formats for Difficulty 1 or 2 questions.\n"
        "Do NOT reuse numbers from any examples in the context. "
        "Generate fresh, novel numerical values for every question. "
        "Use Egyptian names (أحمد, فاطمة, يوسف, مريم, نور, عمر) and Egyptian contexts "
        "(المدرسة, السوق, الحديقة, المكتبة, الملعب) in word problems (Difficulty 3+ only)."
    )


def get_recent_question_fingerprints(
    db: Session,
    student_uid: str,
    subject_id: int,
    limit: int = 50,
) -> Set[str]:
    """
    Get fingerprints (first 80 chars) of recently generated questions
    for a specific student + subject, to prevent the LLM from repeating
    questions across quiz sessions.

    Scoped to ``subject_id`` so Math dedup fingerprints don't bleed into
    Arabic or Science quizzes (and vice versa).
    """
    recent_session_ids = (
        db.query(QuizSessionModel.session_id)
        .filter(
            QuizSessionModel.student_uid == student_uid,
            QuizSessionModel.subject_id == subject_id,
        )
        .order_by(QuizSessionModel.start_time.desc())
        .limit(10)
        .all()
    )
    if not recent_session_ids:
        return set()

    session_ids = [s.session_id for s in recent_session_ids]
    recent_questions = (
        db.query(Question.text_content)
        .filter(Question.session_id.in_(session_ids))
        .limit(limit)
        .all()
    )
    return {
        q.text_content[:150].strip()
        for q in recent_questions
        if q.text_content
    }


def shuffle_question_options(question_schema: QuestionSchema) -> QuestionSchema:
    """
    Shuffle the options of a question in-place and keep correct_answer consistent.
    This is the definitive server-side fix for LLM positional bias (always putting
    the correct answer first).
    """
    options = list(question_schema.options)
    random.shuffle(options)
    # correct_answer is a value, not a position — it stays the same string
    return QuestionSchema(
        question_id=question_schema.question_id,
        topic=question_schema.topic,
        question_text=question_schema.question_text,
        options=options,
        correct_answer=question_schema.correct_answer,
        explanation=question_schema.explanation,
        difficulty=question_schema.difficulty,
        hints=question_schema.hints,
    )


def build_difficulty_map(payload: List[Dict]) -> Dict[str, int]:
    """
    Build a mapping from skill name → requested difficulty from the BKT payload.
    Used for post-generation difficulty mismatch detection.
    """
    return {cfg["skill"]: cfg["difficulty"] for cfg in payload}


def _get_tolerance(requested_difficulty: int) -> int:
    """
    Returns the allowed tolerance for a given requested difficulty level.
    Extreme levels (1 = Very Easy, 5 = Very Hard) require an exact match
    because ±1 tolerance would blur the distinction with adjacent levels.
    Middle levels (2-4) allow ±1 tolerance.
    """
    if requested_difficulty in (1, 5):
        return 0  # Exact match required for Very Easy / Very Hard
    return 1      # ±1 tolerance for Easy / Medium / Hard


def filter_mismatched_questions(
    questions: List[QuestionSchema],
    difficulty_map: Dict[str, int],
    tolerance: int = 1,
) -> Tuple[List[QuestionSchema], int]:
    """
    Filters out questions whose difficulty doesn't match what was requested.

    Uses adaptive tolerance: exact match for extreme difficulties (1 and 5),
    ±1 for middle levels (2-4). The ``tolerance`` parameter is used as a
    maximum cap but the per-level tolerance may be stricter.

    Returns:
        (accepted_questions, dropped_count)
    """
    accepted = []
    dropped = 0
    for q in questions:
        requested_diff = difficulty_map.get(q.topic)
        if requested_diff is not None:
            effective_tolerance = min(tolerance, _get_tolerance(requested_diff))
            if abs(q.difficulty - requested_diff) > effective_tolerance:
                print(
                    f"[DifficultyGuard] Dropping question for topic='{q.topic}': "
                    f"requested difficulty={requested_diff}, got={q.difficulty} "
                    f"(tolerance={effective_tolerance})",
                    flush=True,
                )
                dropped += 1
            else:
                accepted.append(q)
        else:
            accepted.append(q)
    return accepted, dropped
