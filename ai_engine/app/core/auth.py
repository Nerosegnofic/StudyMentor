import os
from fastapi import Request, HTTPException, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
import firebase_admin
from firebase_admin import auth, credentials

# Initialize Firebase Admin
# In production, ensure the FIREBASE_SERVICE_ACCOUNT_JSON environment variable is set.
# If not set, it might use Application Default Credentials.
try:
    if not firebase_admin._apps:
        if os.environ.get("FIREBASE_SERVICE_ACCOUNT_JSON"):
            cred = credentials.Certificate(os.environ.get("FIREBASE_SERVICE_ACCOUNT_JSON"))
            firebase_admin.initialize_app(cred)
        else:
            firebase_admin.initialize_app()
except Exception as e:
    print(f"Firebase Admin initialization warning: {e}")

security = HTTPBearer()

def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)) -> str:
    """
    Validates the Firebase JWT token from the Authorization header.
    Returns the Firebase user UID as a string.
    """
    token = credentials.credentials
    try:
        decoded_token = auth.verify_id_token(token)
        uid = decoded_token.get("uid")
        if not uid:
            raise HTTPException(status_code=401, detail="Invalid Firebase Token: No UID found.")
        return uid
    except auth.ExpiredIdTokenError:
        raise HTTPException(status_code=401, detail="Firebase Token has expired.")
    except Exception as e:
        # Generic catch for dev environments if needed, but strict in prod
        raise HTTPException(status_code=401, detail=f"Invalid authentication credentials: {str(e)}")

def get_current_user_optional(request: Request) -> str | None:
    """
    Optional authentication for endpoints that can be public but track users if logged in.
    """
    auth_header = request.headers.get("Authorization")
    if not auth_header or not auth_header.startswith("Bearer "):
        return None
    token = auth_header.split(" ")[1]
    try:
        decoded_token = auth.verify_id_token(token)
        return decoded_token.get("uid")
    except Exception:
        return None
