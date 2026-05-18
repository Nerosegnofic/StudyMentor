from fastapi import Request
from slowapi import Limiter
from slowapi.util import get_remote_address

from app.core.auth import get_current_user_optional

def _get_uid_or_ip(request: Request) -> str:
    """
    Rate limit key function. Extracts the Firebase UID from the JWT so rate
    limits are per-user (not per-IP, which can be bypassed with VPNs).
    Falls back to IP address for unauthenticated requests.
    """
    return get_current_user_optional(request) or get_remote_address(request)

limiter = Limiter(key_func=_get_uid_or_ip)
