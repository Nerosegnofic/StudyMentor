"""
API tests for the analytics endpoints (FastAPI TestClient).

Auth/DB are overridden by the ``client`` fixture. These assert auth gating,
JSON shape, and (re-establishing the deleted ``test_subject_cleanup.py``) the
subject-deletion contract: a user-owned custom subject can be deleted, a global
subject cannot (404, since the query filters ``is_global == False``), and a
missing subject 404s.
"""
import pytest

from app.main import app
from app.core.auth import get_current_user
from tests.conftest import make_subject, make_skill, make_skill_state, TEST_UID


@pytest.mark.api
class TestAnalyticsAuth:
    def test_subjects_requires_auth(self, client):
        app.dependency_overrides.pop(get_current_user, None)
        try:
            resp = client.get("/api/v1/analytics/subjects")
        finally:
            app.dependency_overrides[get_current_user] = lambda: TEST_UID
        assert resp.status_code in (401, 403)


@pytest.mark.api
class TestListSubjects:
    def test_lists_owned_excludes_others_and_unadded_globals(self, client, db_session):
        # Contract (see route): the parent's list = owned subjects + ADDED globals.
        # Un-added globals belong to the Add-Subjects catalog, not this list.
        make_subject(db_session, name="Math", is_global=True)  # global, not added
        make_subject(db_session, name="Astronomy", is_global=False, student_uid=TEST_UID)
        make_subject(db_session, name="Hidden", is_global=False, student_uid="other-student")
        db_session.flush()

        resp = client.get("/api/v1/analytics/subjects")
        assert resp.status_code == 200
        names = {s["name"] for s in resp.json()}
        assert "Astronomy" in names      # owned by the authenticated student
        assert "Hidden" not in names     # owned by someone else
        assert "Math" not in names       # un-added global -> excluded from this list

    def test_response_has_expected_shape(self, client, db_session):
        make_subject(db_session, name="Astronomy", is_global=False, student_uid=TEST_UID)
        db_session.flush()
        resp = client.get("/api/v1/analytics/subjects")
        assert resp.status_code == 200
        entry = next(s for s in resp.json() if s["name"] == "Astronomy")
        for key in ("subject_id", "name", "average_mastery", "total_skills",
                    "mastered_skills", "is_global", "is_selected"):
            assert key in entry


@pytest.mark.api
class TestDeleteSubject:
    def test_delete_owned_subject_succeeds(self, client, db_session):
        make_subject(db_session, name="Astronomy", is_global=False, student_uid=TEST_UID)
        db_session.flush()
        resp = client.delete(
            "/api/v1/analytics/subjects/astronomy",
            params={"student_uid": TEST_UID},
        )
        assert resp.status_code == 200
        assert resp.json() == {"deleted": "astronomy"}

    def test_delete_global_subject_not_allowed(self, client, db_session):
        # Global subjects are excluded by the is_global==False filter -> 404.
        make_subject(db_session, name="Math", is_global=True)
        db_session.flush()
        resp = client.delete(
            "/api/v1/analytics/subjects/math",
            params={"student_uid": TEST_UID},
        )
        assert resp.status_code == 404

    def test_delete_missing_subject_404(self, client, db_session):
        resp = client.delete(
            "/api/v1/analytics/subjects/does-not-exist",
            params={"student_uid": TEST_UID},
        )
        assert resp.status_code == 404