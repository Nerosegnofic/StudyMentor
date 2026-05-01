from app.models.schemas import GenerateQuizResponse
from app.services.rag.generation.base import QuizGeneratorStrategy
from app.services.rag.generation.cohere_strategy import CohereStrategy

class GeneratorContext:
    """
    The Context class that routes requests to the active Generation Strategy.
    """
    def __init__(self, strategy: QuizGeneratorStrategy = None):
        # Default to Cohere Strategy if none is provided
        self._strategy = strategy if strategy else CohereStrategy()

    def set_strategy(self, strategy: QuizGeneratorStrategy):
        """Allows dynamically switching the strategy at runtime."""
        self._strategy = strategy

    def execute_generation(self, topic_instructions: str, total_count: int, context: str) -> GenerateQuizResponse:
        """
        Executes the current strategy's generate method and returns the formatted response.
        """
        return self._strategy.generate(
            topic_instructions=topic_instructions, 
            total_count=total_count, 
            context=context
        )
