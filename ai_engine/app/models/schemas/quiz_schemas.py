import re
import uuid
from pydantic import BaseModel, Field, field_validator, model_validator
from typing import List, Optional, Literal

# Pre-compiled pattern for LaTeX delimiters and bare dollar signs.
# Strips: $...$ inline, \(...\) inline, \[...\] display blocks, and stray $.
_LATEX_PATTERN = re.compile(r"\$[^$]*\$|\\\([\\s\\S]*?\\\)|\\\[[\\s\\S]*?\\\]|\$")

# Pattern to detect trailing zeros in decimal numbers (e.g., "3.70" → "3.7")
_TRAILING_ZEROS_PATTERN = re.compile(r"(\d+\.\d*?)0+(\s|$|[^\d])")


def _strip_latex(text: str) -> str:
    """Remove LaTeX delimiters and reformat plain-text math."""
    if not text:
        return text
    return _LATEX_PATTERN.sub("", text).strip()


def _normalize_numeric_text(text: str) -> str:
    """
    Normalize numeric representations in text to prevent ambiguous duplicates.
    - Strips trailing zeros from decimals: "3.70" → "3.7", "5.00" → "5.0"
    - Preserves non-numeric text unchanged.
    """
    if not text:
        return text
    # Iteratively strip trailing zeros in decimals
    result = _TRAILING_ZEROS_PATTERN.sub(r"\1\2", text)
    # Handle edge case: "5.0" should stay as "5.0" (one decimal place kept)
    return result


class GenerateQuizRequest(BaseModel):
    subject_id: Optional[int] = Field(
        None,
        description="The ID of the subject. If omitted, the system will auto-select the highest priority subject."
    )
    total_questions: int = Field(
        default=10, ge=1, le=50,
        description="Total number of questions to generate"
    )
    student_grade: int = Field(
        default=5, ge=1, le=12,
        description="The student's grade level (1-12). Used to tailor question vocabulary and complexity."
    )


class QuestionSchema(BaseModel):
    question_id: str = Field(
        default_factory=lambda: str(uuid.uuid4()),
        description="Backend-generated unique ID. Ignore this field."
    )
    topic: str = Field(..., description="The name of the topic or skill this question belongs to")
    question_text: str
    options: List[str]
    correct_answer: str
    explanation: str
    difficulty: int = Field(..., ge=1, le=5, description="Difficulty level of the question from 1 to 5")
    hints: List[str] = Field(..., description="Exactly 3 progressive hints to help the student in Arabic")

    @field_validator("question_text", "explanation", mode="before")
    @classmethod
    def strip_latex_from_text(cls, v: str) -> str:
        """
        Enforce the plain-text math formatting rule at the schema level.
        The LLM prompt instructs Gemini not to use LaTeX, but this validator
        acts as a hard safety net in case the model still produces delimiters.
        """
        return _strip_latex(v)

    @field_validator("hints", mode="before")
    @classmethod
    def strip_latex_from_hints(cls, v: List[str]) -> List[str]:
        if not v:
            return v
        return [_strip_latex(h) for h in v]

    @field_validator("options", mode="before")
    @classmethod
    def normalize_options(cls, v: List[str]) -> List[str]:
        """Normalize option text: strip whitespace and trailing zeros."""
        if not v:
            return v
        return [_normalize_numeric_text(opt.strip()) for opt in v]

    @field_validator("correct_answer", mode="before")
    @classmethod
    def normalize_correct_answer(cls, v: str) -> str:
        """Apply the same normalization to correct_answer so it matches options."""
        return _normalize_numeric_text(v.strip()) if v else v

    @model_validator(mode="after")
    def validate_question_integrity(self):
        """
        Post-construction validation to catch LLM output errors:
        1. Exactly 4 options required.
        2. All options must be unique.
        3. correct_answer must exactly match one of the options.
        """
        # Check option count
        if len(self.options) != 4:
            raise ValueError(
                f"Expected exactly 4 options, got {len(self.options)}: {self.options}"
            )

        # Check for duplicate options
        if len(set(self.options)) != len(self.options):
            raise ValueError(
                f"Duplicate options detected: {self.options}"
            )

        # Check correct_answer is in options
        if self.correct_answer not in self.options:
            raise ValueError(
                f"correct_answer '{self.correct_answer}' does not match any option: {self.options}"
            )

        return self


class GenerateQuizResponse(BaseModel):
    quiz_session_id: str = Field(..., description="The ID of the generated quiz session")
    selected_subject_id: int = Field(..., description="The ID of the subject that was selected (either manually or automatically)")
    selected_subject_name: str = Field(..., description="The name of the selected subject")
    quiz_title: str
    questions: List[QuestionSchema]
    quiz_source: Literal["FRESH", "CACHED", "BANK"] = Field(
        default="FRESH",
        description=(
            "FRESH — generated by the LLM now. "
            "CACHED — returned from an existing unsubmitted session (cross-device reuse). "
            "BANK — assembled from the student's previously answered questions (LLM fallback)."
        )
    )

    # Allow extra fields in case the LLM returning structured data has a slightly different shape
    model_config = {"extra": "allow"}


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


class QuizSubmissionResponse(BaseModel):
    score: float
    total_questions: int
    feedback: str
    rewards: dict = Field(default_factory=dict)
