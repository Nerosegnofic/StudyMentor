"""
LLM-Powered Mastery Point Refiner.

Takes the raw regex-extracted mastery points + textbook TOC and passes them
through Gemini 2.5 Flash to produce optimally-granular "skill nodes" for
the BKT adaptive learning system.

Architecture:
    - Single Gemini call per document (all points + TOC in one shot)
    - Structured JSON output via Pydantic + with_structured_output()
    - Fallback to raw regex points if LLM call fails
    - Built-in rate limiter to stay within free-tier limits

Design Goals:
    - Each skill should support generating 5-10 diverse questions
    - Not too specific (single-answer fact) nor too broad (multi-lesson concept)
    - Full textbook coverage: every TOC lesson gets at least one skill
"""
import re
import time
import threading
from typing import List, Dict, Optional

from langchain_google_genai import ChatGoogleGenerativeAI
from app.core.config import settings
from app.models.schemas import RefinedMasteryResponse


# ===========================================================================
# Rate Limiter
# ===========================================================================

class RateLimiter:
    """
    Simple token-bucket rate limiter for Gemini API calls.
    Gemini 2.5 Flash free tier: 10 RPM, 250K TPM.
    We use conservative defaults: max 5 calls/min with 15s min interval.
    """
    def __init__(self, max_calls_per_minute: int = 5, min_interval_seconds: float = 15.0):
        self.max_calls_per_minute = max_calls_per_minute
        self.min_interval_seconds = min_interval_seconds
        self._call_times: List[float] = []
        self._lock = threading.Lock()

    def wait_if_needed(self):
        """Block until it's safe to make the next API call."""
        with self._lock:
            now = time.time()
            # Purge calls older than 60 seconds
            self._call_times = [t for t in self._call_times if now - t < 60]

            # Check RPM limit
            if len(self._call_times) >= self.max_calls_per_minute:
                oldest = self._call_times[0]
                wait_time = 60 - (now - oldest)
                if wait_time > 0:
                    print(f"[RateLimiter] RPM limit reached. Waiting {wait_time:.1f}s...", flush=True)
                    time.sleep(wait_time)
                    now = time.time()
                    self._call_times = [t for t in self._call_times if now - t < 60]

            # Enforce minimum interval between calls
            if self._call_times:
                elapsed = now - self._call_times[-1]
                if elapsed < self.min_interval_seconds:
                    sleep_time = self.min_interval_seconds - elapsed
                    print(f"[RateLimiter] Min interval not met. Waiting {sleep_time:.1f}s...", flush=True)
                    time.sleep(sleep_time)

            self._call_times.append(time.time())


# Global rate limiter instance
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
- Raw mastery points were extracted by regex and may be too specific, too broad, duplicated, or missing entirely for some lessons.
- You are given the textbook's Table of Contents (TOC) to ensure full coverage.
- These skills will be used to: (a) track student mastery via BKT, (b) generate quiz questions.

RULES:
1. MERGE points that test the same cognitive skill within a lesson.
   Example: "أستطيع أن أقرأ الأعداد العشرية حتى جزء من الألف" + "أستطيع أن أكتب الأعداد العشرية حتى جزء من الألف"
   → Merge into: "قراءة وكتابة الأعداد العشرية حتى جزء من الألف"

2. SPLIT points that are too broad and span multiple distinct testable skills.

3. FILL GAPS: If a lesson appears in the TOC but has NO mastery points, create 1-2 appropriate skills for it based on the lesson title.

4. SWEET SPOT: Each skill must be:
   - Specific enough to generate 5-10 diverse quiz questions
   - Broad enough to NOT be a single-answer trivia fact
   - Focused on ONE testable cognitive ability

5. NORMALIZE unit names: Consolidate duplicates (e.g., "الوحدة الثانية" and "الوحدة الثانية: العلاقات بين الأعداد" should be merged into one canonical name).

6. LANGUAGE: Keep the EXACT language of the textbook. If the textbook is in English, write skills in English. If Arabic, write skills in Arabic. Do NOT translate.

7. REMOVE filler/generic points like "أستطيع أن أتحقق من معقولية إجاباتي" UNLESS they are the only point for a lesson.

8. SKILL TEXT FORMAT: Write skills as concise noun phrases describing the ability, NOT as "أستطيع أن..." sentences.
   Example (Math): Instead of "أستطيع أن أقرب الأعداد العشرية" → Use "تقريب الأعداد العشرية إلى أقرب جزء من عشرة أو مائة أو ألف"
   Example (English): Instead of "Read and identify sight words" + "Spell sight words" → Use "Reading and spelling sight words"
   Example (Arabic): Instead of "أن يميز التلميذ بين التاء المربوطة والمفتوحة" + "أن يكتب التاء المربوطة" → Use "التمييز بين التاء المربوطة والمفتوحة وكتابتهما"
   Example (Science): Instead of "أن يتعرف التلميذ على أجزاء النبات" + "أن يصف وظيفة كل جزء" → Use "التعرف على أجزاء النبات ووظائفها"
   Example (Social Studies): Instead of "أن يحدد الطالب عاصمة مصر" + "أن يذكر موقع مصر الجغرافي" → Use "تحديد عاصمة مصر وموقعها الجغرافي"

9. SKILL IDs: Generate a unique skill_id for each skill using the format: u{unit_number}_l{lesson_number}_s{skill_index}
   Example: u1_l1_s1, u1_l1_s2, u1_l2_s1, etc.

10. OUTPUT: Return structured JSON matching the provided schema exactly. Cover EVERY lesson in the TOC."""


def _build_user_prompt(raw_mastery: List[dict], toc_text: str) -> str:
    """Build the user prompt containing raw points and TOC. Language-neutral labels."""
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
    
    prompt = f"""Here is the textbook's Table of Contents:
---
{toc_text}
---

Here are the raw regex-extracted mastery points:
---
{points_text}
---

Please refine these into optimal skill nodes following the rules in your instructions. Ensure EVERY lesson from the TOC is covered."""
    
    return prompt


# ===========================================================================
# Main Refiner Function
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
                f"[MasteryRefiner] ✓ Refinement complete: "
                f"{raw_total} raw → {refined_total} refined points, "
                f"{raw_lessons} → {refined_lessons} lesson groups.",
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
    print("[MasteryRefiner] ✗ All retries failed. Falling back to raw regex points.", flush=True)
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
