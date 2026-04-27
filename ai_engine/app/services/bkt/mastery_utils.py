def mastery_to_difficulty(mastery: float) -> int:
    """
    Converts a BKT mastery probability (0.0 - 1.0) into a target difficulty level (1-5).
    
    The mapping is inversely proportional: low mastery → easy questions,
    high mastery → hard questions. This ensures students are challenged 
    appropriately without being overwhelmed.
    
    Mastery 0.00–0.20 → Difficulty 1  (Very Easy)
    Mastery 0.20–0.40 → Difficulty 2  (Easy)
    Mastery 0.40–0.60 → Difficulty 3  (Medium)
    Mastery 0.60–0.80 → Difficulty 4  (Hard)
    Mastery 0.80–1.00 → Difficulty 5  (Very Hard)
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
