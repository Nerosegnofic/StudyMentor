import uuid
from datetime import datetime
from sqlalchemy import Column, Integer, String, Float, ForeignKey, DateTime, Text, JSON
from sqlalchemy.dialects.postgresql import UUID as PG_UUID
from sqlalchemy.orm import relationship
from app.models.domain.base import Base

class Question(Base):
    __tablename__ = "questions"
    
    question_id = Column(PG_UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    skill_id = Column(Integer, ForeignKey("skills.skill_id"), nullable=False)
    session_id = Column(PG_UUID(as_uuid=True), ForeignKey("quiz_sessions.session_id"), nullable=False)
    text_content = Column(Text, nullable=False)
    options = Column(JSON, nullable=False)
    correct_answer = Column(String, nullable=False)
    difficulty = Column(Float, nullable=False)
    source_enum = Column(String, default="AI")
    explanation = Column(Text, nullable=True)
    hints = Column(JSON, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    submitted_at = Column(DateTime, nullable=True)
    
    skill = relationship("Skill", back_populates="questions")
    session = relationship("QuizSession", back_populates="questions")
    responses = relationship("QuestionResponse", back_populates="question", cascade="all, delete-orphan")
