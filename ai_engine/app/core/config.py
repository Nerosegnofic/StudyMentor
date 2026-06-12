from pydantic_settings import BaseSettings, SettingsConfigDict
from typing import Optional
import os

BASE_DIR = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
ENV_FILE_PATH = os.path.join(BASE_DIR, ".env")

class Settings(BaseSettings):
    PROJECT_NAME: str = "AI Curriculum POC"
    VERSION: str = "0.1.0"

    # Environment variables from .env
    OPENAI_API_KEY: Optional[str] = None
    LLAMA_CLOUD_API_KEY: Optional[str] = None
    COHERE_API_KEY: Optional[str] = None
    GEMINI_API_KEY: Optional[str] = None
    POSTGRES_CONNECTION: Optional[str] = None
    FIREBASE_PROJECT_ID: str = "studymentor-2026"
    FIREBASE_SERVICE_ACCOUNT_JSON: Optional[str] = None

    # --- AI Model Configuration ---
    # Gemini Models:
    # - "gemini-2.5-flash" (Recommended default: fast, cheap, highly capable)
    # - "gemini-2.5-pro" (Better for complex logic, deeper reasoning, and complex parsing)
    GEMINI_MODEL: str = "gemini-3.5-flash"
    GEMINI_FALLBACK_MODEL: Optional[str] = "gemini-2.5-flash"

    # Cohere Models:
    # - "command-r-08-2024" (Current default)
    # - "command-r-plus" (Recommended for advanced multi-step tools & reasoning)
    COHERE_MODEL: str = "command-r-08-2024"

    # Cohere Embeddings:
    # - "embed-multilingual-v3.0" (Recommended: high-quality vector embeddings for Arabic)
    # - "embed-multilingual-light-v3.0" (Faster, smaller dimensions)
    COHERE_EMBEDDING_MODEL: str = "embed-multilingual-v3.0"

    # --- Guardrail Configuration ---
    # File Upload
    MAX_UPLOAD_SIZE_MB: int = 50

    # RAG Retrieval Quality
    # Cosine distance threshold: chunks with score > this value are too irrelevant to inject.
    # Range: 0.0 (identical) → 2.0 (opposite). 0.45 retains reasonably on-topic chunks.
    RETRIEVAL_SCORE_THRESHOLD: float = 0.55

    # Quiz Bank Fallback (used when LLM generation fails)
    # Minimum fraction of required questions the bank must cover before using it.
    QUIZ_BANK_MIN_COVERAGE: float = 0.60
    # Minimum days since a question was answered before it can be reused from the bank.
    QUIZ_BANK_MIN_AGE_DAYS: int = 7

    # LLM Resilience
    LLM_MAX_RETRIES: int = 3

    # Rate Limiting (slowapi format: "N/period" — e.g., "3/minute")
    QUIZ_GENERATE_RATE_LIMIT: str = "3/minute"

    # BKT Evaluation / Spam Detection
    # Minimum time in ms required for an answer to be considered genuine comprehension
    MINIMUM_GENUINE_TIME_MS: int = 2000

    model_config = SettingsConfigDict(env_file=ENV_FILE_PATH, extra="ignore")


settings = Settings()
