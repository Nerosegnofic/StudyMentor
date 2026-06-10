import uuid
from datetime import datetime
from sqlalchemy import Column, Integer, String, Float, Boolean, ForeignKey, DateTime, Text, JSON
from sqlalchemy.dialects.postgresql import UUID as PG_UUID
from sqlalchemy.orm import relationship
from .base import Base

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
    quiz_context = Column(String, default="VOLUNTARY")  # VOLUNTARY | FORCED
    
    subject = relationship("Subject")
    questions = relationship("Question", back_populates="session", cascade="all, delete-orphan")

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

class QuestionResponse(Base):
    __tablename__ = "question_responses"
    
    response_id = Column(PG_UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    question_id = Column(PG_UUID(as_uuid=True), ForeignKey("questions.question_id"), nullable=False)
    student_uid = Column(String, nullable=False, index=True)
    selected_option = Column(String, nullable=True)
    is_correct = Column(Boolean, nullable=False)
    time_taken_ms = Column(Integer, nullable=False)
    hints_used = Column(Integer, default=0)
    
    question = relationship("Question", back_populates="responses")
