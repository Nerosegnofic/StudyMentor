import os
from fastapi import Request, HTTPException, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
import firebase_admin
from firebase_admin import auth, credentials
from app.core.config import settings

def init_firebase():
    """
    Initializes the Firebase Admin SDK. 
    Called during FastAPI startup to ensure the default app is ready.
    """
    try:
        if not firebase_admin._apps:
            if settings.FIREBASE_SERVICE_ACCOUNT_JSON:
                print(f"DEBUG: Initializing Firebase with Service Account: {settings.FIREBASE_SERVICE_ACCOUNT_JSON}")
                cred = credentials.Certificate(settings.FIREBASE_SERVICE_ACCOUNT_JSON)
                firebase_admin.initialize_app(cred, options={'projectId': settings.FIREBASE_PROJECT_ID})
                print(f"DEBUG: Firebase initialized with Service Account. Overrode Project ID to: {settings.FIREBASE_PROJECT_ID}")
            else:
                print(f"DEBUG: Falling back to Project ID: {settings.FIREBASE_PROJECT_ID}")
                firebase_admin.initialize_app(options={'projectId': settings.FIREBASE_PROJECT_ID})
                print("DEBUG: Firebase initialized with Project ID fallback.")
        else:
            print(f"DEBUG: Firebase already initialized: {firebase_admin._apps}")
    except Exception as e:
        # A Firebase init failure is unrecoverable — all authenticated endpoints
        # will fail. Raising here prevents the server from starting in a broken state.
        raise RuntimeError(
            f"Firebase Admin SDK failed to initialize. Server cannot start. Reason: {e}"
        ) from e


security = HTTPBearer()

def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)) -> str:
    """
    Validates the Firebase JWT token from the Authorization header.
    
    HOW IT WORKS:
    1. FastAPI's HTTPBearer extracts the "Bearer <token>" string from the request headers.
    2. We pass this token to the Firebase Admin SDK (auth.verify_id_token).
    3. The SDK performs a cryptographic check:
       - Is the token's signature valid? (Did it actually come from Firebase?)
       - Is the token expired? (Tokens are usually valid for 1 hour)
       - Is the "aud" (audience) correct for our project?
    4. If valid, the SDK returns a dictionary (claims) containing the user's details.
    5. We extract the "uid" (the unique, immutable ID for that student in Firebase).
    6. We return this UID to be injected into the route handlers.
    """
    token = credentials.credentials
    try:
        # This call handles the cryptographic verification
        decoded_token = auth.verify_id_token(token)
        uid = decoded_token.get("uid")
        if not uid:
            raise HTTPException(status_code=401, detail="Invalid Firebase Token: No UID found.")
        return uid
    except auth.ExpiredIdTokenError:
        raise HTTPException(status_code=401, detail="Firebase token has expired. Please sign in again.")
    except Exception as e:
        # Log the actual error internally but DO NOT expose it in the HTTP response.
        # Token details, internal library errors, or project IDs must not leak to clients.
        print(f"[Auth] Token verification failed: {type(e).__name__}: {e}")
        raise HTTPException(status_code=401, detail="Invalid or expired authentication token.")

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
