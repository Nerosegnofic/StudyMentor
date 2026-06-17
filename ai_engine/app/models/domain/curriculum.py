from sqlalchemy import Column, Integer, String, Float, ForeignKey, Boolean
from sqlalchemy.orm import relationship
from .base import Base

class Subject(Base):
    __tablename__ = "subjects"
    
    subject_id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String, nullable=False)
    weight = Column(Float, default=1.0)
    color_hex = Column(String)
    
    # Hybrid Approach: Global vs Private subjects
    is_global = Column(Boolean, default=True)
    student_uid = Column(String, nullable=True, index=True) # Null if is_global=True
    
    
    skills = relationship("Skill", back_populates="subject", cascade="all, delete-orphan")
    documents = relationship("Document", back_populates="subject", cascade="all, delete-orphan")

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
    default_learn_rate = Column(Float, default=0.05)
    
    subject = relationship("Subject", back_populates="skills")
    student_states = relationship("StudentSkillState", back_populates="skill", cascade="all, delete-orphan")
    questions = relationship("Question", back_populates="skill", cascade="all, delete-orphan")
