import math
from datetime import datetime
from typing import Tuple
from app.models.domain import StudentSkillState
from app.services.evaluation.config import BKTConfig

class BKTEngine:
    """
    Bayesian Knowledge Tracing (BKT) Engine.
    Tracks a student's mastery probability over time as they practice.
    Focuses on the "When": deciding when a student has learned a skill.
    """
    def __init__(self, config=None):
        self.cfg = config if config else BKTConfig()

    def _clamp(self, x: float) -> float:
        return min(self.cfg.max_prob, max(self.cfg.min_prob, x))

    def _adjust_parameters(self, difficulty: int, response_time: float) -> Tuple[float, float]:
        """
        Adjusts guess and slip rates based on item difficulty and response time.
        """
        delta = difficulty - 3
        guess = self.cfg.base_guess * math.exp(-self.cfg.difficulty_guess_sensitivity * delta)
        slip = self.cfg.base_slip * math.exp(+self.cfg.difficulty_slip_sensitivity * delta)

        if response_time < self.cfg.rush_seconds:
            guess *= 0.7
            slip *= 1.5
        elif response_time > self.cfg.slow_seconds:
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
        skill_state: StudentSkillState, 
        skill_name: str, 
        difficulty: int, 
        correct: bool, 
        response_time: float = 10.0, 
        hints_used: int = 0,
        current_session_spam_count: int = 0
    ) -> Tuple[bool, int]:
        """
        Main entry point for updating a student's cognitive state after an answer.
        Returns (trigger_punishment, updated_spam_count).
        """
        # Apply time-based forgetting before the Bayesian update so skills decay
        # when a student returns after a break.
        if skill_state.last_practiced:
            days_elapsed = (datetime.utcnow() - skill_state.last_practiced).total_seconds() / 86400.0
            if days_elapsed > 0:
                decayed = skill_state.mastery_probability * (self.cfg.forgetting_rate ** days_elapsed)
                skill_state.mastery_probability = self._clamp(decayed)

        old_mastery = skill_state.mastery_probability
        guess, slip = self._adjust_parameters(difficulty, response_time)
        effective_quality = max(self.cfg.min_quality, 1.0 - (hints_used * self.cfg.hint_penalty))

        trigger_punishment = False
        updated_spam_count = current_session_spam_count

        if response_time < self.cfg.min_read_seconds:
            updated_spam_count += 1
            effective_quality = 0.0
            slip = 0.80

            if updated_spam_count >= self.cfg.spam_threshold:
                trigger_punishment = True
        else:
            updated_spam_count = 0

        learn_rate = skill_state.skill.default_learn_rate if skill_state.skill else self.cfg.default_learn_rate

        # Apply only a fraction (mastery_step) of the Bayesian jump each question so
        # mastery grows and declines gradually instead of swinging ±25-35 pts at once.
        updated = self._bayesian_update(old_mastery, correct, guess, slip, learn_rate)
        new_mastery = old_mastery + effective_quality * self.cfg.mastery_step * (updated - old_mastery)

        skill_state.mastery_probability = self._clamp(new_mastery)
        skill_state.attempts += 1
        skill_state.last_practiced = datetime.utcnow()

        # Require a minimum number of answered questions before declaring a skill
        # mastered, so a lucky streak doesn't trigger the mastered badge.
        if (
            skill_state.mastery_probability >= self.cfg.mastered_threshold
            and skill_state.attempts >= self.cfg.mastered_min_attempts
        ):
            skill_state.is_mastered = True

        return trigger_punishment, updated_spam_count
