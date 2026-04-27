from app.models.schemas import StudentProfile, StudentSkillState
from app.services.bkt.base import AdaptiveEvaluationStrategy

class IRTStrategy(AdaptiveEvaluationStrategy):
    """
    Item Response Theory mock strategy.
    Grades heavily based on inherent difficulty rather than Bayesian history.
    """
    def process_answer(self, profile: StudentProfile, skill: str, difficulty: int, correct: bool, response_time: float = 10.0, hints_used: int = 0) -> bool:
        profile.current_step += 1
        
        if skill not in profile.skills:
            profile.skills[skill] = StudentSkillState(mastery=50.0) # Assume 0-100 scale for IRT MVP
            
        data = profile.skills[skill]
        
        trigger_punishment = False
        if response_time < 2.0:
            profile.consecutive_spam_clicks += 1
            if profile.consecutive_spam_clicks >= 3:
                trigger_punishment = True
            return trigger_punishment
            
        profile.consecutive_spam_clicks = 0
        
        # Simple IRT mock logic
        if correct:
            # High difficulty correct = large jump
            data.mastery += (difficulty * 2.0)
        else:
            # Low difficulty wrong = large drop
            data.mastery -= ((6 - difficulty) * 2.0)
            
        # Clamp 0-100
        data.mastery = min(100.0, max(0.0, data.mastery))
        data.attempts += 1
        
        return trigger_punishment
