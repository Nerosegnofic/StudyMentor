from pydantic import BaseModel, Field
from typing import List, Dict, Any, Optional
from uuid import UUID

class DocumentUploadResponse(BaseModel):
    status: str
    document_id: UUID

class GenerateQuizRequest(BaseModel):
    total_questions: int = Field(default=10, ge=1, le=50, description="Total number of questions to generate")

import uuid

class QuestionSchema(BaseModel):
    question_id: str = Field(default_factory=lambda: str(uuid.uuid4()), description="Backend-generated unique ID. Ignore this field.")
    topic: str = Field(..., description="The name of the topic or skill this question belongs to")
    question_text: str
    options: List[str]
    correct_answer: str
    explanation: str
    difficulty: int = Field(..., ge=1, le=5, description="Difficulty level of the question from 1 to 5")
    hints: List[str] = Field(..., description="Exactly 3 progressive hints to help the student in Arabic")

class GenerateQuizResponse(BaseModel):
    quiz_title: str
    questions: List[QuestionSchema]
    
    # Allow extra fields in case the LLM returning structured data has a slightly different shape
    model_config = {"extra": "allow"}

class StudentAnswer(BaseModel):
    question_id: str
    selected_option: str
    time_taken_ms: int = Field(default=10000, description="Time taken to answer in ms")
    hints_used: int = Field(default=0, description="Number of hints used")

class QuizSubmissionRequest(BaseModel):
    quiz_session_id: str = Field(..., description="The ID of the generated quiz session")
    answers: List[StudentAnswer]

class QuizSubmissionResponse(BaseModel):
    score: float
    total_questions: int
    feedback: str

# SQLAlchemy Domain Models are now used for student profiles and skill states.
# DTOs can be added here if needed for API responses.

# ---------------------------------------------------------------------------
# LLM-Refined Mastery Points (Structured Output for Gemini)
# ---------------------------------------------------------------------------

class RefinedSkill(BaseModel):
    """A single refined mastery skill — the atomic unit for BKT tracking."""
    skill_id: str = Field(..., description="Unique short identifier for this skill, e.g. 'u1_l1_s1'. Format: u{unit_number}_l{lesson_number}_s{skill_index}")
    skill_text: str = Field(..., description="The refined mastery point text in the textbook's language")

class RefinedLesson(BaseModel):
    """A lesson with its refined skills."""
    lesson_name: str = Field(..., description="Canonical lesson name, e.g. 'الدرس الأول: الكسور العشرية حتى جزء من الألف'")
    skills: List[RefinedSkill] = Field(..., description="List of refined skills for this lesson")

class RefinedUnit(BaseModel):
    """A unit containing its lessons."""
    unit_name: str = Field(..., description="Canonical unit name, e.g. 'الوحدة الأولى: القيمة المكانية للأعداد العشرية وحسابها'")
    lessons: List[RefinedLesson] = Field(..., description="List of lessons in this unit")

class RefinedMasteryResponse(BaseModel):
    """Complete structured output from the Gemini mastery refinement call."""
    units: List[RefinedUnit] = Field(..., description="All units with their lessons and refined skills")


# ---------------------------------------------------------------------------
# Database Mastery Point Schema
# ---------------------------------------------------------------------------

class MasteryPointSchema(BaseModel):
    id: UUID = Field(default_factory=uuid.uuid4)
    document_id: UUID
    unit: str
    lesson: str
    skill_id: Optional[str] = None
    point_text: str
    source: str = Field(default="regex", description="Origin: 'regex' or 'llm_refined'")
    
    class Config:
        from_attributes = True
