import secrets

from fastapi import Depends, HTTPException
from fastapi.security import APIKeyHeader

from app.core.config import settings

# Declaring this as an APIKeyHeader security scheme makes Swagger /docs render an
# "Authorize" box, so an operator can paste the admin key once and then use the
# multipart upload-global form directly from /docs.
_admin_key_header = APIKeyHeader(name="X-Admin-Key", auto_error=False)


def require_admin(provided_key: str = Depends(_admin_key_header)) -> bool:
    """
    Gate admin-only endpoints (e.g. publishing global curriculum) behind a static
    admin key sent in the `X-Admin-Key` header, compared in constant time.

    Returns 403 when ADMIN_API_KEY is unset (feature disabled) or the key does not
    match — never reveals which of the two it was.
    """
    expected = settings.ADMIN_API_KEY
    if not expected or not provided_key or not secrets.compare_digest(provided_key, expected):
        raise HTTPException(status_code=403, detail="Admin privileges required.")
    return True
