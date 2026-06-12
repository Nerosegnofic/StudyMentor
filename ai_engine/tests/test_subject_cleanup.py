from fastapi.testclient import TestClient
from unittest.mock import patch, MagicMock
from app.main import app

client = TestClient(app)

@patch("app.controllers.routes_analytics.get_current_user_uid")
@patch("app.controllers.routes_analytics.SessionLocal")
def test_delete_subject_success(mock_session_local, mock_get_current_user):
    # Mock auth
    mock_get_current_user.return_value = "student_123"
    
    # Mock DB session
    mock_db = MagicMock()
    mock_session_local.return_value = mock_db
    
    # Mock subject query
    mock_subject = MagicMock()
    mock_subject.is_global = False
    mock_subject.id = "sub_456"
    mock_db.query().filter().first.return_value = mock_subject
    
    # Run request
    response = client.delete("/analytics/subjects/astronomy")
    
    assert response.status_code == 200
    assert response.json() == {"status": "success", "message": "Subject astronomy deleted successfully."}
    
    # Ensure it didn't commit without executing vector cleanup
    mock_db.execute.assert_called()
    mock_db.delete.assert_called_once_with(mock_subject)
    mock_db.commit.assert_called()


@patch("app.controllers.routes_analytics.get_current_user_uid")
@patch("app.controllers.routes_analytics.SessionLocal")
def test_delete_subject_global_forbidden(mock_session_local, mock_get_current_user):
    mock_get_current_user.return_value = "student_123"
    
    mock_db = MagicMock()
    mock_session_local.return_value = mock_db
    
    # Mock subject query returning a global subject
    mock_subject = MagicMock()
    mock_subject.is_global = True
    mock_db.query().filter().first.return_value = mock_subject
    
    # Try deleting a global subject like math
    response = client.delete("/analytics/subjects/math")
    
    assert response.status_code == 403
    assert "Cannot delete global subjects" in response.json()["detail"]
    
    # Ensure delete and commit were NOT called
    mock_db.delete.assert_not_called()
    mock_db.commit.assert_not_called()


@patch("app.controllers.routes_analytics.get_current_user_uid")
@patch("app.controllers.routes_analytics.SessionLocal")
def test_delete_subject_not_found(mock_session_local, mock_get_current_user):
    mock_get_current_user.return_value = "student_123"
    
    mock_db = MagicMock()
    mock_session_local.return_value = mock_db
    
    # Mock subject query returning None
    mock_db.query().filter().first.return_value = None
    
    response = client.delete("/analytics/subjects/unknown_subject")
    
    assert response.status_code == 404
    assert "Subject unknown_subject not found" in response.json()["detail"]
    
    mock_db.delete.assert_not_called()
