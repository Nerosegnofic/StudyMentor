"""
Quiz Bank Fallback Service (G12).

When the primary LLM generation fails (LLMGenerationError after all retries),
this service attempts to assemble a quiz from the student's previously answered
questions stored in the `questions` table.

Eligibility criteria for a bank question:
  - text_content is NOT NULL (not yet scrubbed by the 30-day cleanup job).
  - The student has a QuestionResponse for this question (they answered it).
  - It was answered at least QUIZ_BANK_MIN_AGE_DAYS days ago (prevents re-use
    of questions the student just saw, which would defeat the learning purpose).
  - skill_id maps to the required skill name.
  - difficulty is within ±1 of the target difficulty level.

The assembled questions are CLONED into the new session with fresh UUIDs so
submission grading, BKT updates, and the 30-day scrub all work correctly.
"""

import uuid
from datetime import datetime, timedelta
from typing import List, Dict, Optional

from sqlalchemy import and_, func
from sqlalchemy.orm import Session

from app.models.domain.quiz import Question, QuestionResponse
from app.models.domain.curriculum import Skill
from app.core.config import settings
from app.core.exceptions import QuizBankInsufficientError


def build_quiz_from_bank(
    db: Session,
    student_uid: str,
    subject_id: int,
    quiz_payload: List[Dict],
    new_session_id: uuid.UUID,
    min_coverage: float = None,
    min_age_days: int = None,
) -> List[Question]:
    """
    Assembles a quiz from the student's previously answered questions.

    Args:
        db: Active SQLAlchemy session.
        student_uid: The authenticated student's Firebase UID.
        subject_id: Subject ID (used for logging only — skill filtering is by name).
        quiz_payload: Output of build_quiz_payload() — list of dicts with keys:
                      {"skill": str, "difficulty": int, "count": int}
        new_session_id: UUID of the new QuizSession to attach cloned questions to.
        min_coverage: Minimum fraction of required questions the bank must fill.
                      Defaults to settings.QUIZ_BANK_MIN_COVERAGE (0.60).
        min_age_days: Questions answered within this many days are excluded.
                      Defaults to settings.QUIZ_BANK_MIN_AGE_DAYS (7).

    Returns:
        List of new Question ORM objects (clones with new UUIDs, source_enum="BANK").

    Raises:
        QuizBankInsufficientError: If coverage < min_coverage threshold.
                                   The controller should then return 503.
    """
    if min_coverage is None:
        min_coverage = settings.QUIZ_BANK_MIN_COVERAGE
    if min_age_days is None:
        min_age_days = settings.QUIZ_BANK_MIN_AGE_DAYS

    total_required = sum(cfg["count"] for cfg in quiz_payload)
    cutoff_date = datetime.utcnow() - timedelta(days=min_age_days)

    bank_questions: List[Question] = []
    used_question_ids: set = set()

    for cfg in quiz_payload:
        skill_name: str = cfg["skill"]
        target_difficulty: int = cfg["difficulty"]
        count_needed: int = cfg["count"]

        # Build exclusion filter for already-selected questions
        excluded = list(used_question_ids) if used_question_ids else None

        query = (
            db.query(Question)
            .join(Skill, Question.skill_id == Skill.skill_id)
            .join(
                QuestionResponse,
                and_(
                    QuestionResponse.question_id == Question.question_id,
                    QuestionResponse.student_uid == student_uid,
                ),
            )
            .filter(
                Skill.name == skill_name,
                Question.text_content.isnot(None),          # Not yet scrubbed
                Question.difficulty >= target_difficulty - 1,
                Question.difficulty <= target_difficulty + 1,
                Question.submitted_at <= cutoff_date,        # Old enough to reuse
            )
        )

        if excluded:
            query = query.filter(Question.question_id.notin_(excluded))

        candidates: List[Question] = (
            query.order_by(func.random()).limit(count_needed).all()
        )

        for original in candidates:
            used_question_ids.add(original.question_id)

            # Clone the question with a new UUID so it belongs to this session.
            # The clone has source_enum="BANK" to distinguish it from LLM-fresh questions.
            cloned = Question(
                question_id=uuid.uuid4(),
                skill_id=original.skill_id,
                session_id=new_session_id,
                text_content=original.text_content,
                options=original.options,
                correct_answer=original.correct_answer,
                difficulty=original.difficulty,
                source_enum="BANK",
                explanation=original.explanation,
                hints=original.hints,
            )
            bank_questions.append(cloned)

    # Coverage check
    coverage = len(bank_questions) / total_required if total_required > 0 else 0.0
    print(
        f"[QuizBank] Bank coverage: {len(bank_questions)}/{total_required} "
        f"({coverage:.0%}) for student={student_uid}, subject_id={subject_id}",
        flush=True,
    )

    if coverage < min_coverage:
        raise QuizBankInsufficientError(
            f"Quiz bank coverage {coverage:.0%} is below the required threshold "
            f"({min_coverage:.0%}). The student may be new or all eligible bank "
            f"questions were answered within the last {min_age_days} days."
        )

    return bank_questions
