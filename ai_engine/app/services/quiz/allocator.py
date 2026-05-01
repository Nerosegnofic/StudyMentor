from typing import Dict, List, Tuple

def allocate_questions(
    weights: Dict[str, float],
    total_questions: int,
) -> Dict[str, int]:
    """
    Distributes *total_questions* across skills proportionally to their
    priority weights using the **Largest-Remainder Method** (Hamilton's
    method) to guarantee the sum equals exactly *total_questions*.
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
    HIGH_PRIORITY_THRESHOLD = 0.25
    allocation: Dict[str, int] = {}
    for skill, frac in ideal.items():
        allocation[skill] = int(frac)

    # --- Step B2: guarantee ≥ 1 for high-priority skills (budget-aware) --
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
        remainders.sort(key=lambda x: x[1], reverse=True)
        for i in range(min(remaining, len(remainders))):
            allocation[remainders[i][0]] += 1
    elif remaining < 0:
        # Over-allocated: trim from lowest-weight skills
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
