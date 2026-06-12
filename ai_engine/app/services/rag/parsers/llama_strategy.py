import os
import re
from uuid import UUID
from llama_parse import LlamaParse
from app.core.config import settings
from app.services.rag.parsers.base import DocumentParserStrategy


# ---------------------------------------------------------------------------
# Subject-to-Language Mapping
# ---------------------------------------------------------------------------
# Egyptian primary school subjects fall into two categories:
#   1. Arabic-medium: Math, Science, Social Studies, Arabic Language, etc.
#      These textbooks are written primarily in Arabic (with occasional
#      English technical terms). They REQUIRE language="ar" for proper OCR.
#
#   2. English-medium: English (Connect / المعاصر)
#      These textbooks are written primarily in English (with occasional
#      Arabic instructions/glossary). They need auto-detect (no language param)
#      to avoid LlamaParse translating the English into Arabic.
#
# The mapping is intentionally conservative: if we're unsure, default to
# Arabic mode because the majority of Egyptian primary textbooks are Arabic.

_ENGLISH_SUBJECT_PATTERNS = re.compile(
    r'(?:english|connect|انجليز|إنجليز)',
    re.IGNORECASE
)


def _is_english_subject(subject_name: str) -> bool:
    """Determine if a subject is English-medium based on its name."""
    if not subject_name:
        return False
    return bool(_ENGLISH_SUBJECT_PATTERNS.search(subject_name))


# ---------------------------------------------------------------------------
# System Prompts
# ---------------------------------------------------------------------------

_ARABIC_SYSTEM_PROMPT = (
    "This is a bilingual educational textbook. "
    "IMPORTANT: The primary language is Arabic (RTL). "
    "Please preserve the RTL reading order for Arabic sections. "
    "Keep technical English terms in-line. "
    "Output headers as # and sub-headers as ##."
)

_ENGLISH_SYSTEM_PROMPT = (
    "You are parsing an educational textbook for an Egyptian school. "
    "The textbook is written primarily in English, with some Arabic instructions or glossary entries.\n\n"
    "CRITICAL RULES:\n"
    "1. PRESERVE the original language of every piece of text EXACTLY as it appears. "
    "Do NOT translate any text. If a sentence is in English, output it in English. "
    "If a sentence is in Arabic, output it in Arabic.\n"
    "2. For Arabic text, preserve the RTL reading order.\n"
    "3. Keep technical terms, proper nouns, and vocabulary words exactly as written.\n"
    "4. Output headers as # and sub-headers as ##.\n"
    "5. Preserve bullet points, numbered lists, and table structures.\n"
    "6. If a bilingual glossary appears (e.g., 'storm (عاصفة)'), keep BOTH languages."
)


class LlamaParseStrategy(DocumentParserStrategy):
    """
    Implementation of Document Parsing using LlamaParse API.

    Adapts OCR settings based on the subject:
    - Arabic-medium subjects (Math, Science, etc.) → language="ar" for best Arabic OCR
    - English-medium subjects (English) → auto-detect to avoid translating English to Arabic
    """
    def parse(self, document_id: UUID, temp_file_path: str, subject_name: str = "") -> str:
        if settings.LLAMA_CLOUD_API_KEY:
            os.environ["LLAMA_CLOUD_API_KEY"] = settings.LLAMA_CLOUD_API_KEY

        is_english = _is_english_subject(subject_name)

        # Build LlamaParse kwargs based on subject language
        parse_kwargs = {
            "result_type": "markdown",
            "premium_mode": True,
            "verbose": True,
        }

        if is_english:
            # English subject: auto-detect language (do NOT set language="ar")
            parse_kwargs["system_prompt"] = _ENGLISH_SYSTEM_PROMPT
            print(f"[{document_id}] Parser mode: ENGLISH (subject='{subject_name}')", flush=True)
        else:
            # Arabic-medium subject (default): force Arabic OCR for best quality
            parse_kwargs["language"] = "ar"
            parse_kwargs["system_prompt"] = _ARABIC_SYSTEM_PROMPT
            print(f"[{document_id}] Parser mode: ARABIC (subject='{subject_name}')", flush=True)

        parser = LlamaParse(**parse_kwargs)

        print(f"[{document_id}] Starting LlamaParse extraction...", flush=True)
        try:
            documents = parser.load_data(temp_file_path)
        except Exception as e:
            print(f"CRITICAL: LlamaParse failed: {str(e)}", flush=True)
            return "" # Return empty so the pipeline handles it gracefully

        print(f"[{document_id}] Extraction complete! Found {len(documents)} pages.", flush=True)
        return "\n\n".join([doc.text for doc in documents])
