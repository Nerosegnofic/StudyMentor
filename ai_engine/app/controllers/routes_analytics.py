from fastapi import APIRouter, HTTPException
from app.models.schemas import QuizSubmissionRequest, QuizSubmissionResponse, StudentProfile
import logging
from typing import Dict
from app.services.bkt.context import EvaluationContext
from app.services.bkt.bkt_strategy import BKTStrategy
from app.services.bkt.irt_strategy import IRTStrategy

router = APIRouter(prefix="/analytics", tags=["Analytics"])

# Global in-memory storage for MVP (Mock Database)
# Dictionary tracking each student_id to their StudentProfile data
student_profiles: Dict[str, StudentProfile] = {}

# Instantiate the Context with the Bayesian Strategy (can swap to IRTStrategy())
evaluation_context = EvaluationContext(strategy=BKTStrategy())

@router.post("/submit", response_model=QuizSubmissionResponse)
async def submit_quiz(request: QuizSubmissionRequest):
    """
    Submit a completed quiz and calculate the score.
    In a real system, this would update the Bayesian Knowledge Tracing (BKT) 
    model in the database for the student.
    """
    try:
        total_questions = len(request.answers)
        if total_questions == 0:
            raise HTTPException(status_code=400, detail="Answers list cannot be empty.")
            
        correct_answers = sum(1 for ans in request.answers if ans.is_correct)
        score = (correct_answers / total_questions) * 100
        
        # Determine feedback based on score
        if score >= 85:
            feedback = "ممتاز! لقد أبليت بلاءً حسناً." # Excellent! You did great.
        elif score >= 50:
            feedback = "جيد، ولكن يمكنك التحسن بمزيد من الممارسة." # Good, but you can improve with more practice.
        else:
            feedback = "لا تقلق، استمر في المحاولة وسوف تنجح." # Don't worry, keep trying and you will succeed.
            
        # --- BKT Integration ---
        student_id = request.student_id
        if student_id not in student_profiles:
            student_profiles[student_id] = StudentProfile(student_id=student_id)
            
        profile = student_profiles[student_id]
        
        triggered_punishment = False
        
        for ans in request.answers:
            # Fallback to "General Math" if no topic provided
            skill_name = ans.topic if ans.topic else "General Math"
            
            # Pass the profile state and metrics to the stateless evaluation context
            punished = evaluation_context.execute_evaluation(
                profile=profile,
                skill=skill_name,
                difficulty=ans.difficulty,
                correct=ans.is_correct,
                response_time=ans.response_time,
                hints_used=ans.hints_used
            )
            if punished:
                triggered_punishment = True
                
        if triggered_punishment:
            feedback += " 🛑 تبدو أنك كنت تجيب بسرعة كبيرة جداً. يرجى أخذ الوقت الكافي للتفكير في المرة القادمة!" # Punishment message in Arabic
        
        return QuizSubmissionResponse(
            score=score,
            total_questions=total_questions,
            feedback=feedback
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
        
@router.get("/student/{student_id}")
async def get_student_analytics(student_id: str):
    """
    Get the BKT and performance analytics for a specific student.
    """
    if student_id not in student_profiles:
        # Return 0 mastery if the student has no history
        return {
            "student_id": student_id,
            "overall_mastery": 0.0,
            "mastery_by_topic": {},
            "recommended_topics": []
        }
        
    profile = student_profiles[student_id]
    
    mastery_by_topic = {}
    for skill, data in profile.skills.items():
        mastery_by_topic[skill] = data.mastery
        
    # Calculate overall mastery (average)
    if float(len(mastery_by_topic)) > 0:
        overall_mastery = sum(mastery_by_topic.values()) / len(mastery_by_topic)
    else:
        overall_mastery = 0.0
        
    # Recommend topics with lowest mastery (under 60%)
    recommended_topics = [
        skill for skill, mastery in mastery_by_topic.items() if mastery < 0.60
    ]
    
    # Sort them so lowest are first
    recommended_topics.sort(key=lambda x: mastery_by_topic[x])

    return {
        "student_id": student_id,
        "overall_mastery": round(overall_mastery, 4),
        "mastery_by_topic": {k: round(v, 4) for k, v in mastery_by_topic.items()},
        "recommended_topics": recommended_topics
    }
