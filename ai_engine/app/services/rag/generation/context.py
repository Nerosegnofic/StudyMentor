from app.models.schemas import GenerateQuizResponse
from app.services.rag.generation.base import QuizGeneratorStrategy
from app.services.rag.generation.cohere_strategy import CohereStrategy
from app.core.exceptions import LLMGenerationError


class GeneratorContext:
    """
    Routes quiz generation requests to the active strategy (Gemini, Cohere, etc.).
    Performs a post-generation sanity check on the result.

    Raises:
        LLMGenerationError: Propagated from the strategy if all retries are
                            exhausted, OR raised here if the LLM returns an
                            empty questions list.
    """

    def __init__(self, strategy: QuizGeneratorStrategy = None):
        self._strategy = strategy if strategy else CohereStrategy()

    def set_strategy(self, strategy: QuizGeneratorStrategy):
        """Allows dynamically switching the strategy at runtime."""
        self._strategy = strategy

    def execute_generation(
        self,
        topic_instructions: str,
        total_count: int,
        context: str,
        student_grade: str = "5th",
        variance_block: str = "",
    ) -> GenerateQuizResponse:
        # LLMGenerationError propagates up — the controller handles it
        response = self._strategy.generate(
            topic_instructions=topic_instructions,
            total_count=total_count,
            context=context,
            student_grade=student_grade,
            variance_block=variance_block,
        )

        # Post-generation sanity check: an empty list means the LLM
        # produced structurally valid JSON but with no actual content.
        if not response or not response.questions:
            raise LLMGenerationError(
                "LLM returned a valid response structure but with an empty questions list."
            )

        if len(response.questions) < total_count:
            print(
                f"[GeneratorContext] Warning: LLM returned {len(response.questions)} questions "
                f"but {total_count} were requested. Proceeding with available questions.",
                flush=True,
            )

        return response
