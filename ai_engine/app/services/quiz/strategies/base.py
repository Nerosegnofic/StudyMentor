from abc import ABC, abstractmethod
from typing import List


class SubjectStrategy(ABC):
    """Interface every subject strategy must implement."""

    @property
    @abstractmethod
    def subject_key(self) -> str:
        """Short identifier: 'math', 'english', etc."""

    # ---- Prompt slot providers ----------------------------------------

    @abstractmethod
    def difficulty_scale(self) -> str:
        """Full difficulty scale text with subject-appropriate examples."""

    @abstractmethod
    def difficulty_violations(self) -> str:
        """What is explicitly WRONG at each difficulty level."""

    @abstractmethod
    def self_check_rules(self) -> str:
        """Self-check instructions for the LLM before finalizing questions."""

    @abstractmethod
    def formatting_rules(self) -> str:
        """Subject-specific formatting rules (math symbols, language, etc.)."""

    @abstractmethod
    def pedagogical_tone(self) -> str:
        """Language and tone instructions."""

    @abstractmethod
    def get_format_pool(self, difficulty: int) -> List[str]:
        """Return question formats appropriate for the given difficulty."""
