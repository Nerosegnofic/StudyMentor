import uuid
from sqlalchemy import Column, Integer, String, Boolean, ForeignKey
from sqlalchemy.dialects.postgresql import UUID as PG_UUID
from sqlalchemy.orm import relationship
from app.models.domain.base import Base

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
