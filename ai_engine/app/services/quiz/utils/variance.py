import random
import string
from typing import List
from app.services.quiz.strategies import SubjectProfile

def generate_variance_block(
    strategy: SubjectProfile,
    difficulty_levels: List[int] = None,
) -> str:
    """
    Generate a unique variance seed and difficulty-appropriate question format
    requirements for each quiz generation call.

    Format pools are provided by the subject profile, ensuring that only
    subject- and difficulty-appropriate formats are selected.

    Args:
        strategy: The resolved SubjectProfile providing format pools.
        difficulty_levels: Difficulty levels present in this quiz.
    """
    seed = ''.join(random.choices(string.ascii_uppercase + string.digits, k=8))

    # Build per-difficulty format instructions
    if difficulty_levels:
        unique_levels = sorted(set(difficulty_levels))
    else:
        unique_levels = [3]  # Default to medium if unknown

    format_lines = []
    for level in unique_levels:
        pool = strategy.format_pool(level)
        chosen = random.sample(pool, k=min(2, len(pool)))
        label = {1: "Very Easy", 2: "Easy", 3: "Medium", 4: "Hard", 5: "Very Hard"}.get(level, "Medium")
        for fmt in chosen:
            format_lines.append(f"  - For Difficulty {level} ({label}) questions: {fmt}")

    return (
        f"\n\nVARIANCE SEED: {seed}\n"
        "For this specific generation, use these question formats matched to each difficulty level:\n"
        + "\n".join(format_lines)
        + "\n\nIMPORTANT: Only use formats appropriate for each question's difficulty level. "
        "Do NOT reuse examples from the context. Generate fresh, novel content for every question."
    )
