import os
import sys
from uuid import UUID

# Add current directory to path so we can import app
sys.path.append(os.getcwd())

from app.services.rag.store import get_mastery_points

def view_points(doc_id_str, output_file=None):
    try:
        doc_id = UUID(doc_id_str)
        points = get_mastery_points(doc_id)
        
        if not points:
            print(f"No mastery points found for document: {doc_id_str}")
            return

        lines = []
        lines.append(f"{'='*60}")
        lines.append(f" Mastery Points for Document: {doc_id_str}")
        lines.append(f"{'='*60}\n")
        
        current_unit = None
        current_lesson = None
        
        for p in points:
            unit = p.get('unit') or "Uncategorized"
            lesson = p.get('lesson') or "General"
            text = p.get('point_text')
            
            if unit != current_unit:
                lines.append(f"\n[ UNIT: {unit} ]")
                current_unit = unit
                current_lesson = None
            
            if lesson != current_lesson:
                lines.append(f"  > Lesson: {lesson}")
                current_lesson = lesson
            
            lines.append(f"    - {text}")
            
        lines.append(f"\nTotal points: {len(points)}")
        lines.append(f"{'='*60}\n")

        output_content = "\n".join(lines)
        
        if output_file:
            with open(output_file, 'w', encoding='utf-8') as f:
                f.write(output_content)
            print(f"Saved mastery points to {output_file}")
        else:
            print(output_content)

    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    # Ensure terminal can handle Arabic/Unicode
    if hasattr(sys.stdout, 'reconfigure'):
        sys.stdout.reconfigure(encoding='utf-8')
    
    if len(sys.argv) < 2:
        # Default to the one in your logs if none provided
        target_id = "4e87ba1b-582c-4102-bdae-7b86c4a9d3b2"
        print(f"No ID provided, defaulting to: {target_id}")
        view_points(target_id)
    elif len(sys.argv) == 3:
        view_points(sys.argv[1], sys.argv[2])
    else:
        view_points(sys.argv[1])
