from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.exceptions import OutputParserException
from pydantic import ValidationError
from tenacity import (
    Retrying,
    stop_after_attempt,
    wait_exponential,
    retry_if_exception_type,
)

from app.models.schemas import GenerateQuizResponse
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
        quiz_prompt: ChatPromptTemplate,
        topic_instructions: str,
        total_count: int,
        context: str,
        student_grade: str = "5th",
        subject_name: str = "",
        variance_block: str = "",
    ) -> GenerateQuizResponse:
        inputs = {
            "topic_instructions": topic_instructions,
            "total_count": total_count,
            "context": context,
            "student_grade": student_grade,
            "subject_name": subject_name,
            "variance_block": variance_block,
        }

        max_attempts = settings.LLM_MAX_RETRIES
        has_fallback = bool(getattr(settings, "GEMINI_FALLBACK_MODEL", None))
        if has_fallback:
            max_attempts += settings.LLM_MAX_RETRIES

        last_exc: Exception = None
        try:
            for attempt in Retrying(
                stop=stop_after_attempt(max_attempts),
                wait=wait_exponential(multiplier=1, min=2, max=20),
                retry=retry_if_exception_type((OutputParserException, ValidationError, Exception)),
                reraise=True,
            ):
                with attempt:
                    attempt_num = attempt.retry_state.attempt_number
                    model_to_use = settings.GEMINI_MODEL
                    
                    if attempt_num > settings.LLM_MAX_RETRIES and has_fallback:
                        model_to_use = settings.GEMINI_FALLBACK_MODEL
                        print(f"[GeminiStrategy] Attempt {attempt_num}/{max_attempts}: using fallback model {model_to_use}...", flush=True)
                    else:
                        print(f"[GeminiStrategy] Invoking LLM {model_to_use} (attempt {attempt_num}/{max_attempts})...", flush=True)

                    llm = ChatGoogleGenerativeAI(
                        google_api_key=settings.GEMINI_API_KEY,
                        model=model_to_use,
                        temperature=0.7,
                    )
                    structured_llm = llm.with_structured_output(GenerateQuizResponse)
                    chain = quiz_prompt | structured_llm

                    return chain.invoke(inputs)
        except Exception as exc:
            last_exc = exc

        raise LLMGenerationError(
            f"Gemini quiz generation failed after {max_attempts} attempt(s). "
            f"Last error: {type(last_exc).__name__}: {last_exc}"
        ) from last_exc
