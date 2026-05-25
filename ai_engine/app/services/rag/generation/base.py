from abc import ABC, abstractmethod
from app.models.schemas import GenerateQuizResponse

class QuizGeneratorStrategy(ABC):
    """
    Abstract Base Class defining the interface for all LLM quiz generation strategies.
    All integrations must implement the generate method to return a standard Pydantic schema.
    """
    @abstractmethod
    def generate(self, topic_instructions: str, total_count: int, context: str, student_grade: str = "5th") -> GenerateQuizResponse:
        pass
