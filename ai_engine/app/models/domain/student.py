import uuid
from datetime import datetime
from sqlalchemy import Column, Integer, String, Float, Boolean, ForeignKey, DateTime
from sqlalchemy.dialects.postgresql import UUID as PG_UUID
from sqlalchemy.orm import relationship
from .base import Base

class StudentBKTProfile(Base):
    __tablename__ = "student_bkt_profiles"
    student_uid = Column(String, primary_key=True)
    current_step = Column(Integer, default=0)
    consecutive_spam_clicks = Column(Integer, default=0)

class StudentSkillState(Base):
    __tablename__ = "student_skill_states"
    
    state_id = Column(PG_UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    student_uid = Column(String, nullable=False, index=True) # Firebase UID
    skill_id = Column(Integer, ForeignKey("skills.skill_id"), nullable=False)
    mastery_probability = Column(Float, default=0.01)
    is_mastered = Column(Boolean, default=False)
    last_practiced = Column(DateTime, default=datetime.utcnow)
    attempts = Column(Integer, default=0)
    
    skill = relationship("Skill", back_populates="student_states")
