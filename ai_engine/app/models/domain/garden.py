from datetime import datetime
from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey, UniqueConstraint
from sqlalchemy.orm import relationship
from .base import Base


class GardenPlant(Base):
    __tablename__ = "garden_plants"

    student_uid = Column(String, nullable=False, index=True)
    subject_id = Column(Integer, ForeignKey("subjects.subject_id"), nullable=False)
    mastery_percent = Column(Float, nullable=False, default=0.0)  # 0.0 – 100.0
    updated_at = Column(DateTime, default=datetime.utcnow)

    subject = relationship("Subject")

    __table_args__ = (
        UniqueConstraint("student_uid", "subject_id", name="uq_garden_plant"),
        {"extend_existing": True},
    )

    # Composite PK via ORM convention — use UniqueConstraint above for DB integrity.
    # We expose a synthetic PK column so SQLAlchemy is happy.
    id = Column(Integer, primary_key=True, autoincrement=True)
