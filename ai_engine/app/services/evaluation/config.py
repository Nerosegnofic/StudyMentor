from dataclasses import dataclass

@dataclass
class BKTConfig:
    base_guess: float = 0.20
    base_slip: float = 0.10
    min_prob: float = 0.01
    max_prob: float = 0.95
    forgetting_rate: float = 0.995