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
from app.repositories.analytics_repo import (
    get_subject_time_allocation,
    get_study_time_series,
    summarize_quiz_effort,
    get_time_of_day_distribution,
    get_window_summary,
    get_weakest_subject,
)
from app.services.evaluation.insights import build_alerts, build_insight
from app.models.domain.quiz import QuizSession
from app.models.domain import Subject

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

    # Per-subject question counts for today — drives the home "questions" ring.
    questions_today = sum((s.total_questions or 0) for s in sessions)
    by_subject: dict = {}
    for s in sessions:
        by_subject[s.subject_id] = by_subject.get(s.subject_id, 0) + (s.total_questions or 0)

    subject_ids = [sid for sid in by_subject if sid is not None]
    names: dict = {}
    if subject_ids:
        rows = db.query(Subject).filter(Subject.subject_id.in_(subject_ids)).all()
        names = {row.subject_id: row.name for row in rows}

    questions_by_subject = [
        {
            "subject_id": sid,
            "subject_name": names.get(sid, "General") if sid is not None else "General",
            "questions": qcount,
        }
        for sid, qcount in by_subject.items()
        if qcount > 0
    ]
    questions_by_subject.sort(key=lambda e: e["questions"], reverse=True)

    return {
        "student_uid": student_uid,
        "quizzes_today": len(sessions),
        "study_time_minutes": study_time_minutes,
        "accuracy_today": accuracy_today,
        "questions_today": questions_today,
        "questions_by_subject": questions_by_subject,
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

    # Subject time allocation: share of this week's study minutes per subject
    subject_allocations = get_subject_time_allocation(db, sessions)

    # Effort & focus: self-started vs forced quizzes + rapid-guessing sessions
    effort = summarize_quiz_effort(sessions)

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

    # Week-over-week deltas (vs. the previous 7-day window).
    last_week = get_window_summary(db, student_uid, now - timedelta(days=14), week_start)
    accuracy_delta = (
        round(overall_accuracy - last_week["accuracy"], 1)
        if last_week["quizzes"] > 0
        else None
    )
    study_minutes_delta = study_time_minutes - last_week["study_minutes"]
    quizzes_delta = len(sessions) - last_week["quizzes"]

    # Days since last quiz (inactivity signal).
    days_since_last_quiz = None
    if gam.last_quiz_date:
        last_q = gam.last_quiz_date
        last_q = last_q.date() if hasattr(last_q, "date") else last_q
        days_since_last_quiz = (now.date() - last_q).days

    # Alerts + natural-language insight (rules engine, no LLM).
    signals = {
        "accuracy": overall_accuracy,
        "accuracy_delta": accuracy_delta,
        "study_minutes": study_time_minutes,
        "study_minutes_delta": study_minutes_delta,
        "total_quizzes": len(sessions),
        "quizzes_delta": quizzes_delta,
        "current_streak": gam.current_streak,
        "longest_streak": gam.longest_streak,
        "guessing_sessions": effort["guessing_sessions"],
        "days_since_last_quiz": days_since_last_quiz,
        "weakest_subject": get_weakest_subject(db, student_uid),
    }
    alerts = build_alerts(signals)
    ai_insight_text = build_insight(signals)

    return {
        "student_uid": student_uid,
        "week_start_date": week_start.date().isoformat(),
        "total_quizzes": len(sessions),
        "study_time_minutes": study_time_minutes,
        "overall_accuracy_percent": overall_accuracy,
        "current_streak_days": gam.current_streak,
        "longest_streak_days": gam.longest_streak,
        "accuracy_trend": accuracy_trend,
        "subject_allocations": subject_allocations,
        "voluntary_quizzes": effort["voluntary_quizzes"],
        "forced_quizzes": effort["forced_quizzes"],
        "guessing_sessions": effort["guessing_sessions"],
        "accuracy_delta": accuracy_delta,
        "study_minutes_delta": study_minutes_delta,
        "quizzes_delta": quizzes_delta,
        "alerts": alerts,
        "ai_insight_text": ai_insight_text,
    }


@router.get("/student/{student_uid}/study-habits")
def get_study_habits(
    student_uid: str,
    client_local_date: Optional[str] = Query(None),
    tz_offset_minutes: int = Query(0),
    db: Session = Depends(get_db),
    _caller: str = Depends(get_current_user),
):
    """Return streaks plus real study-time series (28-day heatmap, last 7 days,
    and time-of-day distribution in the student's local time)."""
    anchor = None
    if client_local_date:
        try:
            anchor = datetime.strptime(client_local_date, "%Y-%m-%d").date()
        except ValueError:
            pass

    gam = get_or_create_student_gamification(db, student_uid)
    heatmap, daily = get_study_time_series(db, student_uid, anchor_date=anchor)
    time_of_day = get_time_of_day_distribution(db, student_uid, tz_offset_minutes=tz_offset_minutes)

    return {
        "student_uid": student_uid,
        "current_streak_days": gam.current_streak,
        "longest_streak_days": gam.longest_streak,
        "consistency_heatmap": heatmap,
        "daily_study": daily,
        "time_of_day": time_of_day,
    }

