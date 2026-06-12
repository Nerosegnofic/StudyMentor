"""
Pydantic schemas for gamification API endpoints.
"""
from pydantic import BaseModel, Field
from typing import Optional


class GamificationProfileResponse(BaseModel):
    """GET /student/{id}/gamification"""
    student_uid: str
    xp_total: int
    coins_total: int
    current_level: int
    level_name: str
    next_level_xp: Optional[int] = None
    progress_percent: float
    current_streak: int = 0
    longest_streak: int = 0
    last_quiz_date: Optional[str] = None
    next_milestone: Optional[int] = None
    next_milestone_days_away: Optional[int] = None
    total_questions_answered: int = 0


class LevelSchema(BaseModel):
    """Single level entry for GET /levels"""
    level_number: int
    level_name: str
    xp_required: int
    unlock_description: Optional[str] = None


class LevelsResponse(BaseModel):
    """GET /levels"""
    levels: list[LevelSchema]


class DailyLoginRequest(BaseModel):
    client_local_date: Optional[str] = Field(None, description="Local date from client (YYYY-MM-DD)")


class DailyLoginResponse(BaseModel):
    """POST /student/{id}/daily-login"""
    awarded: bool
    coins_earned: int = 0
    coins_total: int = 0
    current_streak: int = 0


class SpendCoinsRequest(BaseModel):
    """Payload for POST /student/{id}/spend-coins"""
    amount: int
    reason: str


class SpendCoinsResponse(BaseModel):
    """Response for POST /student/{id}/spend-coins"""
    coins_total: int
    amount_spent: int


class QuizRewardsSummary(BaseModel):
    """Embedded in the quiz submission response."""
    xp_earned: int
    coins_earned: int
    xp_total: int
    coins_total: int
    old_level: int
    new_level: int
    did_level_up: bool
