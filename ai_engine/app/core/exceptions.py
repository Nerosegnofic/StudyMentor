"""
Custom application exceptions for the StudyMentor AI Engine.

Using custom exceptions instead of generic Python exceptions allows:
  1. Precise error handling in controllers — catch a specific error, return
     a specific HTTP status code (403, 404, 503, etc.).
  2. Clean separation between *expected* failures (LLM down, bank empty)
     and *unexpected* bugs (which bubble up to the global 500 handler).
  3. The global exception handler in main.py can safely log everything
     without leaking internal detail to HTTP responses.
"""


class LLMGenerationError(Exception):
    """
    Raised by GeminiStrategy (or any LLM strategy) when all retry attempts
    are exhausted and no valid GenerateQuizResponse could be produced.
    Maps to HTTP 503 Service Unavailable.
    """


class QuizBankInsufficientError(Exception):
    """
    Raised by quiz_bank_service when the student's previously answered
    questions cannot cover the minimum required fraction of the quiz
    (QUIZ_BANK_MIN_COVERAGE). This happens for new students or when all
    eligible questions were answered too recently.
    Maps to HTTP 503 Service Unavailable.
    """


class TenantViolationError(PermissionError):
    """
    Raised when a data access attempt crosses tenant (firebase_uid)
    boundaries — e.g., a student trying to delete another student's document.
    Maps to HTTP 403 Forbidden.
    """


class InsufficientContextError(ValueError):
    """
    Raised by the RAG retrieval layer when no usable curriculum context
    could be found for the requested topics and subject after all safe
    fallback tiers have been exhausted.
    Maps to HTTP 404 Not Found (no curriculum data available).
    """
