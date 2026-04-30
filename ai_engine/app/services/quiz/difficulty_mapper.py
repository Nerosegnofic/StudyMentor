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
