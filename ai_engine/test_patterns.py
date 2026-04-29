"""Quick validation of regex patterns against real textbook samples."""
import sys, os
sys.path.append(os.getcwd())
sys.stdout.reconfigure(encoding='utf-8')

from app.services.rag.processors.metadata_extractor import (
    UNIT_PATTERNS, LESSON_PATTERNS, CONCEPT_PATTERNS,
    _extract_full_title, detect_chunk_role, is_garbage_chunk
)
from app.services.rag.processors.objective_extractor import (
    extract_ministry_objectives, extract_arabic_objectives
)


def test_pattern(name, patterns, samples):
    """Test that all samples match at least one pattern."""
    print(f"\n{'='*60}")
    print(f"  Testing: {name}")
    print(f"{'='*60}")
    passed = 0
    for sample in samples:
        matched = any(p.search(sample) for p in patterns)
        status = "✅" if matched else "❌"
        print(f"  {status} '{sample[:60]}...' " if len(sample) > 60 else f"  {status} '{sample}'")
        if matched:
            passed += 1
    print(f"  Result: {passed}/{len(samples)} matched")
    return passed == len(samples)


# ==========================================================================
# Test UNIT_PATTERNS
# ==========================================================================
unit_samples = [
    # Sela7 format (numeric)
    "## الوحدة (1): القيمة المكانية للأعداد العشرية وحسابها",
    "# الوحدة 1",
    "## الوحدة 5",
    "الوحدة (3): ضرب الأعداد الصحيحة",
    # Ministry format (ordinal)
    "# الوحدة الأولى",
    "## الوحدة الثانية: العلاقات بين الأعداد",
    "الوحدة الرابعة",
    "الوحدة الخامسة: عمليتا الضرب والقسمة",
    "الوحدة السادسة",
    # English
    "Unit 3: Multiplication",
    "Chapter 5",
]
test_pattern("UNIT_PATTERNS", UNIT_PATTERNS, unit_samples)


# ==========================================================================
# Test LESSON_PATTERNS
# ==========================================================================
lesson_samples = [
    # Sela7 format (numeric)
    "الدرس (1): الكسور العشرية حتى جزء من الألف",
    "الدرسان (2 ، 3): تغيير القيم المكانية",
    "الدرس (8 - 10): نمذجة طرح الكسور العشرية",
    "الدروس (4 - 6): ضرب الكسور العشرية",
    # Ministry format (ordinal)
    "# الدرس الأول",
    "## الدرس الثاني",
    "الدرس السابع",
    "الدرس الحادي عشر",
    "الدرس الثالث",
    # English
    "Lesson 3",
]
test_pattern("LESSON_PATTERNS", LESSON_PATTERNS, lesson_samples)


# ==========================================================================
# Test _extract_full_title
# ==========================================================================
print(f"\n{'='*60}")
print(f"  Testing: _extract_full_title")
print(f"{'='*60}")

title_tests = [
    ("الوحدة (1): القيمة المكانية", UNIT_PATTERNS, "الوحدة (1): القيمة المكانية"),
    ("# الوحدة الأولى", UNIT_PATTERNS, "الوحدة الأولى"),
    ("الوحدة الثانية: العلاقات بين الأعداد", UNIT_PATTERNS, "الوحدة الثانية: العلاقات بين الأعداد"),
    ("الدرس (1): الكسور العشرية", LESSON_PATTERNS, "الدرس (1): الكسور العشرية"),
    ("# الدرس الأول", LESSON_PATTERNS, "الدرس الأول"),
]

for input_text, patterns, expected in title_tests:
    result = _extract_full_title(input_text, patterns)
    status = "✅" if result == expected else "❌"
    print(f"  {status} '{input_text[:50]}' → '{result}' (expected: '{expected}')")


# ==========================================================================
# Test detect_chunk_role
# ==========================================================================
print(f"\n{'='*60}")
print(f"  Testing: detect_chunk_role")
print(f"{'='*60}")

role_tests = [
    ("الوحدة الأولى\nالكسور العشرية", "unit_header"),
    ("# الدرس الأول\n## الكسور العشرية", "lesson_header"),
    ("المفهوم الأول | الوحدة الرابعة", "concept_header"),
    ("تحقق من فهمك\n1. أوجد ناتج", "exercise"),
    ("تعلّم\nعند الضرب في 10", "explanation"),
    ("فهرس الكتاب\nالوحدة (1) ...... 5", "toc"),
]

for text, expected_role in role_tests:
    role = detect_chunk_role(text)
    status = "✅" if role == expected_role else "❌"
    print(f"  {status} '{text[:50]}' → '{role}' (expected: '{expected_role}')")


# ==========================================================================
# Test is_garbage_chunk
# ==========================================================================
print(f"\n{'='*60}")
print(f"  Testing: is_garbage_chunk")
print(f"{'='*60}")

garbage_tests = [
    ("# viii\nالممسوحة ضوئياً بـ CamScanner", 6, True),
    ("viii", 1, True),
    ("### التمرين 611", 3, False),  # Could be exercise ref, not garbage
    ("أوجد ناتج الضرب: $3.2 \\times 10$", 6, False),
    ("يُقرّب التلميذ الأعداد العشرية إلى أقرب جزء من عشرة", 8, False),
]

for text, wc, expected in garbage_tests:
    result = is_garbage_chunk(text, wc)
    status = "✅" if result == expected else "❌"
    print(f"  {status} '{text[:40]}' (wc={wc}) → garbage={result} (expected: {expected})")


# ==========================================================================
# Test Ministry Objective Extraction
# ==========================================================================
print(f"\n{'='*60}")
print(f"  Testing: extract_ministry_objectives")
print(f"{'='*60}")

ministry_sample = """
# الوحدة الأولى: القيمة المكانية

# الدرس الأول
## الكسور العشرية حتى جزء من الألف

### أهداف التعلم
- أستطيع أن أقرأ الأعداد العشرية حتى جزء من الألف.
- أستطيع أن أكتب الأعداد العشرية حتى جزء من الألف.

### استكشف
Content here...

## هدف التعلم
- أستطيع أن أقرب الأعداد العشرية إلى أقرب جزء من عشرة.

# الوحدة الثانية: العلاقات بين الأعداد

# الدرس الثالث
## تحليل العدد إلى عوامل

### أهداف التعلم:
- أستطيع أن أستخدم أشجار العوامل لتحديد العوامل المشتركة لعددين صحيحين.
- أستطيع أن أستخدم أشجار العوامل لتحديد العامل المشترك الأكبر لعددين صحيحين.
"""

results = extract_ministry_objectives(ministry_sample)
print(f"  Found {len(results)} groups:")
for r in results:
    print(f"    Unit: {r['unit']}")
    print(f"    Lesson: {r['lesson']}")
    for obj in r['objectives']:
        print(f"      - {obj}")
    print()


# ==========================================================================
# Test Arabic (Sela7) Objective Extraction
# ==========================================================================
print(f"\n{'='*60}")
print(f"  Testing: extract_arabic_objectives")
print(f"{'='*60}")

sela7_sample = """
## الوحدة (1): القيمة المكانية

### المفاهيم

#### المفهوم الأول: القيمة المكانية

- **الدرس (1): الكسور العشرية حتى جزء من الألف**
  - يكتب التلميذ الأعداد العشرية حتى جزء من الألف
  - يقرأ التلميذ الأعداد العشرية حتى جزء من الألف

- **الدرسان (2 ، 3): تغيير القيم المكانية**
  - يشرح التلميذ كيف تتغير قيمة الرقم
  - يُكوّن التلميذ الأعداد العشرية

## Another section
"""

results = extract_arabic_objectives(sela7_sample)
print(f"  Found {len(results)} groups:")
for r in results:
    print(f"    Unit: {r['unit']}")
    print(f"    Lesson: {r['lesson']}")
    for obj in r['objectives']:
        print(f"      - {obj}")
    print()


# ==========================================================================
# Test on REAL Ministry Book
# ==========================================================================
print(f"\n{'='*60}")
print(f"  Testing: REAL Ministry Book (debug_43bf78c4)")
print(f"{'='*60}")

debug_path = "debug_43bf78c4-44c1-4b48-be03-63075925b597.md"
if os.path.exists(debug_path):
    with open(debug_path, 'r', encoding='utf-8') as f:
        real_text = f.read()
    
    results = extract_ministry_objectives(real_text)
    total_obj = sum(len(r['objectives']) for r in results)
    print(f"  Found {total_obj} objectives across {len(results)} groups:")
    for r in results[:5]:  # Show first 5
        print(f"    [{r['unit']}] {r['lesson']}:")
        for obj in r['objectives'][:2]:  # Show first 2 per group
            print(f"      - {obj}")
    if len(results) > 5:
        print(f"    ... and {len(results) - 5} more groups")
else:
    print(f"  ⚠ File not found: {debug_path}")


# ==========================================================================
# Test on REAL Sela7 Book
# ==========================================================================
print(f"\n{'='*60}")
print(f"  Testing: REAL Sela7 Book (debug_99dea7b4)")
print(f"{'='*60}")

debug_path = "debug_99dea7b4-d98d-4641-b753-76092a399096.md"
if os.path.exists(debug_path):
    with open(debug_path, 'r', encoding='utf-8') as f:
        real_text = f.read()
    
    results = extract_arabic_objectives(real_text)
    total_obj = sum(len(r['objectives']) for r in results)
    print(f"  Found {total_obj} objectives across {len(results)} groups:")
    for r in results[:5]:  # Show first 5
        print(f"    [{r['unit']}] {r['lesson']}:")
        for obj in r['objectives'][:2]:
            print(f"      - {obj}")
    if len(results) > 5:
        print(f"    ... and {len(results) - 5} more groups")
else:
    print(f"  ⚠ File not found: {debug_path}")


# ==========================================================================
# Test: Generic Arabic Headers (Science / Arabic Language style)
# ==========================================================================
print(f"\n{'='*60}")
print(f"  Testing: Generic Arabic Objective Headers")
print(f"{'='*60}")

from app.services.rag.processors.objective_extractor import _AR_OBJECTIVES_HEADER, _AR_INLINE_OBJECTIVES_INTRO, _AR_GENERIC_OBJECTIVE

ar_header_samples = [
    "### أهداف التعلم",
    "## هدف التعلم",
    "### نواتج التعلم",
    "## الأهداف السلوكية",
    "### الأهداف التعليمية",
    "## الأهداف الإجرائية",
    "### مخرجات التعلم",
    "ماذا سنتعلم؟",
    "ماذا سوف نتعلم",
    "## أهداف الدرس",
    "## هدف الوحدة",
    "الأهداف",
]

passed = 0
for s in ar_header_samples:
    matched = bool(_AR_OBJECTIVES_HEADER.match(s.strip()))
    status = "✅" if matched else "❌"
    print(f"  {status} '{s}'")
    if matched: passed += 1
print(f"  Result: {passed}/{len(ar_header_samples)} matched")

# Test inline intros
print(f"\n  Inline objective intros:")
inline_samples = [
    "في هذا الدرس سوف نتعرف على:",
    "في هذه الوحدة نتعلم عن:",
    "بنهاية هذا الدرس يستطيع التلميذ:",
    "في نهاية هذا الدرس:",
    "بعد دراسة هذا الدرس:",
    "يتوقع أن التلميذ:",
]

passed = 0
for s in inline_samples:
    matched = bool(_AR_INLINE_OBJECTIVES_INTRO.search(s))
    status = "✅" if matched else "❌"
    print(f"  {status} '{s}'")
    if matched: passed += 1
print(f"  Result: {passed}/{len(inline_samples)} matched")

# Test generic Arabic bullets
print(f"\n  Generic Arabic objective bullets:")
ar_bullet_samples = [
    "- أستطيع أن أقرأ الأعداد العشرية",
    "- أن يشرح التلميذ الفرق بين العوامل والمضاعفات",
    "- أن يصف الطالب مكونات الخلية",
    "- يتعرف التلميذ على أجزاء النبات",
    "- يكتب التلميذ تعبيراً عن حياته اليومية",
    "- التعرف على الخلية النباتية",
    "- فهم العلاقة بين الكائنات الحية وبيئتها",
    "- مقارنة بين الخلية الحيوانية والنباتية",
    "• استخدام المجهر لفحص العينات",
]

passed = 0
for s in ar_bullet_samples:
    matched = bool(_AR_GENERIC_OBJECTIVE.match(s))
    status = "✅" if matched else "❌"
    print(f"  {status} '{s}'")
    if matched: passed += 1
print(f"  Result: {passed}/{len(ar_bullet_samples)} matched")


# ==========================================================================
# Test: English Expanded Patterns
# ==========================================================================
print(f"\n{'='*60}")
print(f"  Testing: Expanded English Objective Headers")
print(f"{'='*60}")

from app.services.rag.processors.objective_extractor import _EN_OBJECTIVES_HEADER, _EN_OBJECTIVE

en_header_samples = [
    "Learning Outcomes",
    "Learning Objectives",
    "### Objectives",
    "## Lesson Objectives",
    "Key Learning Points",
    "What You Will Learn",
    "By the end of this lesson",
    "In this lesson you will",
    "Students will be able to",
]

passed = 0
for s in en_header_samples:
    matched = bool(_EN_OBJECTIVES_HEADER.match(s.strip()))
    status = "✅" if matched else "❌"
    print(f"  {status} '{s}'")
    if matched: passed += 1
print(f"  Result: {passed}/{len(en_header_samples)} matched")

# Test English bullets
print(f"\n  English objective bullets:")
en_bullet_samples = [
    "- Read and answer questions about a story",
    "- Students will identify the main character",
    "- Be able to describe the water cycle",
    "- Identify the difference between nouns and verbs",
    "- Compare and contrast two habitats",
    "• Write a short paragraph about your family",
]

passed = 0
for s in en_bullet_samples:
    matched = bool(_EN_OBJECTIVE.match(s))
    status = "✅" if matched else "❌"
    print(f"  {status} '{s}'")
    if matched: passed += 1
print(f"  Result: {passed}/{len(en_bullet_samples)} matched")


# ==========================================================================
# Integration test: Full Science textbook simulation
# ==========================================================================
print(f"\n{'='*60}")
print(f"  Testing: Science Textbook Simulation")
print(f"{'='*60}")

science_sample = """
# الوحدة الأولى: الكائنات الحية

# الدرس الأول
## أجزاء النبات

### نواتج التعلم
- أن يتعرف التلميذ على أجزاء النبات الرئيسية
- أن يصف التلميذ وظيفة كل جزء
- التعرف على عملية البناء الضوئي

### استكشف
Content here...

# الدرس الثاني
## الخلية

في هذا الدرس سوف نتعرف على:
- أن يشرح الطالب مكونات الخلية
- مقارنة بين الخلية الحيوانية والنباتية
- استخدام المجهر لفحص العينات
"""

results = extract_ministry_objectives(science_sample)
total_obj = sum(len(r['objectives']) for r in results)
print(f"  Found {total_obj} objectives across {len(results)} groups:")
for r in results:
    print(f"    [{r['unit']}] {r['lesson']}:")
    for obj in r['objectives']:
        print(f"      - {obj}")
    print()


print(f"\n{'='*60}")
print(f"  ALL TESTS COMPLETE")
print(f"{'='*60}")

