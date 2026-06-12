"""
Gamification service — all reward calculation and level-up business logic.

Called from routes_quizzes.py after a quiz is submitted.
All writes happen inside the caller's existing DB transaction.
"""
from datetime import datetime
from sqlalchemy.orm import Session

from app.repositories.gamification_repo import (
    get_or_create_student_gamification,
    update_student_gamification,
    log_xp_transaction,
    log_coin_transaction,
    log_streak_event,
    level_for_xp,
)


class GamificationService:
    """Stateless service — one instance is shared across requests."""

    # ── XP constants ──────────────────────────────────────────────────────
    XP_PER_CORRECT       = 10
    XP_PERFECT_BONUS     = 50
    XP_SPEED_BONUS       = 5
    XP_COMEBACK_BONUS    = 20
    XP_PERSISTENCE_BONUS = 5

    # ── Coin constants ────────────────────────────────────────────────────
    COINS_QUIZ_COMPLETION = 5
    COINS_FREEDOM_BONUS   = 5
    COINS_DAILY_LOGIN     = 3

    # ══════════════════════════════════════════════════════════════════════
    #  PUBLIC — called from the quiz submission route
    # ══════════════════════════════════════════════════════════════════════

    def process_quiz_rewards(
        self,
        db: Session,
        student_uid: str,
        quiz_session_id,
        *,
        correct_answers: int,
        total_questions: int,
        total_time_ms: int,
        quiz_context: str,  # "VOLUNTARY" | "FORCED"
        is_comeback: bool = False,
        client_local_date: str | None = None,
    ) -> dict:
        """
        Atomically:
          1. Calculate all XP and coin rewards for the quiz.
          2. Append individual transaction log rows.
          3. Update the student_gamification aggregate.
          4. Return a summary dict.

        The caller (routes_quizzes.py) is responsible for db.commit().
        """
        row = get_or_create_student_gamification(db, student_uid)
        old_level = row.current_level

        total_xp = 0
        total_coins = 0

        # ── XP rewards ───────────────────────────────────────────────────

        # 1. Base XP: +10 per correct answer
        base_xp = correct_answers * self.XP_PER_CORRECT
        if base_xp > 0:
            log_xp_transaction(db, student_uid, base_xp, "CORRECT_ANSWER", quiz_session_id)
            total_xp += base_xp

        # 2. Perfect quiz bonus: all correct
        if total_questions > 0 and correct_answers == total_questions:
            log_xp_transaction(db, student_uid, self.XP_PERFECT_BONUS, "PERFECT_QUIZ_BONUS", quiz_session_id)
            total_xp += self.XP_PERFECT_BONUS

        # 3. Speed bonus: finished under 1 minute per question
        if total_questions > 0:
            target_ms = total_questions * 60 * 1000  # 1 min per question
            if 0 < total_time_ms <= target_ms:
                log_xp_transaction(db, student_uid, self.XP_SPEED_BONUS, "SPEED_BONUS", quiz_session_id)
                total_xp += self.XP_SPEED_BONUS

        # 4. Comeback bonus
        if is_comeback:
            log_xp_transaction(db, student_uid, self.XP_COMEBACK_BONUS, "COMEBACK_BONUS", quiz_session_id)
            total_xp += self.XP_COMEBACK_BONUS

        # 5. Persistence bonus (forced quiz)
        if quiz_context == "FORCED":
            log_xp_transaction(db, student_uid, self.XP_PERSISTENCE_BONUS, "PERSISTENCE_BONUS", quiz_session_id)
            total_xp += self.XP_PERSISTENCE_BONUS

        # ── Coin rewards ─────────────────────────────────────────────────

        # Base completion reward
        log_coin_transaction(db, student_uid, self.COINS_QUIZ_COMPLETION, "QUIZ_COMPLETION")
        total_coins += self.COINS_QUIZ_COMPLETION

        # Freedom bonus for forced quizzes
        if quiz_context == "FORCED":
            log_coin_transaction(db, student_uid, self.COINS_FREEDOM_BONUS, "FREEDOM_BONUS")
            total_coins += self.COINS_FREEDOM_BONUS

        # ── Update aggregate ─────────────────────────────────────────────
        update_student_gamification(db, row, xp_delta=total_xp, coins_delta=total_coins)

        # ── Streak Logic ─────────────────────────────────────────────────
        streak_result = self.update_streak(db, student_uid, row, client_local_date)
        milestone_coins = 0
        milestone_hit = None
        if streak_result.get("incremented", False):
            milestone_hit, milestone_coins = self.check_streak_milestone(db, student_uid, row.current_streak)
            if milestone_coins > 0:
                total_coins += milestone_coins
                row.coins_total += milestone_coins
                update_student_gamification(db, row, coins_delta=milestone_coins)

        new_level = row.current_level
        did_level_up = new_level > old_level

        print(
            f"[Gamification] student={student_uid} "
            f"xp_earned={total_xp} coins_earned={total_coins} "
            f"level={old_level}->{new_level} level_up={did_level_up}",
            flush=True,
        )

        # Calculate next milestone
        next_milestone = None
        next_milestone_days_away = None
        for m in [3, 7, 14, 30]:
            if row.current_streak < m:
                next_milestone = m
                next_milestone_days_away = m - row.current_streak
                break

        return {
            "xp_earned": total_xp,
            "coins_earned": total_coins,
            "xp_total": row.xp_total,
            "coins_total": row.coins_total,
            "old_level": old_level,
            "new_level": new_level,
            "did_level_up": did_level_up,
            "streak_incremented": streak_result.get("incremented", False),
            "milestone_hit": milestone_hit,
            "current_streak": row.current_streak,
            "longest_streak": row.longest_streak,
            "last_quiz_date": row.last_quiz_date.isoformat() if row.last_quiz_date else None,
            "next_milestone": next_milestone,
            "next_milestone_days_away": next_milestone_days_away,
        }

    # ══════════════════════════════════════════════════════════════════════
    #  Streak Management
    # ══════════════════════════════════════════════════════════════════════

    def update_streak(self, db: Session, student_uid: str, row, client_local_date: str | None = None) -> dict:
        """
        Updates the streak based on the client's local date (if provided) or UTC.
        Returns a dict indicating if the streak was incremented.
        """
        today = datetime.utcnow().date()
        if client_local_date:
            try:
                today = datetime.strptime(client_local_date, "%Y-%m-%d").date()
            except ValueError:
                pass
        
        result = {"incremented": False}

        if row.last_quiz_date == today:
            # Already completed a quiz today
            return result

        if row.last_quiz_date is None:
            # First quiz ever
            row.current_streak = 1
            row.longest_streak = 1
            log_streak_event(db, student_uid, "INCREMENT", row.current_streak)
            result["incremented"] = True
        else:
            delta_days = (today - row.last_quiz_date).days
            if delta_days == 1:
                # Quiz completed yesterday
                row.current_streak += 1
                if row.current_streak > row.longest_streak:
                    row.longest_streak = row.current_streak
                log_streak_event(db, student_uid, "INCREMENT", row.current_streak)
                result["incremented"] = True
            elif delta_days > 1:
                # Streak broken
                log_streak_event(db, student_uid, "BREAK", row.current_streak)
                row.current_streak = 1
                log_streak_event(db, student_uid, "INCREMENT", row.current_streak)
                result["incremented"] = True

        row.last_quiz_date = today
        return result

    def check_streak_milestone(self, db: Session, student_uid: str, current_streak: int) -> tuple[int | None, int]:
        """
        Checks if the current streak hits a milestone (3, 7, 14, 30 days).
        Awards coins if a milestone is reached.
        Returns (milestone_days, coin_amount).
        """
        MILESTONES = {
            3: 20,
            7: 35,
            14: 50,
            30: 100,
        }

        if current_streak in MILESTONES:
            # In v1 we rely on the DB transaction to ensure this runs once per increment
            # A more robust check would query streak_events to see if this milestone was already rewarded
            reward = MILESTONES[current_streak]
            log_coin_transaction(db, student_uid, reward, "STREAK_MILESTONE")
            return current_streak, reward
        
        return None, 0

    # ══════════════════════════════════════════════════════════════════════
    #  Daily login check
    # ══════════════════════════════════════════════════════════════════════

    def check_daily_login(self, db: Session, student_uid: str, client_local_date: str | None = None) -> dict | None:
        """
        Award +3 coins if the student hasn't logged in today.
        Returns the reward dict or None if already awarded.
        """
        row = get_or_create_student_gamification(db, student_uid)

        today = datetime.utcnow().date()
        if client_local_date:
            try:
                today = datetime.strptime(client_local_date, "%Y-%m-%d").date()
            except ValueError:
                pass

        if row.last_login_date == today:
            return None

        # Award daily login coins
        log_coin_transaction(db, student_uid, self.COINS_DAILY_LOGIN, "DAILY_LOGIN")
        row.coins_total += self.COINS_DAILY_LOGIN
        # BUG FIX: Streaks represent consecutive days of *learning* (quizzes). 
        # Just logging in should NOT increment the streak, otherwise it increments twice on quiz days.
        row.last_active_at = datetime.utcnow()
        row.last_login_date = today
        row.updated_at = datetime.utcnow()

        return {
            "coins_earned": self.COINS_DAILY_LOGIN,
            "coins_total": row.coins_total,
            "current_streak": row.current_streak,
        }

    # ══════════════════════════════════════════════════════════════════════
    #  Spend coins
    # ══════════════════════════════════════════════════════════════════════

    def spend_coins(self, db: Session, student_uid: str, amount: int, reason: str) -> dict:
        """
        Deducts coins from the student's balance for a purchase.
        Raises ValueError if insufficient funds.
        """
        if amount <= 0:
            raise ValueError("Amount to spend must be strictly positive.")

        row = get_or_create_student_gamification(db, student_uid)
        
        if row.coins_total < amount:
            raise ValueError(f"Insufficient coins. Have {row.coins_total}, need {amount}.")

        log_coin_transaction(db, student_uid, -amount, reason)
        row.coins_total -= amount
        row.updated_at = datetime.utcnow()

        return {
            "coins_total": row.coins_total,
            "amount_spent": amount,
        }

    # ══════════════════════════════════════════════════════════════════════
    #  Profile read
    # ══════════════════════════════════════════════════════════════════════

    def get_student_profile(self, db: Session, student_uid: str) -> dict:
        """Return the full gamification profile for the API response."""
        row = get_or_create_student_gamification(db, student_uid)

        # Fetch next level info
        from app.repositories.gamification_repo import get_all_levels
        from app.models.domain.quiz import QuestionResponse
        
        levels = get_all_levels(db)
        level_name = "Seedling"
        next_level_xp = None
        progress_percent = 100.0

        for lvl in levels:
            if lvl.level_number == row.current_level:
                level_name = lvl.level_name

        # Find XP for current and next level
        current_xp_threshold = 0
        for lvl in levels:
            if lvl.level_number == row.current_level:
                current_xp_threshold = lvl.xp_required
            if lvl.level_number == row.current_level + 1:
                next_level_xp = lvl.xp_required

        if next_level_xp is not None:
            xp_range = next_level_xp - current_xp_threshold
            if xp_range > 0:
                xp_into_level = row.xp_total - current_xp_threshold
                progress_percent = min((xp_into_level / xp_range) * 100, 100.0)
            else:
                progress_percent = 100.0

        next_milestone = None
        next_milestone_days_away = None
        
        for m in [3, 7, 14, 30]:
            if row.current_streak < m:
                next_milestone = m
                next_milestone_days_away = m - row.current_streak
                break

        total_questions_answered = (
            db.query(QuestionResponse)
            .filter(QuestionResponse.student_uid == student_uid)
            .count()
        )

        return {
            "student_uid": student_uid,
            "xp_total": row.xp_total,
            "coins_total": row.coins_total,
            "current_level": row.current_level,
            "level_name": level_name,
            "next_level_xp": next_level_xp,
            "progress_percent": round(progress_percent, 1),
            "current_streak": row.current_streak,
            "longest_streak": row.longest_streak,
            "last_quiz_date": row.last_quiz_date.isoformat() if row.last_quiz_date else None,
            "next_milestone": next_milestone,
            "next_milestone_days_away": next_milestone_days_away,
            "total_questions_answered": total_questions_answered,
        }
