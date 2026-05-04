import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.core.database import init_db

if __name__ == "__main__":
    print("Initializing Database to test schema...")
    init_db()
    print("Success!")
