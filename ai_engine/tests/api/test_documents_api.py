"""
API tests for the document upload endpoint (FastAPI TestClient).

These assert the upload *validation* guards (MIME type, extension, size) at the
HTTP layer without running the real ingestion pipeline — the background task is
never triggered because validation fails first, and a valid upload's ingestion is
mocked. Auth/DB are overridden by the ``client`` fixture.
"""
import pytest

from app.core.config import settings


@pytest.mark.api
class TestUploadValidation:
    def test_non_pdf_mime_rejected(self, client):
        resp = client.post(
            "/api/v1/documents/upload",
            files={"file": ("notes.txt", b"hello", "text/plain")},
            data={"subject_name": "Math"},
        )
        assert resp.status_code == 415  # unsupported media type

    def test_pdf_mime_but_wrong_extension_rejected(self, client):
        # Correct MIME but a non-.pdf filename trips the secondary extension guard.
        resp = client.post(
            "/api/v1/documents/upload",
            files={"file": ("notes.txt", b"%PDF-1.4 fake", "application/pdf")},
            data={"subject_name": "Math"},
        )
        assert resp.status_code == 400

    def test_oversize_pdf_rejected(self, client):
        # One byte over the configured limit.
        too_big = b"%PDF-1.4" + b"0" * (settings.MAX_UPLOAD_SIZE_MB * 1024 * 1024 + 1)
        resp = client.post(
            "/api/v1/documents/upload",
            files={"file": ("book.pdf", too_big, "application/pdf")},
            data={"subject_name": "Math"},
        )
        assert resp.status_code == 413  # payload too large