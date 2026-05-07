import os
import sys
from uuid import UUID

# Add current directory to path so we can import app
sys.path.append(os.getcwd())

from app.services.rag.store import get_mastery_points

def view_points(doc_id_str, output_file=None, source_filter=None):
    try:
        doc_id = UUID(doc_id_str)
        points = get_mastery_points(doc_id, source=source_filter)
        
        if not points:
            label = f" (source={source_filter})" if source_filter else ""
            print(f"No mastery points found for document: {doc_id_str}{label}")
            return

        lines = []
        source_label = f" [{source_filter}]" if source_filter else " [all sources]"
        lines.append(f"{'='*60}")
        lines.append(f" Mastery Points for Document: {doc_id_str}{source_label}")
        lines.append(f"{'='*60}\n")
        
        current_unit = None
        current_lesson = None
        
        for p in points:
            unit = p.get('unit') or "Uncategorized"
            lesson = p.get('lesson') or "General"
            text = p.get('point_text')
            skill_id = p.get('skill_id')
            src = p.get('source', 'regex')
            
            if unit != current_unit:
                lines.append(f"\n[ UNIT: {unit} ]")
                current_unit = unit
                current_lesson = None
            
            if lesson != current_lesson:
                lines.append(f"  > Lesson: {lesson}")
                current_lesson = lesson
            
            # Show skill_id if present (LLM-refined points have them)
            id_tag = f" [{skill_id}]" if skill_id else ""
            src_tag = f" ({src})" if not source_filter else ""
            lines.append(f"    - {text}{id_tag}{src_tag}")
            
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
    
    # Usage:
    #   python view_mastery.py <doc_id>                          -- show all
    #   python view_mastery.py <doc_id> --source regex           -- show regex only
    #   python view_mastery.py <doc_id> --source llm_refined     -- show refined only
    #   python view_mastery.py <doc_id> output.txt               -- save to file
    #   python view_mastery.py <doc_id> output.txt --source llm_refined
    
    if len(sys.argv) < 2:
        target_id = "4e87ba1b-582c-4102-bdae-7b86c4a9d3b2"
        print(f"No ID provided, defaulting to: {target_id}")
        view_points(target_id)
    else:
        doc_id = sys.argv[1]
        output_file = None
        source_filter = None
        
        # Parse remaining args
        i = 2
        while i < len(sys.argv):
            if sys.argv[i] == "--source" and i + 1 < len(sys.argv):
                source_filter = sys.argv[i + 1]
                i += 2
            else:
                output_file = sys.argv[i]
                i += 1
        
        view_points(doc_id, output_file, source_filter)
