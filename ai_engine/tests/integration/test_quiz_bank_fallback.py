"""
Integration tests for the quiz-bank fallback (DB-backed).

When live LLM generation fails, ``build_quiz_from_bank`` reassembles a quiz from
the student's previously-answered questions. Eligibility requires: a matching
skill name, difficulty within ±1 of target, an existing QuestionResponse by the
student, and ``submitted_at`` older than ``min_age_days``. The cloned questions
must carry ``source_enum="BANK"`` and fresh UUIDs. Coverage below ``min_coverage``
raises ``QuizBankInsufficientError``.
"""
import uuid
from datetime import datetime, timedelta

import pytest

from app.services.quiz.quiz_bank_service import build_quiz_from_bank
from app.core.exceptions import QuizBankInsufficientError
from tests.conftest import (
    make_subject, make_skill, make_quiz_session, make_question, make_response,
)

STUDENT = "student-bank"


def _bankable_question(db, skill, *, difficulty, age_days, session, answered=True):
    """A question old enough to reuse, with a student response."""
    q = make_question(
        db, skill_id=skill.skill_id, session_id=session.session_id,
        difficulty=difficulty, text_content="old question",
    )
    q.submitted_at = datetime.utcnow() - timedelta(days=age_days)
    if answered:
        make_response(db, question_id=q.question_id, student_uid=STUDENT, is_correct=True)
    db.flush()
    return q


@pytest.fixture
def bank_setup(db_session):
    subject = make_subject(db_session, name="Math")
    skill = make_skill(db_session, subject_id=subject.subject_id, name="Fractions")
    old_session = make_quiz_session(db_session, student_uid=STUDENT,
                                    subject_id=subject.subject_id, total_questions=10)
    return db_session, subject, skill, old_session


@pytest.mark.integration
class TestQuizBankFallback:
    def test_builds_quiz_when_bank_has_enough(self, bank_setup):
        db, subject, skill, old_session = bank_setup
        for _ in range(5):
            _bankable_question(db, skill, difficulty=3, age_days=30, session=old_session)

        payload = [{"skill": "Fractions", "difficulty": 3, "count": 4}]
        new_session_id = uuid.uuid4()
        cloned = build_quiz_from_bank(db, STUDENT, subject.subject_id, payload, new_session_id)

        assert len(cloned) == 4
        assert all(c.source_enum == "BANK" for c in cloned)
        assert all(c.session_id == new_session_id for c in cloned)

    def test_difficulty_within_plus_minus_one_is_eligible(self, bank_setup):
        db, subject, skill, old_session = bank_setup
        # Target 3 -> difficulties 2,3,4 are eligible; 1 and 5 are not.
        for d in (2, 3, 4):
            _bankable_question(db, skill, difficulty=d, age_days=30, session=old_session)
        _bankable_question(db, skill, difficulty=1, age_days=30, session=old_session)
        _bankable_question(db, skill, difficulty=5, age_days=30, session=old_session)

        payload = [{"skill": "Fractions", "difficulty": 3, "count": 3}]
        cloned = build_quiz_from_bank(db, STUDENT, subject.subject_id, payload, uuid.uuid4())
        assert len(cloned) == 3
        assert all(2 <= c.difficulty <= 4 for c in cloned)

    def test_recently_answered_questions_are_excluded(self, bank_setup):
        db, subject, skill, old_session = bank_setup
        # All questions answered only 1 day ago -> below the 7-day min age -> ineligible.
        for _ in range(5):
            _bankable_question(db, skill, difficulty=3, age_days=1, session=old_session)

        payload = [{"skill": "Fractions", "difficulty": 3, "count": 4}]
        with pytest.raises(QuizBankInsufficientError):
            build_quiz_from_bank(db, STUDENT, subject.subject_id, payload, uuid.uuid4())

    def test_insufficient_coverage_raises(self, bank_setup):
        db, subject, skill, old_session = bank_setup
        # Only 1 eligible question but 4 required -> 25% coverage < 60% threshold.
        _bankable_question(db, skill, difficulty=3, age_days=30, session=old_session)

        payload = [{"skill": "Fractions", "difficulty": 3, "count": 4}]
        with pytest.raises(QuizBankInsufficientError):
            build_quiz_from_bank(db, STUDENT, subject.subject_id, payload, uuid.uuid4())

    def test_unanswered_questions_are_not_reused(self, bank_setup):
        db, subject, skill, old_session = bank_setup
        # Old enough but never answered by this student -> not in the bank.
        for _ in range(5):
            _bankable_question(db, skill, difficulty=3, age_days=30,
                               session=old_session, answered=False)

        payload = [{"skill": "Fractions", "difficulty": 3, "count": 4}]
        with pytest.raises(QuizBankInsufficientError):
            build_quiz_from_bank(db, STUDENT, subject.subject_id, payload, uuid.uuid4())