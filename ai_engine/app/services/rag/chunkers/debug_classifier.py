from app.services.rag.chunkers.classifier import ChunkClassifier

test_chunks = [
    # 1. Problematic Overview Chunk
    """# عمليتا الضرب والقسمة مع الكسور العشرية
## المفاهيم
### المفهوم الأول: ضرب الكسور العشرية.
- **الدرس (1):** الضرب في قوى العدد 10
- يشرح التلميذ الأنماط المستخدمة عند الضرب في قوى العدد 10.
- يضرب التلميذ كسرًا عشريًا في عدد صحيحة.""",
    
    # 2. TOC Chunk
    "الدرس (1): الضرب في قوى العدد 10 ................... 136",
    
    # 3. Real Problem Chunk
    """### تعلّم
أوجد ناتج: $3.2 \times 10$
عند الضرب في 10 يتحرك كل رقم في العدد خانة واحدة جهة اليسار.
$3.2 \times 10 = 32$""",

    # 4. Empty Table Chunk
    """| الوحدات |        | الكسور العشرية |        |      |   |
| ------- | ------ | -------------- | ------ | ---- | - |
| مئات    | عشارات | أحاد           | جزء من | مائة |   |"""
]

print(f"{'TYPE':<12} | {'SUB':<4} | {'STR':<4} | {'TEXT SNIPPET'}")
print("-" * 60)

for chunk in test_chunks:
    res = ChunkClassifier.classify(chunk)
    snippet = chunk.replace('\n', ' ')[:40]
    print(f"{res['content_type']:<12} | {res['substantive_score']:<4} | {res['structural_score']:<4} | {snippet}...")
