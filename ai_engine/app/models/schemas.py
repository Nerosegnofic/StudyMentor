from pydantic import BaseModel, Field
from typing import List, Dict, Any, Optional
from uuid import UUID

class DocumentUploadResponse(BaseModel):
    status: str
    document_id: UUID

class TopicQuizConfig(BaseModel):
    topic: str = Field(..., description="Topic name in Arabic")
    difficulty: int = Field(..., ge=1, le=5, description="Target difficulty for this topic")
    question_count: int = Field(..., ge=1, le=10, description="Number of questions for this topic")

class QuizPayloadItem(BaseModel):
    """A single skill-block inside the adaptive quiz payload produced by the
    BKT → Quiz-Generator bridge."""
    skill: str = Field(..., description="Skill name from the student's mastery profile")
    difficulty: int = Field(..., ge=1, le=5, description="Target difficulty derived from mastery via ZPD mapping")
    count: int = Field(..., ge=1, description="Number of questions allocated to this skill")

class GenerateQuizRequest(BaseModel):
    topic_configs: List[TopicQuizConfig] = Field(..., description="Per-topic quiz specifications")
    student_id: Optional[str] = None

import uuid

class QuestionSchema(BaseModel):
    question_id: str = Field(default_factory=lambda: str(uuid.uuid4()), description="Backend-generated unique ID. Ignore this field.")
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
    is_correct: bool
    topic: Optional[str] = None 
    difficulty: int = Field(default=3, description="Difficulty of the question (1-5)")
    response_time: float = Field(default=10.0, description="Time taken to answer in seconds")
    hints_used: int = Field(default=0, description="Number of hints used")

class QuizSubmissionRequest(BaseModel):
    student_id: str
    quiz_title: str
    answers: List[StudentAnswer]

class QuizSubmissionResponse(BaseModel):
    score: float
    total_questions: int
    feedback: str

class StudentSkillState(BaseModel):
    mastery: float = 0.30
    learn_rate: float = 0.10
    attempts: int = 0
    last_seen_step: int = 0

class StudentProfile(BaseModel):
    student_id: str
    skills: Dict[str, StudentSkillState] = Field(default_factory=dict)
    current_step: int = 0
    consecutive_spam_clicks: int = 0
