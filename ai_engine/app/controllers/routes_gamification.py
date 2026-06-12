"""
Gamification API routes.

Endpoints:
  GET  /gamification/student/{student_uid}/profile  → student's XP/coins/level
  GET  /gamification/levels                          → static level definitions
  POST /gamification/student/{student_uid}/daily-login → award daily login bonus
"""
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.auth import get_current_user
from app.models.schemas import (
    GamificationProfileResponse,
    LevelSchema,
    LevelsResponse,
    DailyLoginRequest,
    DailyLoginResponse,
    SpendCoinsRequest,
    SpendCoinsResponse,
)
from app.services.gamification import GamificationService
from app.repositories.gamification_repo import get_all_levels

router = APIRouter(prefix="/gamification", tags=["Gamification"])
gamification_service = GamificationService()


@router.get(
    "/student/{student_uid}/profile",
    response_model=GamificationProfileResponse,
)
def get_gamification_profile(
    student_uid: str,
    db: Session = Depends(get_db),
    _caller: str = Depends(get_current_user),
):
    """Return the student's full gamification profile."""
    profile = gamification_service.get_student_profile(db, student_uid)
    return GamificationProfileResponse(**profile)


@router.get("/levels", response_model=LevelsResponse)
def list_levels(
    db: Session = Depends(get_db),
    _caller: str = Depends(get_current_user),
):
    """Return all level definitions."""
    rows = get_all_levels(db)
    return LevelsResponse(
        levels=[
            LevelSchema(
                level_number=l.level_number,
                level_name=l.level_name,
                xp_required=l.xp_required,
                unlock_description=l.unlock_description,
            )
            for l in rows
        ]
    )


@router.post(
    "/student/{student_uid}/daily-login",
    response_model=DailyLoginResponse,
)
def daily_login(
    student_uid: str,
    req: DailyLoginRequest,
    db: Session = Depends(get_db),
    _caller: str = Depends(get_current_user),
):
    """Award the daily login bonus if not already awarded today."""
    result = gamification_service.check_daily_login(db, student_uid, req.client_local_date)
    if result is None:
        db.commit()
        return DailyLoginResponse(awarded=False)

    db.commit()
    return DailyLoginResponse(
        awarded=True,
        coins_earned=result["coins_earned"],
        coins_total=result["coins_total"],
        current_streak=result["current_streak"],
    )


@router.post(
    "/student/{student_uid}/spend-coins",
    response_model=SpendCoinsResponse,
)
def spend_coins(
    student_uid: str,
    req: SpendCoinsRequest,
    db: Session = Depends(get_db),
    _caller: str = Depends(get_current_user),
):
    """Deduct coins for shop purchases."""
    try:
        result = gamification_service.spend_coins(db, student_uid, req.amount, req.reason)
        db.commit()
        return SpendCoinsResponse(**result)
    except ValueError as e:
        from fastapi import HTTPException
        raise HTTPException(status_code=400, detail=str(e))

