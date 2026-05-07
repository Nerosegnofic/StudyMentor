import uuid
from sqlalchemy import Column, Integer, String, Float, ForeignKey, Text, JSON
from sqlalchemy.dialects.postgresql import UUID as PG_UUID
from sqlalchemy.orm import relationship
from pgvector.sqlalchemy import Vector
from .base import Base

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
    unit_name = Column(String, nullable=True)
    lesson_name = Column(String, nullable=True)
    lesson_index = Column(Integer, nullable=True)
    weight = Column(Float, default=1.0)
    default_difficulty = Column(Float, default=1.0)
    default_learn_rate = Column(Float, default=0.1)
    
    subject = relationship("Subject", back_populates="skills")
    student_states = relationship("StudentSkillState", back_populates="skill", cascade="all, delete-orphan")
    curriculum_chunks = relationship("CurriculumChunk", back_populates="skill", cascade="all, delete-orphan")
    questions = relationship("Question", back_populates="skill", cascade="all, delete-orphan")

class CurriculumChunk(Base):
    __tablename__ = "curriculum_chunks"
    
    chunk_id = Column(PG_UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    document_id = Column(PG_UUID(as_uuid=True), nullable=True) # ID of the source document
    skill_id = Column(Integer, ForeignKey("skills.skill_id"), nullable=True)
    content = Column(Text, nullable=False)
    embedding = Column(Vector(1024)) # Cohere embed-multilingual-v3.0 is 1024 dims
    metadata_ = Column("metadata", JSON, nullable=True) # JSONB metadata
    
    skill = relationship("Skill", back_populates="curriculum_chunks")
