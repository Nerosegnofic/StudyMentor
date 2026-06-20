"""
API tests for the quiz endpoints (FastAPI TestClient).

Auth and DB are overridden by the ``client`` fixture (see conftest). The LLM-bound
``generate_quiz_for_student`` is mocked — these tests assert HTTP wiring, auth
gating, request validation, and the submission security guards at the HTTP layer.
The adaptive-learning math itself is covered by the service/integration tests.
"""
from unittest.mock import patch

import pytest

from app.main import app
from app.core.auth import get_current_user
from tests.conftest import (
    seed_levels, make_subject, make_skill, make_quiz_session, make_question, TEST_UID,
)

GEN = "app.controllers.routes_quizzes.generate_quiz_for_student"


@pytest.mark.api
class TestGenerateQuiz:
    def test_generate_returns_service_payload(self, client):
        # A fake matching the GenerateQuizResponse contract (all required fields).
        fake = {
            "quiz_session_id": "sess-1",
            "selected_subject_id": 1,
            "selected_subject_name": "Math",
            "quiz_title": "Adaptive Practice",
            "questions": [],
        }
        with patch(GEN, return_value=fake):
            resp = client.post("/api/v1/quizzes/generate", json={"total_questions": 5})
        assert resp.status_code == 200
        body = resp.json()
        assert body["quiz_session_id"] == "sess-1"
        assert body["selected_subject_name"] == "Math"

    def test_generate_requires_auth(self, client):
        # Clear the auth override so the real get_current_user (HTTPBearer) runs:
        # with no Authorization header it must reject the request.
        app.dependency_overrides.pop(get_current_user, None)
        try:
            resp = client.post("/api/v1/quizzes/generate", json={"total_questions": 5})
        finally:
            app.dependency_overrides[get_current_user] = lambda: TEST_UID
        assert resp.status_code in (401, 403)  # missing bearer -> unauthenticated


@pytest.mark.api
class TestSubmitQuiz:
    @pytest.fixture
    def quiz(self, db_session):
        seed_levels(db_session)
        subject = make_subject(db_session, name="Math")
        skill = make_skill(db_session, subject_id=subject.subject_id, name="Fractions")
        session = make_quiz_session(db_session, student_uid=TEST_UID,
                                    subject_id=subject.subject_id, total_questions=2)
        q1 = make_question(db_session, skill_id=skill.skill_id,
                           session_id=session.session_id, correct_answer="A")
        q2 = make_question(db_session, skill_id=skill.skill_id,
                           session_id=session.session_id, correct_answer="B")
        db_session.flush()
        return session, q1, q2

    def _payload(self, session, answers):
        return {"quiz_session_id": str(session.session_id), "answers": answers}

    def test_submit_scores_correctly(self, client, quiz):
        session, q1, q2 = quiz
        body = self._payload(session, [
            {"question_id": str(q1.question_id), "selected_option": "A", "time_taken_ms": 10000},
            {"question_id": str(q2.question_id), "selected_option": "B", "time_taken_ms": 10000},
        ])
        resp = client.post("/api/v1/quizzes/submit", json=body)
        assert resp.status_code == 200
        assert resp.json()["score"] == 100.0

    def test_submit_grades_server_side(self, client, quiz):
        """A client cannot make a wrong answer count — grading uses stored answers."""
        session, q1, q2 = quiz
        body = self._payload(session, [
            {"question_id": str(q1.question_id), "selected_option": "WRONG", "time_taken_ms": 10000},
            {"question_id": str(q2.question_id), "selected_option": "B", "time_taken_ms": 10000},
        ])
        resp = client.post("/api/v1/quizzes/submit", json=body)
        assert resp.status_code == 200
        assert resp.json()["score"] == 50.0

    def test_submit_rejects_wrong_answer_count(self, client, quiz):
        session, q1, q2 = quiz
        body = self._payload(session, [
            {"question_id": str(q1.question_id), "selected_option": "A", "time_taken_ms": 10000},
        ])
        resp = client.post("/api/v1/quizzes/submit", json=body)
        assert resp.status_code == 400

    def test_submit_rejects_foreign_question(self, client, quiz):
        import uuid
        session, q1, q2 = quiz
        body = self._payload(session, [
            {"question_id": str(q1.question_id), "selected_option": "A", "time_taken_ms": 10000},
            {"question_id": str(uuid.uuid4()), "selected_option": "A", "time_taken_ms": 10000},
        ])
        resp = client.post("/api/v1/quizzes/submit", json=body)
        assert resp.status_code == 400

    def test_submit_forbids_other_students_session(self, client, db_session):
        # A session owned by a DIFFERENT student than the authenticated TEST_UID.
        seed_levels(db_session)
        subject = make_subject(db_session, name="Math")
        skill = make_skill(db_session, subject_id=subject.subject_id, name="Fractions")
        session = make_quiz_session(db_session, student_uid="another-student",
                                    subject_id=subject.subject_id, total_questions=1)
        q1 = make_question(db_session, skill_id=skill.skill_id,
                           session_id=session.session_id, correct_answer="A")
        db_session.flush()
        body = {"quiz_session_id": str(session.session_id),
                "answers": [{"question_id": str(q1.question_id), "selected_option": "A"}]}
        resp = client.post("/api/v1/quizzes/submit", json=body)
        assert resp.status_code == 403