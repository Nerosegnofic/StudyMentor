import random
import string
from typing import List, Dict, Set, Tuple
from sqlalchemy.orm import Session
from app.models.domain.quiz import QuizSession as QuizSessionModel
from app.models.domain import Question
from app.models.schemas import QuestionSchema

def generate_variance_block() -> str:
    """
    Generate a unique variance seed and question format requirements
    for each quiz generation call. This forces the LLM to produce diverse
    questions instead of deterministic repeats for identical inputs.
    """
    seed = ''.join(random.choices(string.ascii_uppercase + string.digits, k=8))
    formats = random.sample([
        "word problem with a real-world Egyptian scenario",
        "fill-in-the-blank calculation",
        "error detection (find the mistake in this solution)",
        "comparison between two values",
        "multi-step reasoning chain",
        "true/false with justification converted to MCQ",
    ], k=3)
    return (
        f"\n\nVARIANCE SEED: {seed}\n"
        "For this specific generation, you MUST use at least these question formats:\n"
        + "\n".join(f"  - {f}" for f in formats)
        + "\n\nDo NOT reuse numbers from any examples in the context. "
        "Generate fresh, novel numerical values for every question. "
        "Use Egyptian names (أحمد, فاطمة, يوسف, مريم, نور, عمر) and Egyptian contexts "
        "(المدرسة, السوق, الحديقة, المكتبة, الملعب) in word problems."
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
        q.text_content[:80].strip()
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


def filter_mismatched_questions(
    questions: List[QuestionSchema],
    difficulty_map: Dict[str, int],
    tolerance: int = 1,
) -> Tuple[List[QuestionSchema], int]:
    """
    Filters out questions whose difficulty doesn't match what was requested (±tolerance).
    
    Returns:
        (accepted_questions, dropped_count)
    """
    accepted = []
    dropped = 0
    for q in questions:
        requested_diff = difficulty_map.get(q.topic)
        if requested_diff is not None and abs(q.difficulty - requested_diff) > tolerance:
            print(
                f"[DifficultyGuard] Dropping question for topic='{q.topic}': "
                f"requested difficulty={requested_diff}, got={q.difficulty}",
                flush=True,
            )
            dropped += 1
        else:
            accepted.append(q)
    return accepted, dropped
