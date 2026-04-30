import uuid
from uuid import UUID
from typing import List, Dict
from sqlalchemy import create_engine, text
from app.core.config import settings

def save_mastery_points(mastery_data: List[Dict], document_id: UUID, source: str = "regex"):
    """
    Saves extracted mastery points to the database.
    """
    engine = create_engine(settings.POSTGRES_CONNECTION)
    
    with engine.begin() as conn:
        # 1. Clear old mastery points for this document and source
        conn.execute(
            text("DELETE FROM mastery_points WHERE document_id = :doc_id AND source = :source"),
            {"doc_id": document_id, "source": source}
        )
        
        # 2. Insert new points
        total = 0
        for entry in mastery_data:
            unit = entry.get('unit', 'Unknown')
            lesson = entry.get('lesson', 'Unknown')
            objectives = entry.get('objectives', [])
            skill_ids = entry.get('skill_ids', [])
            
            for idx, point in enumerate(objectives):
                sid = skill_ids[idx] if idx < len(skill_ids) else None
                conn.execute(
                    text("INSERT INTO mastery_points (id, document_id, unit, lesson, skill_id, point_text, source) "
                         "VALUES (:id, :doc_id, :unit, :lesson, :skill_id, :point, :source)"),
                    {
                        "id": uuid.uuid4(),
                        "doc_id": document_id,
                        "unit": unit,
                        "lesson": lesson,
                        "skill_id": sid,
                        "point": point,
                        "source": source,
                    }
                )
                total += 1
    print(f"[{document_id}] Successfully saved {total} mastery points (source={source}) to database!", flush=True)

def get_mastery_points(document_id: UUID, source: str = None) -> List[Dict]:
    """
    Retrieves mastery points for a given document.
    """
    engine = create_engine(settings.POSTGRES_CONNECTION)
    with engine.connect() as conn:
        if source:
            result = conn.execute(
                text("SELECT unit, lesson, skill_id, point_text, source FROM mastery_points "
                     "WHERE document_id = :doc_id AND source = :source ORDER BY created_at ASC"),
                {"doc_id": document_id, "source": source}
            )
        else:
            result = conn.execute(
                text("SELECT unit, lesson, skill_id, point_text, source FROM mastery_points "
                     "WHERE document_id = :doc_id ORDER BY created_at ASC"),
                {"doc_id": document_id}
            )
        return [
            {"unit": row[0], "lesson": row[1], "skill_id": row[2], "point_text": row[3], "source": row[4]}
            for row in result
        ]

def delete_mastery_points(document_id: UUID):
    """
    Deletes all mastery points associated with a specific document.
    """
    engine = create_engine(settings.POSTGRES_CONNECTION)
    with engine.begin() as conn:
        conn.execute(
            text("DELETE FROM mastery_points WHERE document_id = :doc_id"),
            {"doc_id": document_id}
        )

def clear_mastery_points():
    """
    Wipes the mastery_points table.
    """
    engine = create_engine(settings.POSTGRES_CONNECTION)
    with engine.begin() as conn:
        conn.execute(text("TRUNCATE mastery_points CASCADE;"))
    print("Mastery points table cleared!", flush=True)
