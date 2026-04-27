import math
from typing import Tuple
from app.models.schemas import StudentProfile, StudentSkillState
from app.services.bkt.config import BKTConfig
from app.services.bkt.base import AdaptiveEvaluationStrategy

class BKTStrategy(AdaptiveEvaluationStrategy):
    def __init__(self, config=None):
        self.cfg = config if config else BKTConfig()
        self.SPAM_THRESHOLD = 3

    def clamp(self, x: float) -> float:
        return min(self.cfg.max_prob, max(self.cfg.min_prob, x))

    def adjust_parameters(self, difficulty: int, response_time: float) -> Tuple[float, float]:
        delta = difficulty - 3
        guess = self.cfg.base_guess * math.exp(-0.40 * delta)
        slip = self.cfg.base_slip * math.exp(+0.30 * delta)

        if response_time < 30:
            guess *= 0.7
            slip *= 1.5
        elif response_time > 120:
            guess *= 1.3
            slip *= 0.8

        return self.clamp(guess), self.clamp(slip)

    def bayesian_update(self, mastery: float, correct: bool, guess: float, slip: float, learn_rate: float) -> float:
        if correct:
            numerator = mastery * (1 - slip)
            denominator = numerator + (1 - mastery) * guess
        else:
            numerator = mastery * slip
            denominator = numerator + (1 - mastery) * (1 - guess)

        knew_prob = numerator / denominator
        new_mastery = knew_prob + (1 - knew_prob) * learn_rate
        return self.clamp(new_mastery)

    def process_answer(self, profile: StudentProfile, skill: str, difficulty: int, correct: bool, response_time: float = 10.0, hints_used: int = 0) -> bool:
        profile.current_step += 1
        
        if skill not in profile.skills:
            profile.skills[skill] = StudentSkillState()
            
        data = profile.skills[skill]

        old_mastery = data.mastery
        guess, slip = self.adjust_parameters(difficulty, response_time)
        effective_quality = max(0.1, 1.0 - (hints_used * 0.3))
        
        trigger_punishment = False 
        MINIMUM_READ_TIME = 2.0 
        
        if response_time < MINIMUM_READ_TIME:
            profile.consecutive_spam_clicks += 1
            effective_quality = 0.0
            slip = 0.80 
            
            if profile.consecutive_spam_clicks >= self.SPAM_THRESHOLD:
                trigger_punishment = True
        else:
            profile.consecutive_spam_clicks = 0

        updated = self.bayesian_update(old_mastery, correct, guess, slip, data.learn_rate)
        new_mastery = old_mastery + effective_quality * (updated - old_mastery)
        
        data.mastery = self.clamp(new_mastery)
        data.attempts += 1
        data.last_seen_step = profile.current_step

        return trigger_punishment
