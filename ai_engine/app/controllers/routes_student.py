from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.core.auth import get_current_user
from app.repositories import get_all_student_skill_states

router = APIRouter(prefix="/analytics/student", tags=["Student Analytics (Legacy)"])

@router.get("/")
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
