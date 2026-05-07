import math
from typing import List, Dict

class IRTEngine:
    """
    Item Response Theory (IRT) Engine.
    Estimates a student's latent ability (Theta) and calibrates item parameters.
    Focuses on the "What": assessing ability and question quality.
    """
    
    def calculate_probability_of_success(self, theta: float, b: float, a: float = 1.0, c: float = 0.0) -> float:
        """
        3-Parameter Logistic (3PL) Model:
        P(correct) = c + (1 - c) / (1 + exp(-a * (theta - b)))
        
        theta: Student ability
        b: Item difficulty
        a: Item discrimination (default 1.0)
        c: Guessing parameter (default 0.0)
        """
        exponent = -a * (theta - b)
        # Avoid overflow in exp
        exponent = max(-100, min(100, exponent))
        return c + (1.0 - c) / (1.0 + math.exp(exponent))

    def estimate_theta(self, current_theta: float, responses: List[Dict[str, any]]) -> float:
        """
        Simplified Maximum Likelihood Estimation (MLE) or standard scoring update.
        responses: List of dicts with {'difficulty': float, 'correct': bool}
        """
        if not responses:
            return current_theta
            
        # Standard IRT update logic:
        # If they get a hard question right, theta goes up more.
        # If they get an easy question wrong, theta goes down more.
        new_theta = current_theta
        for resp in responses:
            b = resp.get('difficulty', 3.0) # Difficulty scale (e.g. 1-5)
            correct = resp.get('correct', False)
            
            p = self.calculate_probability_of_success(new_theta, b)
            
            # Learning rate/step for theta updates
            step_size = 0.3
            if correct:
                new_theta += step_size * (1 - p)
            else:
                new_theta -= step_size * p
                
        # Clamp theta typically between -4 and +4
        return max(-4.0, min(4.0, new_theta))

    def calibrate_item_difficulty(self, current_b: float, student_thetas: List[float], outcomes: List[bool]) -> float:
        """
        Adjusts the difficulty parameter (b) of a question based on how 
        students with known abilities performed on it.
        """
        if not student_thetas or len(student_thetas) != len(outcomes):
            return current_b
            
        # If high-ability students are failing, b is too low (harder than expected)
        # If low-ability students are passing, b is too high (easier than expected)
        # For simplicity, we adjust b based on the average residual
        adjustment = 0.0
        for theta, correct in zip(student_thetas, outcomes):
            p = self.calculate_probability_of_success(theta, current_b)
            actual = 1.0 if correct else 0.0
            adjustment += (p - actual)
            
        return current_b + (adjustment / len(student_thetas))
