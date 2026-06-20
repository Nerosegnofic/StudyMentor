def mastery_to_difficulty(mastery: float) -> int:
    """
    Converts a BKT mastery probability (0.0 – 1.0) into a target difficulty
    level (1–5) using Zone of Proximal Development thresholds.

    Mastery < 0.20    → Difficulty 1  (Very Easy)
    Mastery 0.20–0.39 → Difficulty 2  (Easy)
    Mastery 0.40–0.59 → Difficulty 3  (Medium)
    Mastery 0.60–0.79 → Difficulty 4  (Hard)
    Mastery 0.80+     → Difficulty 5  (Very Hard)
    """
    if mastery < 0.20:
        return 1
    elif mastery < 0.40:
        return 2
    elif mastery < 0.60:
        return 3
    elif mastery < 0.80:
        return 4
    else:
        return 5
