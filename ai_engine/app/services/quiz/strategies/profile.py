"""
Subject prompt profile.

Per-subject quiz-prompt customization is *data*, not behavior — each subject only
supplies constant text for a fixed set of prompt slots plus difficulty→format pools.
So it is modeled as a frozen dataclass (a config record), not a class hierarchy. Each
subject module defines one `PROFILE = SubjectProfile(...)`; `strategy_resolver` maps a
subject name to the right profile.
"""
from dataclasses import dataclass
from typing import Dict, List


@dataclass(frozen=True)
class SubjectProfile:
    subject_key: str                       # short id: 'math', 'english', ...
    difficulty_scale: str                  # full difficulty scale text with examples
    difficulty_violations: str             # what is explicitly WRONG at each level
    self_check_rules: str                  # self-check instructions for the LLM
    formatting_rules: str                  # subject-specific formatting rules
    pedagogical_tone: str                  # language and tone instructions
    format_pools: Dict[int, List[str]]     # difficulty (1-5) -> question formats

    def format_pool(self, difficulty: int) -> List[str]:
        """Question formats appropriate for the given difficulty (defaults to Medium)."""
        return self.format_pools.get(difficulty, self.format_pools[3])