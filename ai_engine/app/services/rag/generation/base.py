from abc import ABC, abstractmethod
from langchain_core.prompts import ChatPromptTemplate
from app.models.schemas import GenerateQuizResponse

class QuizGeneratorStrategy(ABC):
    """
    Abstract Base Class defining the interface for all LLM quiz generation strategies.
    All integrations must implement the generate method to return a standard Pydantic schema.
    """
    @abstractmethod
    def generate(self, quiz_prompt: ChatPromptTemplate, topic_instructions: str, total_count: int, context: str, student_grade: str = "5th", subject_name: str = "", variance_block: str = "") -> GenerateQuizResponse:
        pass
