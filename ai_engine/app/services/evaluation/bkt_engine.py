import math
from typing import Tuple
from app.models.domain import StudentBKTProfile, StudentSkillState
from app.services.evaluation.config import BKTConfig

class BKTEngine:
    """
    Bayesian Knowledge Tracing (BKT) Engine.
    Tracks a student's mastery probability over time as they practice.
    Focuses on the "When": deciding when a student has learned a skill.
    """
    def __init__(self, config=None):
        self.cfg = config if config else BKTConfig()
        self.SPAM_THRESHOLD = 3

    def _clamp(self, x: float) -> float:
        return min(self.cfg.max_prob, max(self.cfg.min_prob, x))

    def _adjust_parameters(self, difficulty: int, response_time: float) -> Tuple[float, float]:
        """
        Adjusts guess and slip rates based on item difficulty and response time.
        """
        delta = difficulty - 3
        guess = self.cfg.base_guess * math.exp(-0.40 * delta)
        slip = self.cfg.base_slip * math.exp(+0.30 * delta)

        if response_time < 30:
            guess *= 0.7
            slip *= 1.5
        elif response_time > 120:
            guess *= 1.3
            slip *= 0.8

        return self._clamp(guess), self._clamp(slip)

    def _bayesian_update(self, mastery: float, correct: bool, guess: float, slip: float, learn_rate: float) -> float:
        """
        Standard BKT update using Hidden Markov Model logic.
        """
        if correct:
            numerator = mastery * (1 - slip)
            denominator = numerator + (1 - mastery) * guess
        else:
            numerator = mastery * slip
            denominator = numerator + (1 - mastery) * (1 - guess)

        knew_prob = numerator / denominator
        new_mastery = knew_prob + (1 - knew_prob) * learn_rate
        return self._clamp(new_mastery)

    def update_mastery(
        self, 
        profile: StudentBKTProfile, 
        skill_state: StudentSkillState, 
        skill_name: str, 
        difficulty: int, 
        correct: bool, 
        response_time: float = 10.0, 
        hints_used: int = 0
    ) -> bool:
        """
        Main entry point for updating a student's cognitive state after an answer.
        """
        profile.current_step += 1
        
        old_mastery = skill_state.mastery_probability
        guess, slip = self._adjust_parameters(difficulty, response_time)
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

        # Assuming skill relationship is loaded, fallback to default 0.10 if not
        learn_rate = skill_state.skill.default_learn_rate if skill_state.skill else 0.10

        updated = self._bayesian_update(old_mastery, correct, guess, slip, learn_rate)
        new_mastery = old_mastery + effective_quality * (updated - old_mastery)
        
        skill_state.mastery_probability = self._clamp(new_mastery)
        if skill_state.mastery_probability >= 0.95:
            skill_state.is_mastered = True
            
        skill_state.attempts += 1
        # Reusing attempts as last_seen_step for simplicity since last_seen_step is no longer explicitly on state, 
        # or we don't need it. The profile has current_step.

        return trigger_punishment
