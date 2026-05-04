import uuid
from datetime import datetime
from sqlalchemy import Column, Integer, String, Float, Boolean, ForeignKey, DateTime, Text, JSON
from sqlalchemy.dialects.postgresql import UUID as PG_UUID
from sqlalchemy.orm import declarative_base, relationship
from pgvector.sqlalchemy import Vector

Base = declarative_base()

class StudentBKTProfile(Base):
    __tablename__ = "student_bkt_profiles"
    student_uid = Column(String, primary_key=True)
    current_step = Column(Integer, default=0)
    consecutive_spam_clicks = Column(Integer, default=0)

class Subject(Base):
    __tablename__ = "subjects"
    
    subject_id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String, nullable=False)
    weight = Column(Float, default=1.0)
    color_hex = Column(String)
    
    skills = relationship("Skill", back_populates="subject", cascade="all, delete-orphan")

class Skill(Base):
    __tablename__ = "skills"
    
    skill_id = Column(Integer, primary_key=True, autoincrement=True)
    subject_id = Column(Integer, ForeignKey("subjects.subject_id"), nullable=False)
    name = Column(String, nullable=False)
    weight = Column(Float, default=1.0)
    default_difficulty = Column(Float, default=1.0)
    default_learn_rate = Column(Float, default=0.1)
    
    subject = relationship("Subject", back_populates="skills")
    student_states = relationship("StudentSkillState", back_populates="skill", cascade="all, delete-orphan")
    curriculum_chunks = relationship("CurriculumChunk", back_populates="skill", cascade="all, delete-orphan")
    questions = relationship("Question", back_populates="skill", cascade="all, delete-orphan")

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

class CurriculumChunk(Base):
    __tablename__ = "curriculum_chunks"
    
    chunk_id = Column(PG_UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    document_id = Column(PG_UUID(as_uuid=True), nullable=True) # ID of the source document
    skill_id = Column(Integer, ForeignKey("skills.skill_id"), nullable=True)
    content = Column(Text, nullable=False)
    embedding = Column(Vector(1024)) # Cohere embed-multilingual-v3.0 is 1024 dims
    metadata_ = Column("metadata", JSON, nullable=True) # JSONB metadata
    
    skill = relationship("Skill", back_populates="curriculum_chunks")

class QuizSession(Base):
    __tablename__ = "quiz_sessions"
    
    session_id = Column(PG_UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    student_uid = Column(String, nullable=False, index=True)
    start_time = Column(DateTime, default=datetime.utcnow)
    end_time = Column(DateTime, nullable=True)
    total_questions = Column(Integer, nullable=False)
    score = Column(Float, nullable=True)
    
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
