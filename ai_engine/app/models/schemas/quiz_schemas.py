import uuid
from pydantic import BaseModel, Field
from typing import List, Optional

class GenerateQuizRequest(BaseModel):
    subject_id: Optional[int] = Field(None, description="The ID of the subject. If omitted, the system will auto-select the highest priority subject.")
    total_questions: int = Field(default=10, ge=1, le=50, description="Total number of questions to generate")

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
    quiz_session_id: str = Field(..., description="The ID of the generated quiz session")
    selected_subject_id: int = Field(..., description="The ID of the subject that was selected (either manually or automatically)")
    selected_subject_name: str = Field(..., description="The name of the selected subject")
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


