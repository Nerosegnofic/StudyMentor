from typing import List, Dict, Tuple
from app.models.schemas import QuestionSchema

def build_difficulty_map(payload: List[Dict]) -> Dict[str, int]:
    """
    Build a mapping from skill name -> requested difficulty from the BKT payload.
    Used for post-generation difficulty mismatch detection.
    """
    return {cfg["skill"]: cfg["difficulty"] for cfg in payload}

def _get_tolerance(requested_difficulty: int) -> int:
    """
    Returns the allowed tolerance for a given requested difficulty level.
    Extreme levels (1 = Very Easy, 5 = Very Hard) require an exact match
    because ±1 tolerance would blur the distinction with adjacent levels.
    Middle levels (2-4) allow ±1 tolerance.
    """
    if requested_difficulty in (1, 5):
        return 0  # Exact match required for Very Easy / Very Hard
    return 1      # ±1 tolerance for Easy / Medium / Hard

def filter_mismatched_questions(
    questions: List[QuestionSchema],
    difficulty_map: Dict[str, int],
    tolerance: int = 1,
) -> Tuple[List[QuestionSchema], int]:
    """
    Filters out questions whose difficulty doesn't match what was requested.

    Uses adaptive tolerance: exact match for extreme difficulties (1 and 5),
    ±1 for middle levels (2-4). The `tolerance` parameter is used as a
    maximum cap but the per-level tolerance may be stricter.

    Returns:
        (accepted_questions, dropped_count)
    """
    accepted = []
    dropped = 0
    for q in questions:
        requested_diff = difficulty_map.get(q.topic)
        if requested_diff is not None:
            effective_tolerance = min(tolerance, _get_tolerance(requested_diff))
            if abs(q.difficulty - requested_diff) > effective_tolerance:
                print(
                    f"[DifficultyGuard] Dropping question for topic='{q.topic}': "
                    f"requested difficulty={requested_diff}, got={q.difficulty} "
                    f"(tolerance={effective_tolerance})",
                    flush=True,
                )
                dropped += 1
            else:
                accepted.append(q)
        else:
            accepted.append(q)
    return accepted, dropped
