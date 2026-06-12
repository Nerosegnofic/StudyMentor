from app.core.database import SessionLocal
from app.models.domain.curriculum import Skill
from sqlalchemy import text

session = SessionLocal()
skills = session.query(Skill).all()

with open('refined_skills.md', 'w', encoding='utf-8') as f:
    f.write("# Refined Skills\n\n")
    for s in skills:
        f.write(f'### Skill {s.skill_id}\n')
        f.write(f'- **Name:** {s.name}\n')
        f.write(f'- **Unit:** {s.unit_name}\n')
        f.write(f'- **Lesson:** {s.lesson_name}\n\n')

result = session.execute(text("SELECT document, cmetadata FROM langchain_pg_embedding")).fetchall()
with open('chunks.md', 'w', encoding='utf-8') as f:
    f.write("# Extracted Chunks\n\n")
    for i, row in enumerate(result):
        doc = row[0]
        meta = row[1]
        f.write(f'### Chunk {i+1} ({meta.get("role", "unknown")})\n')
        f.write(f'- **Unit:** {meta.get("unit", "")}\n')
        f.write(f'- **Lesson:** {meta.get("lesson", "")}\n')
        f.write(f'- **Doc ID:** {meta.get("document_id", "")}\n\n')
        f.write(f'{doc}\n\n')

print(f'Done! Saved {len(result)} chunks to chunks.md and {len(skills)} skills to refined_skills.md.')
