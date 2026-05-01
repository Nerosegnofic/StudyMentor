import os
import sys
import json
from uuid import UUID

# Add current directory to path so we can import app
sys.path.append(os.getcwd())

from app.services.rag.store import create_engine, text, settings

def dump_chunks(output_file, doc_id_filter=None):
    try:
        engine = create_engine(settings.POSTGRES_CONNECTION)
        with engine.connect() as conn:
            # Query the LangChain PGVector table
            if doc_id_filter:
                query = text("SELECT document, cmetadata FROM langchain_pg_embedding WHERE cmetadata->>'document_id' = :doc_id ORDER BY id ASC")
                result = conn.execute(query, {"doc_id": str(doc_id_filter)})
            else:
                query = text("SELECT document, cmetadata FROM langchain_pg_embedding ORDER BY id ASC")
                result = conn.execute(query)
                
            rows = result.fetchall()
            
        if not rows:
            print(f"No chunks found in the database{' for document ' + str(doc_id_filter) if doc_id_filter else ''}.")
            return

        lines = []
        lines.append(f"{'='*80}")
        lines.append(f" VECTOR STORE CHUNKS DUMP")
        if doc_id_filter:
            lines.append(f" Document ID: {doc_id_filter}")
        lines.append(f" Total Chunks: {len(rows)}")
        lines.append(f"{'='*80}\n")
        
        for i, r in enumerate(rows):
            content, metadata_json = r
            
            # Metadata is usually a dict or stringified JSON
            metadata = metadata_json if isinstance(metadata_json, dict) else json.loads(metadata_json)
            
            doc_id = metadata.get('document_id', 'Unknown')
            unit = metadata.get('parent_unit', 'Unknown')
            concept = metadata.get('parent_concept', '')
            lesson = metadata.get('parent_lesson', 'Unknown')
            role = metadata.get('chunk_role', 'Unknown')
            page = metadata.get('page_number', 'Unknown')
            
            lines.append(f"--- CHUNK {i+1} [Doc: {doc_id}] ---")
            context_parts = [f"Unit: {unit or 'Unknown'}"]
            if concept:
                context_parts.append(f"Concept: {concept}")
            context_parts.append(f"Lesson: {lesson or 'Unknown'}")
            context_parts.append(f"Role: {role}")
            lines.append(f"Context: {' | '.join(context_parts)}")
            lines.append(f"Full Metadata: {json.dumps(metadata, ensure_ascii=False)}")
            lines.append("-" * 40)
            lines.append(f"{content.strip()}")
            lines.append("\n")
            
        lines.append(f"\n\n{'='*80}")
        lines.append(f" END OF CHUNKS DUMP")
        lines.append(f"{'='*80}\n")

        output_content = "\n".join(lines)
        
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(output_content)
        print(f"Successfully dumped {len(rows)} chunks to {output_file}")

    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    if len(sys.argv) == 3:
        # ID and Filename provided
        dump_chunks(sys.argv[2], sys.argv[1])
    elif len(sys.argv) == 2:
        # Only ID or Filename provided - interpret as ID if UUID-like
        try:
            val = sys.argv[1]
            UUID(val)
            dump_chunks("chunks_dump.txt", val)
        except:
            dump_chunks(sys.argv[1])
    else:
        dump_chunks("all_chunks_dump.txt")
