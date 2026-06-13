"""
Gamification API routes.

Endpoints:
  GET  /gamification/student/{student_uid}/profile        → student's XP/coins/level
  GET  /gamification/student/{student_uid}/daily-snapshot → today's quizzes/study time/accuracy
  GET  /gamification/student/{student_uid}/weekly-report  → 7-day stats + streak
  GET  /gamification/levels                               → static level definitions
  POST /gamification/student/{student_uid}/daily-login    → award daily login bonus
"""
from datetime import datetime, timedelta
from typing import Optional

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from sqlalchemy import func

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
from app.repositories.gamification_repo import get_all_levels, get_or_create_student_gamification
from app.models.domain.quiz import QuizSession

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


@router.get("/student/{student_uid}/daily-snapshot")
def get_daily_snapshot(
    student_uid: str,
    client_local_date: Optional[str] = Query(None),
    db: Session = Depends(get_db),
    _caller: str = Depends(get_current_user),
):
    """Return today's quiz count, study time, and accuracy for a student."""
    today = datetime.utcnow().date()
    if client_local_date:
        try:
            today = datetime.strptime(client_local_date, "%Y-%m-%d").date()
        except ValueError:
            pass

    sessions = (
        db.query(QuizSession)
        .filter(
            QuizSession.student_uid == student_uid,
            func.date(QuizSession.start_time) == today,
            QuizSession.end_time.isnot(None),
        )
        .all()
    )

    study_time_minutes = sum(
        int((s.end_time - s.start_time).total_seconds() / 60)
        for s in sessions
    )
    scored = [s.score for s in sessions if s.score is not None]
    accuracy_today = int(sum(scored) / len(scored)) if scored else 0

    return {
        "student_uid": student_uid,
        "quizzes_today": len(sessions),
        "study_time_minutes": study_time_minutes,
        "accuracy_today": accuracy_today,
    }


@router.get("/student/{student_uid}/weekly-report")
def get_weekly_report(
    student_uid: str,
    db: Session = Depends(get_db),
    _caller: str = Depends(get_current_user),
):
    """Return 7-day quiz stats and streak for a student."""
    now = datetime.utcnow()
    week_start = now - timedelta(days=7)

    sessions = (
        db.query(QuizSession)
        .filter(
            QuizSession.student_uid == student_uid,
            QuizSession.start_time >= week_start,
            QuizSession.end_time.isnot(None),
        )
        .all()
    )

    study_time_minutes = sum(
        int((s.end_time - s.start_time).total_seconds() / 60)
        for s in sessions
    )
    scored = [s.score for s in sessions if s.score is not None]
    overall_accuracy = round(sum(scored) / len(scored), 1) if scored else 0.0

    # Accuracy trend: group completed sessions by ISO week over the past 6 weeks
    six_weeks_ago = now - timedelta(weeks=6)
    trend_sessions = (
        db.query(QuizSession)
        .filter(
            QuizSession.student_uid == student_uid,
            QuizSession.start_time >= six_weeks_ago,
            QuizSession.end_time.isnot(None),
            QuizSession.score.isnot(None),
        )
        .order_by(QuizSession.start_time)
        .all()
    )

    week_buckets: dict = {}
    for s in trend_sessions:
        key = (s.start_time.year, s.start_time.isocalendar()[1])
        week_buckets.setdefault(key, []).append(s.score)

    accuracy_trend = [
        {"week_label": f"W{wk}", "accuracy": round(sum(scores) / len(scores), 1)}
        for (_, wk), scores in sorted(week_buckets.items())
    ]

    gam = get_or_create_student_gamification(db, student_uid)

    return {
        "student_uid": student_uid,
        "week_start_date": week_start.date().isoformat(),
        "total_quizzes": len(sessions),
        "study_time_minutes": study_time_minutes,
        "overall_accuracy_percent": overall_accuracy,
        "current_streak_days": gam.current_streak,
        "longest_streak_days": gam.longest_streak,
        "accuracy_trend": accuracy_trend,
    }

