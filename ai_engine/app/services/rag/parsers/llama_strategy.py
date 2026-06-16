import os
from uuid import UUID
from llama_parse import LlamaParse
from app.core.config import settings
from app.services.rag.parsers.base import DocumentParserStrategy


# ---------------------------------------------------------------------------
# System Prompts
# ---------------------------------------------------------------------------
# Both prompts carry an explicit NO-TRANSLATE rule so the parser transcribes the
# original language faithfully regardless of the OCR language hint. That guarantee
# is what lets the ingestion pipeline trust content-based language detection and
# safely re-parse when its first-pass guess was wrong.

_NO_TRANSLATE_RULE = (
    "CRITICAL: Preserve the original language of every piece of text EXACTLY as it "
    "appears. Do NOT translate any text — English stays English, Arabic stays Arabic. "
)

_ARABIC_SYSTEM_PROMPT = (
    "This is a bilingual educational textbook. "
    "IMPORTANT: The primary language is Arabic (RTL). "
    + _NO_TRANSLATE_RULE +
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


def _build_parse_kwargs(language: str) -> dict:
    """LlamaParse kwargs for an OCR language. "ar" forces Arabic OCR; "en" auto-detects."""
    kwargs = {
        "result_type": "markdown",
        "premium_mode": True,
        "verbose": True,
    }
    if language == "en":
        # English-medium: auto-detect language (do NOT set language="ar"), so LlamaParse
        # never transliterates English into Arabic.
        kwargs["system_prompt"] = _ENGLISH_SYSTEM_PROMPT
    else:
        # Arabic-medium (default): force Arabic OCR for best quality.
        kwargs["language"] = "ar"
        kwargs["system_prompt"] = _ARABIC_SYSTEM_PROMPT
    return kwargs


class LlamaParseStrategy(DocumentParserStrategy):
    """
    Single-pass document parsing via the LlamaParse API.

    The strategy is a primitive: given an OCR ``language`` it returns markdown for one
    pass. Choosing the initial language, verifying it against the parsed content, and
    deciding whether to re-parse are orchestration concerns owned by the ingestion
    pipeline — not this parser.

    - language="ar": force Arabic OCR (best for Arabic-medium Math/Science/etc.)
    - language="en": auto-detect (avoids translating English-medium books to Arabic)
    """
    def parse(self, document_id: UUID, temp_file_path: str, language: str = "ar") -> str:
        if settings.LLAMA_CLOUD_API_KEY:
            os.environ["LLAMA_CLOUD_API_KEY"] = settings.LLAMA_CLOUD_API_KEY

        parser = LlamaParse(**_build_parse_kwargs(language))

        print(f"[{document_id}] Starting LlamaParse extraction (language={language})...", flush=True)
        try:
            documents = parser.load_data(temp_file_path)
        except Exception as e:
            print(f"CRITICAL: LlamaParse failed (language={language}): {str(e)}", flush=True)
            return ""  # Return empty so the pipeline handles it gracefully

        print(f"[{document_id}] Extraction complete (language={language})! Found {len(documents)} pages.", flush=True)
        return "\n\n".join([doc.text for doc in documents])