from abc import ABC, abstractmethod
from app.models.schemas import StudentProfile

class AdaptiveEvaluationStrategy(ABC):
    @abstractmethod
    def process_answer(self, profile: StudentProfile, skill: str, difficulty: int, correct: bool, response_time: float = 10.0, hints_used: int = 0) -> bool:
        """
        Evaluates a student's answer and updates their internal cognitive profile.
        Returns `True` if a penalty threshold (e.g. rapid guessing limit) was triggered.
        """
        pass
