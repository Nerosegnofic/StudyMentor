from datetime import date
from sqlalchemy import Column, Integer, String, Float, Date, ForeignKey, UniqueConstraint
from sqlalchemy.orm import relationship
from .base import Base


class MasterySnapshot(Base):
    """
    One row per (student, subject, day) recording the subject's mastery percent
    that day. Written whenever the garden mastery is recomputed (after a quiz),
    so the parent Reports → Mastery tab can plot mastery over time.
    """
    __tablename__ = "mastery_snapshots"

    id = Column(Integer, primary_key=True, autoincrement=True)
    student_uid = Column(String, nullable=False, index=True)
    subject_id = Column(Integer, ForeignKey("subjects.subject_id"), nullable=False)
    mastery_percent = Column(Float, nullable=False, default=0.0)  # 0.0 – 100.0
    recorded_on = Column(Date, nullable=False, default=date.today)

    subject = relationship("Subject")

    __table_args__ = (
        UniqueConstraint(
            "student_uid", "subject_id", "recorded_on", name="uq_mastery_snapshot_day"
        ),
        {"extend_existing": True},
    )
