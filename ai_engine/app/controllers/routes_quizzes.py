from fastapi import APIRouter, Depends, Request
from sqlalchemy.orm import Session

from app.models.schemas import (
    GenerateQuizRequest,
    GenerateQuizResponse,
    QuizSubmissionRequest,
    QuizSubmissionResponse,
)
from app.core.rate_limit import limiter
from app.core.config import settings
from app.core.database import get_db
from app.core.auth import get_current_user

from app.services.quiz.quiz_generation_service import generate_quiz_for_student
from app.services.quiz.quiz_submission_service import process_quiz_submission

router = APIRouter(prefix="/quizzes", tags=["Quizzes"])

@router.post("/generate", response_model=GenerateQuizResponse)
@limiter.limit(settings.QUIZ_GENERATE_RATE_LIMIT)
async def generate_quiz(
    request_body: GenerateQuizRequest,
    request: Request,
    db: Session = Depends(get_db),
    student_uid: str = Depends(get_current_user),
):
    """
    Generates a new quiz or retrieves an active cached quiz session.
    """
    return generate_quiz_for_student(db=db, request_body=request_body, student_uid=student_uid)


@router.post("/submit", response_model=QuizSubmissionResponse)
async def submit_quiz(
    request: QuizSubmissionRequest,
    db: Session = Depends(get_db),
    student_uid: str = Depends(get_current_user),
):
    """
    Submits quiz answers, scores them, and updates BKT mastery parameters.
    """
    return process_quiz_submission(db=db, request=request, student_uid=student_uid)