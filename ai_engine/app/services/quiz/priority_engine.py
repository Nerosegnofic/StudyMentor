import math

def compute_skill_priority_weight(mastery: float) -> float:
    """
    Computes a continuous priority weight for a single skill based on its
    mastery level.  Uses a Gaussian-like bell curve centred at 0.50 mastery
    so that skills in the active-learning zone (≈ 0.20 – 0.85) receive the
    highest weight, with a peak at 50 % mastery.

    Three priority tiers are blended:
      • Active learning  (0.20 ≤ m ≤ 0.85) → peak weight via Gaussian
      • Brand-new skills (m < 0.20)         → moderate baseline
      • Mastered skills  (m > 0.95)         → small review floor
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
