from pydantic import BaseModel, Field, field_validator
from typing import List, Optional, Literal

class GenerateQuizRequest(BaseModel):
    subject_id: Optional[int] = Field(
        None,
        description="The ID of the subject. If omitted, the system will auto-select the highest priority subject."
    )
    total_questions: int = Field(
        default=10, ge=1, le=50,
        description="Total number of questions to generate. Ignored when auto_length is true."
    )
    auto_length: bool = Field(
        default=False,
        description="When true (parent picked 'Auto'), the server sizes the quiz adaptively "
                    "from the student's active material and recent accuracy, ignoring total_questions."
    )
    student_grade: int = Field(
        default=5, ge=1, le=12,
        description="The student's grade level (1-12). Used to tailor question vocabulary and complexity."
    )
    quiz_context: Literal["VOLUNTARY", "FORCED"] = Field(
        default="VOLUNTARY",
        description=(
            "How this quiz is launched: VOLUNTARY (student chose to practice) or "
            "FORCED (parent/system mandated, e.g. after a focus-time limit). Drives the "
            "FORCED reward bonus. Stamped on the session that hands the quiz to the student "
            "(including a re-stamp when a pre-warmed/cached session is served)."
        )
    )


class StudentAnswer(BaseModel):
    question_id: str
    selected_option: str
    time_taken_ms: int = Field(default=10000, ge=0, description="Time taken to answer in ms")
    hints_used: int = Field(default=0, description="Number of hints used")

    @field_validator("hints_used", mode="before")
    @classmethod
    def clamp_hints_used(cls, v) -> int:
        """
        Clamp hints_used to [0, 3]. The server defines 3 as the max number
        of hints per question. Client bugs may send out-of-range values;
        we silently clamp rather than reject the whole submission.
        """
        return min(max(int(v), 0), 3)


class QuizSubmissionRequest(BaseModel):
    quiz_session_id: str = Field(..., description="The ID of the generated quiz session")
    answers: List[StudentAnswer]
    client_local_date: Optional[str] = Field(None, description="Client's local date (YYYY-MM-DD) for streak tracking")
