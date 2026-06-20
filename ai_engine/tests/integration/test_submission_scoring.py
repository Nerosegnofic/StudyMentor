"""
Integration tests for quiz submission (DB-backed).

Exercises ``process_quiz_submission`` end-to-end against in-memory SQLite with a
seeded Level ladder. Asserts both the scoring math and the SECURITY guards that
make the server the source of truth:

  - correctness is verified server-side against the stored ``correct_answer``
    (a client cannot mark its own wrong answer correct);
  - the answer count must equal the session's ``total_questions`` (400);
  - answers referencing questions outside the session are rejected (400);
  - submitting someone else's session is forbidden (403);
  - a session cannot be submitted twice (409);
  - a correct answer faster than the genuine-time threshold is flagged and skips
    the BKT mastery bump.
"""
import pytest
from fastapi import HTTPException

from app.core.config import settings
from app.services.quiz.quiz_submission_service import process_quiz_submission
from app.models.schemas import QuizSubmissionRequest, StudentAnswer
from app.models.domain import StudentSkillState
from tests.conftest import (
    seed_levels, make_subject, make_skill, make_quiz_session, make_question,
)

STUDENT = "student-submit"


@pytest.fixture
def quiz(db_session):
    """A 2-question quiz session owned by STUDENT, with a seeded Level ladder."""
    seed_levels(db_session)
    subject = make_subject(db_session, name="Math")
    skill = make_skill(db_session, subject_id=subject.subject_id, name="Fractions")
    session = make_quiz_session(db_session, student_uid=STUDENT,
                                subject_id=subject.subject_id, total_questions=2)
    q1 = make_question(db_session, skill_id=skill.skill_id, session_id=session.session_id,
                       correct_answer="A", difficulty=3.0)
    q2 = make_question(db_session, skill_id=skill.skill_id, session_id=session.session_id,
                       correct_answer="B", difficulty=3.0)
    db_session.commit()
    return db_session, session, q1, q2


def _answer(q, option, ms=10_000):
    return StudentAnswer(question_id=str(q.question_id), selected_option=option, time_taken_ms=ms)


@pytest.mark.integration
class TestSubmissionScoring:
    def test_all_correct_scores_100(self, quiz):
        db, session, q1, q2 = quiz
        req = QuizSubmissionRequest(
            quiz_session_id=str(session.session_id),
            answers=[_answer(q1, "A"), _answer(q2, "B")],
        )
        resp = process_quiz_submission(db, req, STUDENT)
        assert resp.score == 100.0

    def test_half_correct_scores_50(self, quiz):
        db, session, q1, q2 = quiz
        req = QuizSubmissionRequest(
            quiz_session_id=str(session.session_id),
            answers=[_answer(q1, "A"), _answer(q2, "WRONG")],
        )
        resp = process_quiz_submission(db, req, STUDENT)
        assert resp.score == 50.0

    def test_correctness_is_verified_server_side(self, quiz):
        """A client selecting the wrong option cannot make it score as correct."""
        db, session, q1, q2 = quiz
        # q1's correct answer is "A"; the client sends "Z".
        req = QuizSubmissionRequest(
            quiz_session_id=str(session.session_id),
            answers=[_answer(q1, "Z"), _answer(q2, "B")],
        )
        resp = process_quiz_submission(db, req, STUDENT)
        assert resp.score == 50.0  # only q2 counts, server-graded


@pytest.mark.integration
class TestSubmissionGuards:
    def test_wrong_answer_count_rejected(self, quiz):
        db, session, q1, q2 = quiz
        req = QuizSubmissionRequest(
            quiz_session_id=str(session.session_id),
            answers=[_answer(q1, "A")],  # only 1 of 2
        )
        with pytest.raises(HTTPException) as exc:
            process_quiz_submission(db, req, STUDENT)
        assert exc.value.status_code == 400

    def test_foreign_question_rejected(self, quiz):
        db, session, q1, q2 = quiz
        import uuid
        foreign = StudentAnswer(question_id=str(uuid.uuid4()), selected_option="A")
        req = QuizSubmissionRequest(
            quiz_session_id=str(session.session_id),
            answers=[_answer(q1, "A"), foreign],
        )
        with pytest.raises(HTTPException) as exc:
            process_quiz_submission(db, req, STUDENT)
        assert exc.value.status_code == 400

    def test_other_students_session_forbidden(self, quiz):
        db, session, q1, q2 = quiz
        req = QuizSubmissionRequest(
            quiz_session_id=str(session.session_id),
            answers=[_answer(q1, "A"), _answer(q2, "B")],
        )
        with pytest.raises(HTTPException) as exc:
            process_quiz_submission(db, req, "someone-else")
        assert exc.value.status_code == 403

    def test_double_submit_rejected(self, quiz):
        db, session, q1, q2 = quiz
        req = QuizSubmissionRequest(
            quiz_session_id=str(session.session_id),
            answers=[_answer(q1, "A"), _answer(q2, "B")],
        )
        process_quiz_submission(db, req, STUDENT)  # first submit ends the session
        with pytest.raises(HTTPException) as exc:
            process_quiz_submission(db, req, STUDENT)
        assert exc.value.status_code == 409


@pytest.mark.integration
class TestSpamGuard:
    def test_fast_correct_answer_skips_mastery_bump(self, quiz):
        db, session, q1, q2 = quiz
        fast_ms = settings.MINIMUM_GENUINE_TIME_MS - 1  # under the genuine-time floor
        req = QuizSubmissionRequest(
            quiz_session_id=str(session.session_id),
            answers=[_answer(q1, "A", ms=fast_ms), _answer(q2, "B", ms=fast_ms)],
        )
        process_quiz_submission(db, req, STUDENT)

        # The skill state was created but mastery must not have climbed from spam.
        state = (
            db.query(StudentSkillState)
            .filter_by(student_uid=STUDENT)
            .first()
        )
        assert state is not None
        assert state.mastery_probability == pytest.approx(0.01)  # unchanged
        # Spam clicks were counted on the session.
        assert session.consecutive_spam_clicks >= 1