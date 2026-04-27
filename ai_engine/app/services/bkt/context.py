from app.models.schemas import StudentProfile
from app.services.bkt.base import AdaptiveEvaluationStrategy
from app.services.bkt.bkt_strategy import BKTStrategy

class EvaluationContext:
    def __init__(self, strategy: AdaptiveEvaluationStrategy = None):
        self._strategy = strategy if strategy else BKTStrategy()

    def set_strategy(self, strategy: AdaptiveEvaluationStrategy):
        self._strategy = strategy

    def execute_evaluation(self, profile: StudentProfile, skill: str, difficulty: int, correct: bool, response_time: float = 10.0, hints_used: int = 0) -> bool:
        return self._strategy.process_answer(
            profile=profile,
            skill=skill,
            difficulty=difficulty,
            correct=correct,
            response_time=response_time,
            hints_used=hints_used
        )
