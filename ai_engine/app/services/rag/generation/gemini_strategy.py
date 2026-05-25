from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_core.exceptions import OutputParserException
from pydantic import ValidationError
from tenacity import (
    Retrying,
    stop_after_attempt,
    wait_exponential,
    retry_if_exception_type,
)

from app.models.schemas import GenerateQuizResponse
from app.core.prompts import QUIZ_GENERATION_PROMPT
from app.core.config import settings
from app.core.exceptions import LLMGenerationError
from app.services.rag.generation.base import QuizGeneratorStrategy


class GeminiStrategy(QuizGeneratorStrategy):
    """
    Quiz generation using Google Gemini (gemini-2.5-flash).

    Resilience:
        - Retries up to LLM_MAX_RETRIES times with exponential backoff.
        - Retries on OutputParserException (schema mismatch) and ValidationError
          (Pydantic validation failure on structured output).
        - Raises LLMGenerationError after all retries are exhausted so the
          controller can trigger the quiz bank fallback cleanly.
    """

    def generate(
        self,
        topic_instructions: str,
        total_count: int,
        context: str,
        student_grade: str = "5th",
    ) -> GenerateQuizResponse:
        llm = ChatGoogleGenerativeAI(
            google_api_key=settings.GEMINI_API_KEY,
            model=settings.GEMINI_MODEL,
            temperature=0.2,
        )
        structured_llm = llm.with_structured_output(GenerateQuizResponse)
        chain = QUIZ_GENERATION_PROMPT | structured_llm
        inputs = {
            "topic_instructions": topic_instructions,
            "total_count": total_count,
            "context": context,
            "student_grade": student_grade,
        }

        last_exc: Exception = None
        try:
            for attempt in Retrying(
                stop=stop_after_attempt(settings.LLM_MAX_RETRIES),
                wait=wait_exponential(multiplier=1, min=2, max=20),
                retry=retry_if_exception_type((OutputParserException, ValidationError, Exception)),
                reraise=True,
            ):
                with attempt:
                    attempt_num = attempt.retry_state.attempt_number
                    print(
                        f"[GeminiStrategy] Invoking LLM (attempt {attempt_num}/{settings.LLM_MAX_RETRIES})...",
                        flush=True,
                    )
                    return chain.invoke(inputs)
        except Exception as exc:
            last_exc = exc

        raise LLMGenerationError(
            f"Gemini quiz generation failed after {settings.LLM_MAX_RETRIES} attempt(s). "
            f"Last error: {type(last_exc).__name__}: {last_exc}"
        ) from last_exc
