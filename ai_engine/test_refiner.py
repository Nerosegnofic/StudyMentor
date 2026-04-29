"""
Standalone script to test the mastery refiner.

Can work in two modes:
  1. DB mode: reads raw points from database (requires PostgreSQL)
  2. File mode: reads raw points from a mastery text file (no DB needed)

Usage:
    python test_refiner.py <document_id>                          # DB mode
    python test_refiner.py <document_id> --save                   # DB mode + save
    python test_refiner.py <document_id> --from-file mastery.txt  # File mode
    python test_refiner.py <document_id> refined_output.txt       # Save to file
"""
import os
import re
import sys

sys.path.append(os.getcwd())

if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

from uuid import UUID
from app.services.rag.processors.mastery_refiner import refine_mastery_points


def parse_mastery_file(filepath: str) -> list:
    """Parse a mastery_points_*.txt file back into the grouped format."""
    grouped = []
    current_unit = None
    current_lesson = None
    current_objectives = []
    
    with open(filepath, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.rstrip('\n\r')
            
            # Unit header: [ UNIT: ... ]
            unit_match = re.match(r'^\[ UNIT: (.+) \]$', line.strip())
            if unit_match:
                # Save previous lesson
                if current_lesson and current_objectives:
                    grouped.append({
                        'unit': current_unit,
                        'lesson': current_lesson,
                        'objectives': current_objectives,
                    })
                current_unit = unit_match.group(1)
                current_lesson = None
                current_objectives = []
                continue
            
            # Lesson header:   > Lesson: ...
            lesson_match = re.match(r'^\s*> Lesson: (.+)$', line)
            if lesson_match:
                # Save previous lesson
                if current_lesson and current_objectives:
                    grouped.append({
                        'unit': current_unit,
                        'lesson': current_lesson,
                        'objectives': current_objectives,
                    })
                current_lesson = lesson_match.group(1)
                current_objectives = []
                continue
            
            # Objective:     - ...
            obj_match = re.match(r'^\s+-\s+(.+)$', line)
            if obj_match:
                current_objectives.append(obj_match.group(1).strip())
    
    # Don't forget the last one
    if current_lesson and current_objectives:
        grouped.append({
            'unit': current_unit or 'Unknown',
            'lesson': current_lesson,
            'objectives': current_objectives,
        })
    
    return grouped


def main():
    if len(sys.argv) < 2:
        print("Usage: python test_refiner.py <document_id> [--from-file mastery.txt] [--save] [output.txt]")
        sys.exit(1)
    
    doc_id_str = sys.argv[1]
    save_to_db = "--save" in sys.argv
    from_file = None
    output_file = None
    
    # Parse args
    i = 2
    while i < len(sys.argv):
        if sys.argv[i] == "--from-file" and i + 1 < len(sys.argv):
            from_file = sys.argv[i + 1]
            i += 2
        elif sys.argv[i] == "--save":
            i += 1
        else:
            output_file = sys.argv[i]
            i += 1
    
    doc_id = UUID(doc_id_str)
    
    # Step 1: Get raw mastery points
    if from_file:
        print(f"Reading raw points from file: {from_file}")
        raw_mastery_data = parse_mastery_file(from_file)
    else:
        # DB mode
        from app.services.rag.store import get_mastery_points, save_mastery_points as db_save
        raw_points = get_mastery_points(doc_id, source="regex")
        if not raw_points:
            raw_points = get_mastery_points(doc_id)
        
        if not raw_points:
            print(f"No mastery points found for document: {doc_id_str}")
            sys.exit(1)
        
        # Regroup into objective-extractor format
        grouped = {}
        for p in raw_points:
            key = (p['unit'], p['lesson'])
            if key not in grouped:
                grouped[key] = {'unit': p['unit'], 'lesson': p['lesson'], 'objectives': []}
            grouped[key]['objectives'].append(p['point_text'])
        raw_mastery_data = list(grouped.values())
    
    raw_total = sum(len(e['objectives']) for e in raw_mastery_data)
    print(f"Loaded {raw_total} raw mastery points across {len(raw_mastery_data)} lesson groups.\n")
    
    # Step 2: Load markdown for TOC context
    md_path = f"debug_{doc_id_str}.md"
    if os.path.exists(md_path):
        with open(md_path, "r", encoding="utf-8") as f:
            markdown_text = f.read()
        print(f"Loaded markdown from {md_path}\n")
    else:
        print(f"Warning: {md_path} not found. Proceeding without TOC context.\n")
        markdown_text = ""
    
    # Step 3: Run the refiner
    refined = refine_mastery_points(raw_mastery_data, markdown_text)
    
    # Step 4: Display results
    lines = []
    lines.append(f"\n{'='*60}")
    lines.append(f" REFINED Mastery Points for Document: {doc_id_str}")
    lines.append(f"{'='*60}\n")
    
    total = 0
    for entry in refined:
        lines.append(f"\n[ UNIT: {entry['unit']} ]")
        lines.append(f"  > Lesson: {entry['lesson']}")
        skill_ids = entry.get('skill_ids', [])
        for i, obj in enumerate(entry['objectives']):
            sid = skill_ids[i] if i < len(skill_ids) else "?"
            lines.append(f"    - [{sid}] {obj}")
            total += 1
    
    lines.append(f"\nTotal refined skills: {total}")
    lines.append(f"{'='*60}\n")
    
    output_content = "\n".join(lines)
    print(output_content)
    
    if output_file:
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(output_content)
        print(f"\nSaved to {output_file}")
    
    # Step 5: Optionally save to DB
    if save_to_db and not from_file:
        if refined is not raw_mastery_data:
            db_save(refined, doc_id, source="llm_refined")
            print(f"\n✓ Saved {total} refined points to database (source=llm_refined)")
        else:
            print("\n⚠ Refinement fell back to raw data — not saving duplicate to DB.")


if __name__ == "__main__":
    main()
