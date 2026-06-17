from dataclasses import dataclass


@dataclass
class BKTConfig:
    """
    Single tuning panel for the Bayesian Knowledge Tracing mastery model.

    Every number that shapes how fast a skill's mastery grows, declines, and
    forgets lives here — change the values, not the logic in bkt_engine.py.
    """

    # ── Mastery bounds ──────────────────────────────────────────────
    min_prob: float = 0.01      # lowest a skill's mastery can fall to
    max_prob: float = 0.95      # highest a skill's mastery can rise to

    # ── GROWTH SPEED — main knob ────────────────────────────────────
    # Fraction of each question's Bayesian jump that is actually applied.
    # Damps growth AND decline symmetrically.
    # 0.25 = very stable (chosen) · 0.4 = moderate · 1.0 = raw/jumpy BKT
    mastery_step: float = 0.25
    default_learn_rate: float = 0.05   # upward pull per answer (fallback when
                                       # a skill has no per-skill learn rate)

    # ── Answer-noise model ──────────────────────────────────────────
    base_guess: float = 0.20    # chance of a correct answer without knowing
    base_slip: float = 0.10     # chance of a wrong answer despite knowing
    difficulty_guess_sensitivity: float = 0.40  # how fast guess drops as difficulty rises
    difficulty_slip_sensitivity: float = 0.30   # how fast slip rises as difficulty rises

    # ── Forgetting ──────────────────────────────────────────────────
    forgetting_rate: float = 0.995  # daily mastery multiplier (1.0 = never forget)

    # ── "Mastered" badge ────────────────────────────────────────────
    # Lowered from 0.95: with mastery_step < 1 the mastery asymptotically
    # approaches max_prob but never reaches it, so 0.95 would be unreachable.
    # 0.85 also aligns with the 80% garden "full bloom" stage.
    mastered_threshold: float = 0.85
    mastered_min_attempts: int = 6

    # ── Hints / rushing / spam ──────────────────────────────────────
    hint_penalty: float = 0.30   # mastery-update weight lost per hint used
    min_quality: float = 0.10    # floor on the per-update weight
    rush_seconds: float = 30.0   # under this = rushed (guess↓, slip↑)
    slow_seconds: float = 120.0  # over this = deliberate (guess↑, slip↓)
    min_read_seconds: float = 2.0  # under this = spam: no mastery change
    spam_threshold: int = 3      # consecutive spam answers before punishment
