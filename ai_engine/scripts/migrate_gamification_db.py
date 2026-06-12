import os
import sys

# Add ai_engine to Python path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from sqlalchemy import text
from app.core.database import SessionLocal, engine

def migrate():
    print("Starting gamification database migration...")
    db = SessionLocal()
    try:
        # Add columns to student_gamification
        statements = [
            "ALTER TABLE student_gamification ADD COLUMN IF NOT EXISTS current_streak INTEGER NOT NULL DEFAULT 0;",
            "ALTER TABLE student_gamification ADD COLUMN IF NOT EXISTS longest_streak INTEGER NOT NULL DEFAULT 0;",
            "ALTER TABLE student_gamification ADD COLUMN IF NOT EXISTS last_quiz_date DATE;",
            "ALTER TABLE student_gamification ADD COLUMN IF NOT EXISTS last_login_date DATE;",
            "ALTER TABLE student_gamification ADD COLUMN IF NOT EXISTS last_active_at TIMESTAMP;",
        ]
        
        for stmt in statements:
            try:
                db.execute(text(stmt))
                print(f"Executed: {stmt}")
            except Exception as e:
                print(f"Error executing '{stmt}': {e}")
                db.rollback()
        
        db.commit()

        # Create streak_events table if it doesn't exist
        streak_events_stmt = """
        CREATE TABLE IF NOT EXISTS streak_events (
            id UUID PRIMARY KEY,
            student_uid VARCHAR NOT NULL,
            event_type VARCHAR NOT NULL,
            streak_value INTEGER NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
        """
        try:
            db.execute(text(streak_events_stmt))
            print("Executed: CREATE TABLE IF NOT EXISTS streak_events")
            
            # Create index for fast lookups
            db.execute(text("CREATE INDEX IF NOT EXISTS ix_streak_events_student_uid ON streak_events (student_uid);"))
            print("Executed: CREATE INDEX ix_streak_events_student_uid")
        except Exception as e:
            print(f"Error creating streak_events table: {e}")
            db.rollback()

        db.commit()
        print("Gamification database migration complete!")
    finally:
        db.close()

if __name__ == "__main__":
    migrate()
