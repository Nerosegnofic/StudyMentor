from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
from app.models.schemas import QuizSubmissionRequest, QuizSubmissionResponse
from app.core.database import get_db
from app.core.auth import get_current_user
from app.repositories.mastery_repo import get_student_bkt_profile, get_student_skill_state, get_all_student_skill_states
from app.services.evaluation.bkt_engine import BKTEngine
from app.models.domain import Skill, Question, QuestionResponse, QuizSession

router = APIRouter(prefix="/analytics", tags=["Analytics"])
bkt_engine = BKTEngine()

@router.post("/submit", response_model=QuizSubmissionResponse)
async def submit_quiz(
    request: QuizSubmissionRequest, 
    db: Session = Depends(get_db),
    student_uid: str = Depends(get_current_user)
):
    try:
        total_questions = len(request.answers)
        if total_questions == 0:
            raise HTTPException(status_code=400, detail="Answers list cannot be empty.")
            
        bkt_profile = get_student_bkt_profile(db, student_uid)
        triggered_punishment = False
        correct_answers = 0
        
        # We also want to update the QuizSession score
        quiz_session = db.query(QuizSession).filter(QuizSession.session_id == request.quiz_session_id).first()
        
        for ans in request.answers:
            # Secure Server-Side Grading
            db_question = db.query(Question).filter(Question.question_id == ans.question_id).first()
            if not db_question:
                continue # Skip invalid questions
                
            is_correct = (ans.selected_option == db_question.correct_answer)
            if is_correct:
                correct_answers += 1
                
            # Save the student's response securely
            db_response = QuestionResponse(
                question_id=db_question.question_id,
                student_uid=student_uid,
                selected_option=ans.selected_option,
                is_correct=is_correct,
                time_taken_ms=ans.time_taken_ms,
                hints_used=ans.hints_used
            )
            db.add(db_response)
            
            # Lookup skill and update BKT
            difficulty = db_question.difficulty
            skill_name = db_question.skill.name if db_question.skill else "General Math"
            skill_state = get_student_skill_state(db, student_uid, skill_name)
            
            punished = bkt_engine.update_mastery(
                profile=bkt_profile,
                skill_state=skill_state,
                skill_name=skill_name,
                difficulty=difficulty,
                correct=is_correct,
                response_time=ans.time_taken_ms / 1000.0,
                hints_used=ans.hints_used
            )
            if punished:
                triggered_punishment = True
                
        score = (correct_answers / total_questions) * 100
        if quiz_session:
            quiz_session.score = score
            
        db.commit()
        
        if score >= 85:
            feedback = "ممتاز! لقد أبليت بلاءً حسناً."
        elif score >= 50:
            feedback = "جيد، ولكن يمكنك التحسن بمزيد من الممارسة."
        else:
            feedback = "لا تقلق، استمر في المحاولة وسوف تنجح."
                
        if triggered_punishment:
            feedback += " 🛑 تبدو أنك كنت تجيب بسرعة كبيرة جداً. يرجى أخذ الوقت الكافي للتفكير في المرة القادمة!"
        
        return QuizSubmissionResponse(
            score=score,
            total_questions=total_questions,
            feedback=feedback
        )
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))
        
@router.get("/student")
async def get_student_analytics(
    db: Session = Depends(get_db),
    student_uid: str = Depends(get_current_user)
):
    mastery_by_topic = get_all_student_skill_states(db, student_uid)
    
    if not mastery_by_topic:
        return {
            "student_id": student_uid,
            "overall_mastery": 0.0,
            "mastery_by_topic": {},
            "recommended_topics": []
        }
        
    overall_mastery = sum(mastery_by_topic.values()) / len(mastery_by_topic)
    
    recommended_topics = [
        skill for skill, mastery in mastery_by_topic.items() if mastery < 0.60
    ]
    recommended_topics.sort(key=lambda x: mastery_by_topic[x])

    return {
        "student_id": student_uid,
        "overall_mastery": round(overall_mastery, 4),
        "mastery_by_topic": {k: round(v, 4) for k, v in mastery_by_topic.items()},
        "recommended_topics": recommended_topics
    }
