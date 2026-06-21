"""
One-off verification for the skill-consolidation prompt changes (Changes B & C).

Re-runs extract_skills_with_llm() on a CACHED parsed textbook markdown (no PDF
re-parse) and diffs the freshly-generated skill map against the stored baseline
debug_output/<doc>_refined_skills.json.

Usage:
    .venv/Scripts/python.exe scripts/check_skill_changes.py <doc_id_prefix>

Example (the Arabic language book with a 10-skill multi-strand lesson):
    .venv/Scripts/python.exe scripts/check_skill_changes.py 4fbadffc-2ce

What to look for:
    - GENUINE over-split lessons (e.g. a 15-skill linear-algebra lesson) should
      drop toward a smaller count.
    - MULTI-STRAND lessons (e.g. an Arabic lesson mixing reading + grammar +
      spelling + handwriting) should KEEP their distinct skills, NOT collapse.
    - Overall: distribution should not collapse toward 1; lesson coverage (number
      of lessons getting >= 1 skill) should be unchanged.
"""
import glob
import json
import sys
from statistics import mean, median

from app.services.rag.processors.mastery_refiner import extract_skills_with_llm


def _counts(mastery):
    return [len(e.get("objectives", [])) for e in mastery]


def _dist(counts):
    if not counts:
        return "  (no lessons)"
    return (f"  lessons={len(counts)}  skills={sum(counts)}  "
            f"mean={mean(counts):.2f}  median={median(counts)}  max={max(counts)}")


def _find(prefix):
    md = glob.glob(f"debug_output/{prefix}*_parsed.md")
    base = glob.glob(f"debug_output/{prefix}*_refined_skills.json")
    if not md:
        sys.exit(f"No parsed markdown found for prefix '{prefix}' in debug_output/")
    return md[0], (base[0] if base else None)


def main():
    if len(sys.argv) < 2:
        sys.exit("Usage: python scripts/check_skill_changes.py <doc_id_prefix>")
    prefix = sys.argv[1]
    md_path, base_path = _find(prefix)
    print(f"Parsed markdown : {md_path}")
    print(f"Baseline skills : {base_path or '(none)'}")

    markdown = open(md_path, encoding="utf-8").read()

    baseline = []
    if base_path:
        try:
            baseline = json.load(open(base_path, encoding="utf-8"))
            if not isinstance(baseline, list):
                baseline = []
        except Exception:
            baseline = []

    print("\nCalling Gemini with the NEW prompt (one extraction call)...\n")
    new_mastery, detected_subject = extract_skills_with_llm(markdown)
    if not new_mastery:
        sys.exit("extract_skills_with_llm returned nothing (no key / LLM failure). "
                 "Cannot compare.")

    print("=" * 72)
    print(f"DETECTED SUBJECT: {detected_subject!r}")
    print("=" * 72)
    print("BASELINE (stored)  :" + _dist(_counts(baseline)))
    print("NEW (this run)     :" + _dist(_counts(new_mastery)))

    # Lesson coverage: how many lessons got >= 1 skill (should not drop).
    base_lessons = {(e.get("unit", ""), e.get("lesson", "")) for e in baseline}
    new_lessons = {(e.get("unit", ""), e.get("lesson", "")) for e in new_mastery}
    print(f"\nLesson coverage    : baseline={len(base_lessons)}  new={len(new_lessons)}")
    dropped = base_lessons - new_lessons
    if dropped:
        print(f"  WARNING: {len(dropped)} baseline lessons missing in new output:")
        for u, l in list(dropped)[:10]:
            print(f"    - {l}")

    # Per-lesson before/after, sorted by baseline count desc — eyeball the tail.
    base_by_lesson = {e.get("lesson", ""): len(e.get("objectives", [])) for e in baseline}
    new_by_lesson = {e.get("lesson", ""): e.get("objectives", []) for e in new_mastery}

    print("\nPER-LESSON SKILL COUNTS (baseline -> new), highest baseline first:")
    for lesson, b_count in sorted(base_by_lesson.items(), key=lambda x: -x[1]):
        n_objs = new_by_lesson.get(lesson)
        n_count = len(n_objs) if n_objs is not None else "—(lesson not matched)"
        print(f"  {b_count:>3} -> {str(n_count):>3}   {lesson}")

    # Dump the new skills for the highest-count lessons so you can read them.
    print("\nNEW SKILLS for the 2 lessons with the most NEW skills:")
    top = sorted(new_mastery, key=lambda e: -len(e.get("objectives", [])))[:2]
    for e in top:
        print(f"\n  LESSON: {e.get('lesson','')}  ({len(e.get('objectives',[]))} skills)")
        for o in e.get("objectives", []):
            print(f"     - {o}")


if __name__ == "__main__":
    main()