"""
Integration tests for BKT mastery persistence (DB-backed).

Runs the real ``BKTEngine.update_mastery`` against a persisted StudentSkillState
row and asserts the mutation survives across calls: attempts increment,
``last_practiced`` advances, mastery climbs on a correct streak, and the
``is_mastered`` flag flips once the threshold AND minimum-attempts gate are met.
"""
import pytest

from app.services.evaluation.bkt_engine import BKTEngine
from app.models.domain import StudentSkillState
from tests.conftest import make_subject, make_skill, make_skill_state

STUDENT = "student-mastery"


@pytest.fixture
def persisted_state(db_session):
    subject = make_subject(db_session, name="Math")
    skill = make_skill(db_session, subject_id=subject.subject_id, name="Fractions")
    state = make_skill_state(db_session, student_uid=STUDENT, skill_id=skill.skill_id,
                             mastery_probability=0.01, attempts=0)
    db_session.commit()
    return db_session, state


@pytest.mark.integration
class TestMasteryPersistence:
    def test_single_correct_answer_persists(self, persisted_state):
        db, state = persisted_state
        engine = BKTEngine()
        engine.update_mastery(state, "Fractions", difficulty=3, correct=True, response_time=10)
        db.commit()

        reloaded = db.query(StudentSkillState).filter_by(state_id=state.state_id).one()
        assert reloaded.attempts == 1
        assert reloaded.mastery_probability > 0.01
        assert reloaded.last_practiced is not None

    def test_correct_streak_converges_and_sets_mastered(self, persisted_state):
        db, state = persisted_state
        engine = BKTEngine()
        for _ in range(20):
            engine.update_mastery(state, "Fractions", difficulty=3, correct=True, response_time=10)
        db.commit()

        reloaded = db.query(StudentSkillState).filter_by(state_id=state.state_id).one()
        assert reloaded.attempts == 20
        assert reloaded.mastery_probability >= engine.cfg.mastered_threshold
        assert reloaded.is_mastered is True

    def test_mastered_not_set_before_min_attempts(self, persisted_state):
        db, state = persisted_state
        engine = BKTEngine()
        # Even with high mastery, fewer than mastered_min_attempts must not flip it.
        for _ in range(engine.cfg.mastered_min_attempts - 1):
            engine.update_mastery(state, "Fractions", difficulty=1, correct=True, response_time=10)
        db.commit()

        reloaded = db.query(StudentSkillState).filter_by(state_id=state.state_id).one()
        assert reloaded.attempts == engine.cfg.mastered_min_attempts - 1
        assert reloaded.is_mastered is False