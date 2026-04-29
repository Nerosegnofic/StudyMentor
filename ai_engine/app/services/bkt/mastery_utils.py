import math
from typing import Dict, List, Tuple


# ---------------------------------------------------------------------------
# 1) Difficulty Mapping – Zone of Proximal Development (ZPD)
# ---------------------------------------------------------------------------

def mastery_to_difficulty(mastery: float) -> int:
    """
    Converts a BKT mastery probability (0.0 – 1.0) into a target difficulty
    level (1–5) using Zone of Proximal Development thresholds.

    Mastery < 0.30  → Difficulty 1  (Very Easy)
    Mastery 0.30–0.49 → Difficulty 2  (Easy)
    Mastery 0.50–0.69 → Difficulty 3  (Medium)
    Mastery 0.70–0.89 → Difficulty 4  (Hard)
    Mastery 0.90+     → Difficulty 5  (Very Hard)
    """
    if mastery < 0.30:
        return 1
    elif mastery < 0.50:
        return 2
    elif mastery < 0.70:
        return 3
    elif mastery < 0.90:
        return 4
    else:
        return 5


# ---------------------------------------------------------------------------
# 2) Priority Weighting – The Learning Sweet Spot
# ---------------------------------------------------------------------------

def _skill_priority_weight(mastery: float) -> float:
    """
    Computes a continuous priority weight for a single skill based on its
    mastery level.  Uses a Gaussian-like bell curve centred at 0.50 mastery
    so that skills in the active-learning zone (≈ 0.20 – 0.85) receive the
    highest weight, with a peak at 50 % mastery.

    Three priority tiers are blended:
      • Active learning  (0.20 ≤ m ≤ 0.85) → peak weight via Gaussian
      • Brand-new skills (m < 0.20)         → moderate baseline
      • Mastered skills  (m > 0.95)         → small review floor

    The Gaussian is  w = exp(- (m - 0.50)^2 / (2 * σ^2))  with σ = 0.22,
    which naturally produces a wide bell over the 0.20 – 0.85 range and
    drops steeply outside it.  We add a floor so that every skill always
    receives *some* non-zero weight.
    """
    SIGMA = 0.22
    CENTER = 0.50

    # Gaussian component – peaks at CENTER, tapers toward extremes
    gaussian = math.exp(-((mastery - CENTER) ** 2) / (2 * SIGMA ** 2))

    # Tier floors
    if mastery > 0.95:
        # Mastered – only occasional review; small constant weight
        return max(gaussian, 0.05)
    elif mastery < 0.20:
        # Brand-new – gentle introduction; moderate floor
        return max(gaussian, 0.25)
    else:
        # Active-learning zone – let the Gaussian drive the weight
        return gaussian


# ---------------------------------------------------------------------------
# 3) Question Distribution – Strict Allocation
# ---------------------------------------------------------------------------

def _allocate_questions(
    weights: Dict[str, float],
    total_questions: int,
) -> Dict[str, int]:
    """
    Distributes *total_questions* across skills proportionally to their
    priority weights using the **Largest-Remainder Method** (Hamilton's
    method) to guarantee the sum equals exactly *total_questions*.

    Guarantee: every skill whose weight places it in the active-learning
    zone (weight ≥ 0.25, which excludes only the "mastered" floor) gets at
    least 1 question before any rounding takes place.
    """
    if not weights or total_questions <= 0:
        return {}

    weight_sum = sum(weights.values())
    if weight_sum == 0:
        return {}

    # --- Step A: fractional ideal shares --------------------------------
    ideal: Dict[str, float] = {
        skill: (w / weight_sum) * total_questions
        for skill, w in weights.items()
    }

    # --- Step B: floor each share ----------------------------------------
    HIGH_PRIORITY_THRESHOLD = 0.25  # matches the brand-new floor
    allocation: Dict[str, int] = {}
    for skill, frac in ideal.items():
        allocation[skill] = int(frac)

    # --- Step B2: guarantee ≥ 1 for high-priority skills (budget-aware) --
    #  Only grant minimums while the total doesn't exceed total_questions.
    #  Grant in descending weight order so the most important skills win.
    high_priority_skills = sorted(
        [s for s, w in weights.items() if w >= HIGH_PRIORITY_THRESHOLD and allocation[s] == 0],
        key=lambda s: weights[s],
        reverse=True,
    )
    budget_used = sum(allocation.values())
    for skill in high_priority_skills:
        if budget_used >= total_questions:
            break
        allocation[skill] = 1
        budget_used += 1

    # --- Step C: distribute remaining questions by largest remainder -----
    distributed = sum(allocation.values())
    remaining = total_questions - distributed

    if remaining > 0:
        remainders: List[Tuple[str, float]] = [
            (skill, ideal[skill] - allocation[skill])
            for skill in ideal
        ]
        # Sort descending by fractional remainder
        remainders.sort(key=lambda x: x[1], reverse=True)
        for i in range(min(remaining, len(remainders))):
            allocation[remainders[i][0]] += 1
    elif remaining < 0:
        # Over-allocated due to rounding: trim from lowest-weight skills
        over = -remaining
        trim_order = sorted(allocation, key=lambda s: weights[s])
        for skill in trim_order:
            if over <= 0:
                break
            removable = allocation[skill] - (1 if weights[skill] >= HIGH_PRIORITY_THRESHOLD else 0)
            take = min(removable, over)
            if take > 0:
                allocation[skill] -= take
                over -= take

    return allocation


# ---------------------------------------------------------------------------
# 4) Public API – Build Quiz Payload
# ---------------------------------------------------------------------------

def build_quiz_payload(
    student_profile: Dict[str, float],
    total_questions: int,
) -> List[Dict]:
    """
    Bridges the BKT mastery profile and the AI Quiz Generator by computing
    an optimal question distribution across skills.

    Parameters
    ----------
    student_profile : dict
        Mapping of skill names → mastery probabilities [0.0, 1.0].
    total_questions : int
        Total number of questions the quiz must contain.

    Returns
    -------
    list[dict]
        Each dict has:
          • "skill"      (str)  – skill name
          • "difficulty"  (int)  – target difficulty 1–5
          • "count"       (int)  – number of questions for this skill

        The sum of all "count" values is guaranteed to equal *total_questions*.
        Skills allocated 0 questions are omitted.
    """
    if not student_profile or total_questions <= 0:
        return []

    # 1. Compute per-skill priority weights
    weights: Dict[str, float] = {
        skill: _skill_priority_weight(mastery)
        for skill, mastery in student_profile.items()
    }

    # 2. Distribute questions
    allocation = _allocate_questions(weights, total_questions)

    # 3. Build the payload (skip zero-allocation skills)
    payload: List[Dict] = []
    for skill, count in allocation.items():
        if count <= 0:
            continue
        payload.append({
            "skill": skill,
            "difficulty": mastery_to_difficulty(student_profile[skill]),
            "count": count,
        })

    # 4. Sort payload: highest-count (most important) skills first
    payload.sort(key=lambda x: x["count"], reverse=True)

    return payload
