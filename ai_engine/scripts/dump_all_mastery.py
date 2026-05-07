import os
import sys
from uuid import UUID

# Add current directory to path so we can import app
sys.path.append(os.getcwd())

from app.services.rag.store import create_engine, text, settings

def dump_all_points(output_file):
    try:
        engine = create_engine(settings.POSTGRES_CONNECTION)
        with engine.connect() as conn:
            result = conn.execute(
                text("SELECT document_id, unit, lesson, point_text FROM mastery_points ORDER BY document_id, created_at ASC")
            )
            rows = result.fetchall()
            
        if not rows:
            print("No mastery points found in the database.")
            return

        lines = []
        lines.append(f"{'='*80}")
        lines.append(f" GLOBAL MASTERY POINTS DUMP")
        lines.append(f" Total Records: {len(rows)}")
        lines.append(f"{'='*80}\n")
        
        current_doc = None
        current_unit = None
        current_lesson = None
        
        for r in rows:
            doc_id, unit, lesson, text_val = r
            
            if doc_id != current_doc:
                lines.append(f"\n\n{'#'*80}")
                lines.append(f" DOCUMENT: {doc_id}")
                lines.append(f"{'#'*80}")
                current_doc = doc_id
                current_unit = None
                current_lesson = None
            
            unit = unit or "Uncategorized"
            lesson = lesson or "General"
            
            if unit != current_unit:
                lines.append(f"\n[ UNIT: {unit} ]")
                current_unit = unit
                current_lesson = None
            
            if lesson != current_lesson:
                lines.append(f"  > Lesson: {lesson}")
                current_lesson = lesson
            
            lines.append(f"    - {text_val}")
            
        lines.append(f"\n\n{'='*80}")
        lines.append(f" END OF DUMP")
        lines.append(f"{'='*80}\n")

        output_content = "\n".join(lines)
        
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(output_content)
        print(f"Successfully dumped {len(rows)} mastery points to {output_file}")

    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    output_filename = "all_mastery_points_dump.txt"
    dump_all_points(output_filename)
