"""
Integration tests for the Ordered-Frontier skill selector (DB-backed).

These seed real Skill rows and StudentSkillState mastery into in-memory SQLite,
then assert that:
  - ``classify_skills`` buckets skills into frontier / mastered / locked according
    to the unlock threshold and frontier window, in curriculum order; and
  - ``select_quiz_skills`` composes a quiz whose total never exceeds the request
    and whose per-skill difficulty is SERVER-COMPUTED from stored mastery (a core
    security invariant — difficulty is never client-supplied).
"""
import pytest

from app.core.config import settings
from app.services.quiz.skill_selector import classify_skills, select_quiz_skills
from app.services.quiz.difficulty_mapper import mastery_to_difficulty
from tests.conftest import make_subject, make_skill, make_skill_state

STUDENT = "student-sel"


def _seed_linear_curriculum(db, n_skills, masteries):
    """Create a subject with n skills in one unit (lesson_index 0..n-1) and
    optionally seed per-skill mastery for STUDENT. ``masteries`` maps index->prob."""
    subject = make_subject(db, name="Math")
    skills = []
    for i in range(n_skills):
        s = make_skill(db, subject_id=subject.subject_id, name=f"skill-{i}",
                       unit_name="Unit 1", lesson_index=i)
        skills.append(s)
        if i in masteries:
            make_skill_state(db, student_uid=STUDENT, skill_id=s.skill_id,
                             mastery_probability=masteries[i],
                             is_mastered=masteries[i] >= 0.85, attempts=5)
    db.flush()
    return subject, skills


@pytest.mark.integration
class TestClassifySkills:
    def test_empty_subject_returns_empty_zones(self, db_session):
        subject = make_subject(db_session, name="Empty")
        zones = classify_skills(db_session, STUDENT, subject.subject_id)
        assert zones == {"frontier": [], "mastered": [], "locked": []}

    def test_unpracticed_skills_fill_frontier_then_lock(self, db_session):
        # 5 skills, no mastery -> first `frontier_window` are frontier, rest locked.
        subject, _ = _seed_linear_curriculum(db_session, 5, masteries={})
        window = 3
        zones = classify_skills(db_session, STUDENT, subject.subject_id, frontier_window=window)
        assert len(zones["frontier"]) == window
        assert len(zones["locked"]) == 5 - window
        assert zones["mastered"] == []

    def test_high_mastery_skill_goes_to_mastered_zone(self, db_session):
        # Skill 0 above the unlock threshold -> mastered; it does NOT consume a
        # frontier slot, so the window slides to later skills.
        above = settings.SKILL_UNLOCK_THRESHOLD + 0.05
        subject, _ = _seed_linear_curriculum(db_session, 5, masteries={0: above})
        zones = classify_skills(db_session, STUDENT, subject.subject_id, frontier_window=3)
        mastered_names = [e["skill"].name for e in zones["mastered"]]
        frontier_names = [e["skill"].name for e in zones["frontier"]]
        assert mastered_names == ["skill-0"]
        assert frontier_names == ["skill-1", "skill-2", "skill-3"]

    def test_unlock_threshold_boundary(self, db_session):
        # Exactly at the threshold -> mastered (>= is inclusive).
        subject, _ = _seed_linear_curriculum(
            db_session, 2, masteries={0: settings.SKILL_UNLOCK_THRESHOLD}
        )
        zones = classify_skills(db_session, STUDENT, subject.subject_id, frontier_window=3)
        assert [e["skill"].name for e in zones["mastered"]] == ["skill-0"]

    def test_classification_follows_curriculum_order(self, db_session):
        subject, _ = _seed_linear_curriculum(db_session, 4, masteries={})
        zones = classify_skills(db_session, STUDENT, subject.subject_id, frontier_window=2)
        # Frontier should be the earliest two by lesson_index.
        assert [e["skill"].name for e in zones["frontier"]] == ["skill-0", "skill-1"]


@pytest.mark.integration
class TestSelectQuizSkills:
    def test_total_count_never_exceeds_request(self, db_session):
        subject, _ = _seed_linear_curriculum(db_session, 6, masteries={})
        total = 5
        selections = select_quiz_skills(db_session, STUDENT, subject.subject_id,
                                        total_questions=total, student_grade=5)
        assert sum(s["count"] for s in selections) <= total
        assert all(s["count"] > 0 for s in selections)

    def test_difficulty_is_server_computed_from_mastery(self, db_session):
        # Frontier skill with a known mastery -> difficulty must equal the mapper's
        # output, proving difficulty is derived server-side (never client-supplied).
        subject, _ = _seed_linear_curriculum(db_session, 1, masteries={0: 0.35})
        selections = select_quiz_skills(db_session, STUDENT, subject.subject_id,
                                        total_questions=3, student_grade=5)
        assert selections, "expected at least one selected skill"
        entry = next(s for s in selections if s["skill"].name == "skill-0")
        assert entry["difficulty"] == mastery_to_difficulty(0.35)

    def test_zones_are_labelled(self, db_session):
        subject, _ = _seed_linear_curriculum(db_session, 6, masteries={})
        selections = select_quiz_skills(db_session, STUDENT, subject.subject_id,
                                        total_questions=6, student_grade=5)
        assert all(s["zone"] in {"frontier", "review", "preview"} for s in selections)