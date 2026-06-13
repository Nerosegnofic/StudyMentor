"""
LLM-Powered Skill Extraction & Mastery Point Refinement.

Two Gemini-backed entry points produce optimally-granular "skill nodes" for the
BKT adaptive learning system:

    - extract_skills_with_llm(): PRIMARY path. Reads the full cleaned textbook
      markdown and extracts the unit → lesson → skill map directly. Works for
      ANY subject/language because it does not depend on hardcoded regex formats.

    - refine_mastery_points(): FALLBACK path. Refines raw regex-extracted points
      (used only when the LLM primary path is unavailable / fails).

Architecture:
    - Single Gemini call per document, structured JSON output via Pydantic +
      with_structured_output()
    - Built-in rate limiter to stay within free-tier limits
    - extract_skills_with_llm() returns None on failure so the caller can fall
      back to regex; refine_mastery_points() falls back to the raw points

Design Goals:
    - Each skill should support generating 5-10 diverse questions
    - Not too specific (single-answer fact) nor too broad (multi-lesson concept)
    - Full textbook coverage: every TOC lesson gets at least one skill
"""
import re
import time
from typing import List, Dict, Optional

from langchain_google_genai import ChatGoogleGenerativeAI
from app.core.config import settings
from app.core.llm_rate_limiter import RateLimiter
from app.models.schemas import RefinedMasteryResponse


# Global rate limiter instance (shared across mastery-refiner LLM calls).
_rate_limiter = RateLimiter()


# ===========================================================================
# TOC Extraction
# ===========================================================================

def _extract_toc_section(markdown_text: str) -> str:
    """
    Extract the Table of Contents section from the parsed markdown.
    Supports both Arabic and English textbooks.
    
    Strategy:
        1. Look for explicit TOC headers (Arabic: المحتويات, English: Table of Contents, Scope and Sequence)
        2. Fall back to scanning all unit/lesson headers to build a pseudo-TOC
    """
    # Try Arabic TOC header
    toc_match = re.search(
        r'#+\s*المحتويات\s*\n(.*?)(?=\n#+\s*(?:الوحدة|الفصل|Unit|Chapter)|\n---|\Z)',
        markdown_text,
        re.DOTALL
    )
    if toc_match:
        return toc_match.group(0).strip()
    
    # Try English TOC headers
    en_toc_match = re.search(
        r'#+\s*(?:Table\s+of\s+Contents|Contents|Scope\s+and\s+Sequence)\s*\n(.*?)(?=\n#+\s*(?:Unit|Chapter|الوحدة|الفصل)|\n---|\Z)',
        markdown_text,
        re.DOTALL | re.IGNORECASE
    )
    if en_toc_match:
        return en_toc_match.group(0).strip()

    # Fallback: extract all unit and lesson headers to reconstruct a pseudo-TOC
    # Matches Arabic AND English unit/lesson headers
    lines = []
    for match in re.finditer(
        r'^#+\s*((?:الوحدة|الفصل|Unit|Chapter|Module)\s*.+|(?:الدرس|Lesson)\s*.+)$',
        markdown_text,
        re.MULTILINE | re.IGNORECASE
    ):
        lines.append(match.group(1).strip())
    
    if lines:
        return "Table of Contents (extracted from headers):\n" + "\n".join(f"- {line}" for line in lines)
    
    return ""


# ===========================================================================
# Prompt Construction
# ===========================================================================

_SYSTEM_PROMPT = """You are a curriculum design specialist for Egyptian primary education (grades 4-6).

TASK: Refine raw mastery points extracted from a textbook into optimal "skill nodes" for an adaptive learning system that uses Bayesian Knowledge Tracing (BKT).

CONTEXT:
- Raw mastery points were extracted by regex and may be too specific, too broad, or duplicated.
- They are ALREADY grouped under the units and lessons the textbook itself uses. For some
  books a "lesson" is a real lesson title (e.g. "الدرس الأول: الكسور"); for others (e.g.
  English) it is a skill strand such as Speaking / Listening / Reading / Writing. Either
  way, that grouping is correct and must be kept.
- These skills will be used to: (a) track student mastery via BKT, (b) generate quiz questions.

RULES:
1. PRESERVE THE GIVEN GROUPING. Keep every input (unit, lesson) group exactly as provided.
   - Copy each unit name and lesson name VERBATIM into the output. Do NOT rename, renumber,
     translate, split, or merge groups, and do NOT invent new lessons.
   - Only the SKILL TEXTS within a group may be refined; the group labels stay fixed.
   - Do NOT reorganize skills into different lessons than the one they arrived under.

2. MERGE points WITHIN THE SAME input lesson that test the same cognitive skill.
   Example: "أستطيع أن أقرأ الأعداد العشرية" + "أستطيع أن أكتب الأعداد العشرية"
   → Merge into: "قراءة وكتابة الأعداد العشرية"

3. SPLIT a point WITHIN ITS lesson if it spans multiple distinct testable skills.

4. SWEET SPOT: Each skill must be:
   - Specific enough to generate 5-10 diverse quiz questions
   - Broad enough to NOT be a single-answer trivia fact
   - Focused on ONE testable cognitive ability

5. LANGUAGE: Keep the EXACT language of the textbook. If the textbook is in English, write skills in English. If Arabic, write skills in Arabic. Do NOT translate.

6. REMOVE filler/generic points like "أستطيع أن أتحقق من معقولية إجاباتي" UNLESS they are the only point for a lesson.

7. SKILL TEXT FORMAT: Write skills as concise noun phrases describing the ability, NOT as "أستطيع أن..." sentences.
   Example (Math): Instead of "أستطيع أن أقرب الأعداد العشرية" → Use "تقريب الأعداد العشرية إلى أقرب جزء من عشرة أو مائة أو ألف"
   Example (English): Instead of "Read and identify sight words" + "Spell sight words" → Use "Reading and spelling sight words"
   Example (Arabic): Instead of "أن يميز التلميذ بين التاء المربوطة والمفتوحة" + "أن يكتب التاء المربوطة" → Use "التمييز بين التاء المربوطة والمفتوحة وكتابتهما"
   Example (Science): Instead of "أن يتعرف التلميذ على أجزاء النبات" + "أن يصف وظيفة كل جزء" → Use "التعرف على أجزاء النبات ووظائفها"
   Example (Social Studies): Instead of "أن يحدد الطالب عاصمة مصر" + "أن يذكر موقع مصر الجغرافي" → Use "تحديد عاصمة مصر وموقعها الجغرافي"

8. SKILL IDs: Generate a unique skill_id for each skill using the format: u{unit_number}_l{lesson_number}_s{skill_index}
   Example: u1_l1_s1, u1_l1_s2, u1_l2_s1, etc.

9. OUTPUT: Return structured JSON matching the provided schema exactly. Output EXACTLY the same units and lessons you were given — no more, no fewer."""


# Primary-path prompt: the LLM EXTRACTS the skill map directly from the full
# textbook markdown (no regex input). This is what makes skill generation work
# for ANY subject/language instead of only the formats the regex anticipates.
_EXTRACT_SYSTEM_PROMPT = """You are a curriculum design specialist for Egyptian primary education (grades 4-6).

TASK: Read the full textbook markdown provided and EXTRACT its complete learning-skill map for an adaptive learning system that uses Bayesian Knowledge Tracing (BKT). You are building the curriculum skeleton directly from the document text — you are NOT refining a pre-made list.

OUTPUT STRUCTURE: a hierarchy of units → lessons → skills, where each skill is one testable cognitive ability.

RULES:
1. GROUNDING — NO HALLUCINATION. Extract only units, lessons, and skills that are actually present in the document. Copy each unit_name and lesson_name VERBATIM from the document's own headers (e.g. "الوحدة الأولى: الاختيار والمسئولية", "الدرس الأول: الاستماع"). Do NOT invent, rename, translate, or renumber them.

2. SKILL SOURCE. For each lesson:
   - If the lesson states an explicit objectives/outcomes section (e.g. "الأهداف", "نواتج التعلم", "نتائج التعلم", "مخرجات التعلم", "Learning Outcomes", "Now I can..."), derive the skills from those objectives.
   - Otherwise, derive the skills from the lesson title and its content.
   - Every lesson must get AT LEAST ONE skill.

3. UNITS. If the document has no clear unit structure, group all lessons under a single sensible unit named after the document/subject.

4. COMPLETENESS. Enumerate EVERY unit and EVERY lesson found in the document, in order. Do not stop early, summarize, or skip lessons.

5. IGNORE FRONT MATTER. Skip cover pages, author/review credits ("تأليف", "مراجعة", "إشراف"), the introduction ("مقدمة"), the table of contents ("الفهرس", "المحتويات"), and copyright/publisher pages. These are not lessons.

6. SKILL GRANULARITY (sweet spot). Each skill must be:
   - Specific enough to generate 5-10 diverse quiz questions.
   - Broad enough to NOT be a single-answer trivia fact.
   - Focused on ONE testable cognitive ability.
   Merge near-duplicate objectives that test the same skill; split an objective that clearly spans multiple distinct skills.

7. LANGUAGE: Keep the EXACT language of the textbook. If the textbook is in English, write skills in English. If Arabic, write skills in Arabic. Do NOT translate.

8. SKILL TEXT FORMAT: Write skills as concise noun phrases describing the ability, NOT as "أستطيع أن..." / "I can..." sentences.
   Example (Arabic): instead of "يتعرف أهمية التكنولوجيا في حياتنا" → "التعرف على أهمية التكنولوجيا في الحياة".
   Example (Math): instead of "أستطيع أن أقرب الأعداد العشرية" → "تقريب الأعداد العشرية إلى أقرب جزء من عشرة أو مائة".
   Example (English): instead of "Read and identify sight words" → "Reading and identifying sight words".

9. SKILL IDs: Generate a unique skill_id for each skill using the format u{unit_number}_l{lesson_number}_s{skill_index} (e.g. u1_l1_s1, u1_l1_s2, u1_l2_s1).

10. OUTPUT: Return structured JSON matching the provided schema exactly."""


def _build_extract_user_prompt(markdown_text: str) -> str:
    """Build the user prompt for the primary LLM extraction path: the full
    cleaned textbook markdown, asked to be mapped into the unit→lesson→skill schema."""
    return f"""Here is the full cleaned textbook markdown. Extract its complete unit → lesson → skill map following the rules in your instructions. Ground every unit and lesson name in the document's own headers, cover every lesson in order, and return the result as structured JSON.

--- BEGIN TEXTBOOK ---
{markdown_text}
--- END TEXTBOOK ---"""


def _build_user_prompt(raw_mastery: List[dict], toc_text: str) -> str:
    """Build the user prompt containing the raw points. Language-neutral labels.

    `toc_text` is accepted for signature compatibility but intentionally NOT injected:
    feeding the TOC made the model remap skills onto the TOC's lessons, discarding the
    input grouping. We refine the points strictly within the grouping they arrive in.
    This keeps the step general — real lessons for math/science, strands for English —
    because it always preserves whatever grouping the extractor produced.
    """
    # Format raw mastery points with language-neutral labels
    points_text = ""
    for entry in raw_mastery:
        unit = entry.get('unit', 'Unknown')
        lesson = entry.get('lesson', 'Unknown')
        objectives = entry.get('objectives', [])
        points_text += f"\n[Unit: {unit}]\n"
        points_text += f"  Lesson: {lesson}\n"
        for obj in objectives:
            points_text += f"    - {obj}\n"

    prompt = f"""Here are the raw regex-extracted mastery points, already grouped by the
textbook's own units and lessons:
---
{points_text}
---

Refine the SKILL TEXTS within each group following the rules in your instructions. Keep
every (unit, lesson) group exactly as given — same names, same set of lessons — and return
the result as structured JSON."""

    return prompt


# ===========================================================================
# Primary Extractor (LLM-first, language/subject agnostic)
# ===========================================================================

def extract_skills_with_llm(
    markdown_text: str,
    max_retries: int = 3,
) -> Optional[List[dict]]:
    """
    PRIMARY skill extractor: read the full cleaned textbook markdown and extract
    the complete unit → lesson → skill hierarchy directly via Gemini.

    Unlike refine_mastery_points(), this does NOT depend on regex-extracted input,
    so it works for ANY subject/language — not just the formats the regex
    patterns anticipate.

    Args:
        markdown_text: The full cleaned markdown text of the document.
        max_retries: Number of retry attempts on failure.

    Returns:
        List of dicts in the standard mastery format:
        [{'unit': str, 'lesson': str, 'objectives': [str, ...], 'skill_ids': [str, ...]}]

        Returns None when the LLM is unavailable (no API key) or fails / produces
        nothing after all retries, so the caller can fall back to the regex extractor.
    """
    if not markdown_text or not markdown_text.strip():
        print("[SkillExtractor] Empty document text. Skipping.", flush=True)
        return None

    if not settings.GEMINI_API_KEY:
        print("[SkillExtractor] GEMINI_API_KEY not set. Falling back to regex extractor.", flush=True)
        return None

    user_prompt = _build_extract_user_prompt(markdown_text)
    print(f"[SkillExtractor] Extracting skills from {len(markdown_text)} chars of markdown...", flush=True)

    # NOTE: For a single primary-school semester textbook the full document fits
    # comfortably in Gemini Flash's context. For truly massive multi-book uploads,
    # a future option is to split on unit headers and extract per-unit, then concat.
    for attempt in range(1, max_retries + 1):
        try:
            _rate_limiter.wait_if_needed()

            model_to_use = settings.GEMINI_MODEL
            if attempt > 1 and getattr(settings, "GEMINI_FALLBACK_MODEL", None):
                model_to_use = settings.GEMINI_FALLBACK_MODEL
                print(f"[SkillExtractor] Attempt {attempt}/{max_retries}: using fallback model {model_to_use}...", flush=True)
            else:
                print(f"[SkillExtractor] Calling Gemini {model_to_use} (attempt {attempt}/{max_retries})...", flush=True)

            llm = ChatGoogleGenerativeAI(
                google_api_key=settings.GEMINI_API_KEY,
                model=model_to_use,
                temperature=0.1,  # Low temp to stay grounded in the document
            )
            structured_llm = llm.with_structured_output(RefinedMasteryResponse)

            response: RefinedMasteryResponse = structured_llm.invoke(
                [
                    {"role": "system", "content": _EXTRACT_SYSTEM_PROMPT},
                    {"role": "human", "content": user_prompt},
                ]
            )

            extracted = _convert_response_to_mastery_list(response)
            if not extracted:
                raise ValueError("LLM returned an empty skill set")

            total = sum(len(e.get('objectives', [])) for e in extracted)
            print(
                f"[SkillExtractor] [OK] Extracted {total} skills across "
                f"{len(extracted)} lesson groups.",
                flush=True
            )
            return extracted

        except Exception as e:
            print(f"[SkillExtractor] Attempt {attempt}/{max_retries} failed: {e}", flush=True)
            if attempt < max_retries:
                backoff = 2 ** attempt * 5  # 10s, 20s, 40s
                print(f"[SkillExtractor] Retrying in {backoff}s...", flush=True)
                time.sleep(backoff)

    print("[SkillExtractor] [FAILED] All attempts failed. Falling back to regex extractor.", flush=True)
    return None


# ===========================================================================
# Fallback Refiner Function (regex-extracted points → Gemini refinement)
# ===========================================================================

def refine_mastery_points(
    raw_mastery_data: List[dict],
    markdown_text: str,
    max_retries: int = 3,
) -> List[dict]:
    """
    Refine raw regex-extracted mastery points using Gemini LLM.
    
    Args:
        raw_mastery_data: List of dicts from extract_all_objectives(), each with
                         {'unit': str, 'lesson': str, 'objectives': [str, ...]}
        markdown_text: The full cleaned markdown text (for TOC extraction)
        max_retries: Number of retry attempts on failure
    
    Returns:
        List of dicts in the same schema as input:
        [{'unit': str, 'lesson': str, 'objectives': [str, ...], 'skill_ids': [str, ...]}]
        
        Falls back to raw_mastery_data if LLM call fails.
    """
    if not raw_mastery_data:
        print("[MasteryRefiner] No raw mastery points to refine. Skipping.", flush=True)
        return raw_mastery_data
    
    if not settings.GEMINI_API_KEY:
        print("[MasteryRefiner] GEMINI_API_KEY not set. Falling back to raw points.", flush=True)
        return raw_mastery_data
    
    # Extract TOC for context
    toc_text = _extract_toc_section(markdown_text)
    if not toc_text:
        print("[MasteryRefiner] Warning: Could not extract TOC. Proceeding without it.", flush=True)
        toc_text = "(Table of Contents not available)"
    
    # Build prompts
    user_prompt = _build_user_prompt(raw_mastery_data, toc_text)
    
    # Count raw stats for logging
    raw_total = sum(len(e.get('objectives', [])) for e in raw_mastery_data)
    raw_lessons = len(raw_mastery_data)
    print(f"[MasteryRefiner] Refining {raw_total} raw points across {raw_lessons} lesson groups...", flush=True)
    
    # Retry loop with rate limiting
    for attempt in range(1, max_retries + 1):
        try:
            _rate_limiter.wait_if_needed()
            
            model_to_use = settings.GEMINI_MODEL
            if attempt > 1 and getattr(settings, "GEMINI_FALLBACK_MODEL", None):
                model_to_use = settings.GEMINI_FALLBACK_MODEL
                print(f"[MasteryRefiner] Attempt {attempt}/{max_retries}: using fallback model {model_to_use}...", flush=True)
            else:
                print(f"[MasteryRefiner] Calling Gemini {model_to_use} (attempt {attempt}/{max_retries})...", flush=True)

            # Initialize Gemini dynamically for the attempt
            llm = ChatGoogleGenerativeAI(
                google_api_key=settings.GEMINI_API_KEY,
                model=model_to_use,
                temperature=0.1,  # Low temp for consistency
            )
            structured_llm = llm.with_structured_output(RefinedMasteryResponse)

            response: RefinedMasteryResponse = structured_llm.invoke(
                [
                    {"role": "system", "content": _SYSTEM_PROMPT},
                    {"role": "human", "content": user_prompt},
                ]
            )
            
            # Convert structured response back to the standard mastery format
            refined_data = _convert_response_to_mastery_list(response)
            
            refined_total = sum(len(e.get('objectives', [])) for e in refined_data)
            refined_lessons = len(refined_data)
            
            print(
                f"[MasteryRefiner] [OK] Refinement complete: "
                f"{raw_total} raw -> {refined_total} refined points, "
                f"{raw_lessons} -> {refined_lessons} lesson groups.",
                flush=True
            )
            
            return refined_data
            
        except Exception as e:
            print(f"[MasteryRefiner] Attempt {attempt}/{max_retries} failed: {e}", flush=True)
            if attempt < max_retries:
                backoff = 2 ** attempt * 5  # 10s, 20s, 40s
                print(f"[MasteryRefiner] Retrying in {backoff}s...", flush=True)
                time.sleep(backoff)
    
    # All retries exhausted — fallback to raw
    print("[MasteryRefiner] [FAILED] All retries failed. Falling back to raw regex points.", flush=True)
    return raw_mastery_data


def _convert_response_to_mastery_list(response: RefinedMasteryResponse) -> List[dict]:
    """
    Convert the structured Gemini response into the standard mastery format
    used by save_mastery_points().
    
    Output format:
        [{'unit': str, 'lesson': str, 'objectives': [str, ...], 'skill_ids': [str, ...]}]
    """
    result = []
    for unit in response.units:
        for lesson in unit.lessons:
            objectives = []
            skill_ids = []
            for skill in lesson.skills:
                objectives.append(skill.skill_text)
                skill_ids.append(skill.skill_id)
            
            if objectives:
                result.append({
                    'unit': unit.unit_name,
                    'lesson': lesson.lesson_name,
                    'objectives': objectives,
                    'skill_ids': skill_ids,
                })
    return result
