import uuid
from pydantic import BaseModel, Field
from typing import List, Optional
from uuid import UUID

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
