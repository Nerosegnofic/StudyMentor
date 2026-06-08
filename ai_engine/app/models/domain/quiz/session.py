import uuid
from datetime import datetime
from sqlalchemy import Column, Integer, String, Float, ForeignKey, DateTime
from sqlalchemy.dialects.postgresql import UUID as PG_UUID
from sqlalchemy.orm import relationship
from app.models.domain.base import Base

class QuizSession(Base):
    __tablename__ = "quiz_sessions"
    
    session_id = Column(PG_UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    student_uid = Column(String, nullable=False, index=True)
    subject_id = Column(Integer, ForeignKey("subjects.subject_id"), nullable=True)
    start_time = Column(DateTime, default=datetime.utcnow)
    end_time = Column(DateTime, nullable=True)
    total_questions = Column(Integer, nullable=False)
    score = Column(Float, nullable=True)
    consecutive_spam_clicks = Column(Integer, default=0) # Tracks "guessing" behavior within this specific quiz session
    
    subject = relationship("Subject")
    questions = relationship("Question", back_populates="session", cascade="all, delete-orphan")
