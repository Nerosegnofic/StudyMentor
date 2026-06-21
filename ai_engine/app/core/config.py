from pydantic_settings import BaseSettings, SettingsConfigDict
from typing import Optional
import os

BASE_DIR = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
ENV_FILE_PATH = os.path.join(BASE_DIR, ".env")

class Settings(BaseSettings):
    PROJECT_NAME: str = "AI Curriculum POC"
    VERSION: str = "0.1.0"

    # Environment variables from .env
    OPENAI_API_KEY: Optional[str] = None
    LLAMA_CLOUD_API_KEY: Optional[str] = None
    COHERE_API_KEY: Optional[str] = None
    GEMINI_API_KEY: Optional[str] = None
    POSTGRES_CONNECTION: Optional[str] = None
    FIREBASE_PROJECT_ID: str = "studymentor-2026"
    FIREBASE_SERVICE_ACCOUNT_JSON: Optional[str] = None

    # Admin key for publishing GLOBAL (shared) curriculum via /documents/upload-global.
    # Sent as the `X-Admin-Key` header. If unset, the admin upload endpoint is disabled
    # (returns 403) — global subjects can then only be created via the seed script.
    ADMIN_API_KEY: Optional[str] = "test-admin-key-12345"

    # --- AI Model Configuration ---
    # Gemini Models:
    # - "gemini-2.5-flash" (Recommended default: fast, cheap, highly capable)
    # - "gemini-2.5-pro" (Better for complex logic, deeper reasoning, and complex parsing)
    GEMINI_MODEL: str = "gemini-3.5-flash"
    GEMINI_FALLBACK_MODEL: Optional[str] = "gemini-2.5-flash"

    # Cohere Models:
    # - "command-r-08-2024" (Current default)
    # - "command-r-plus" (Recommended for advanced multi-step tools & reasoning)
    COHERE_MODEL: str = "command-r-08-2024"

    # Temperature for Cohere-based quiz generation.
    # Raised to 0.7 to match Gemini and produce varied questions (was hardcoded 0.2).
    COHERE_GENERATION_TEMPERATURE: float = 0.7

    # Cohere Embeddings:
    # - "embed-multilingual-v3.0" (Recommended: high-quality vector embeddings for Arabic)
    # - "embed-multilingual-light-v3.0" (Faster, smaller dimensions)
    COHERE_EMBEDDING_MODEL: str = "embed-multilingual-v3.0"

    # Skill de-duplication (post-extraction safety net): cosine-similarity threshold
    # above which two skills WITHIN THE SAME LESSON are treated as near-duplicates and
    # merged into one. 0.88 is conservative (high precision — merges only true
    # near-duplicates); lower it to merge more aggressively. Per-lesson only, so a skill
    # that legitimately recurs across lessons is never collapsed. The extraction prompt
    # (which merges same-operation/different-representation skills) is the primary defense;
    # this threshold is the deterministic backstop.
    SKILL_DEDUP_SIMILARITY_THRESHOLD: float = 0.88

    # Skill-count drift warning: log a [SkillDrift] warning when any single lesson
    # produces more than this many skills. Pure observability — never modifies skills
    # or blocks ingestion. 6 sits well above the observed mean (1.82) and 95th pctile
    # (<=4), so it fires only on genuine over-split outliers (the old 10-15 skill lessons).
    SKILL_COUNT_WARN_THRESHOLD: int = 6

    # --- Chunking (MarkdownRecursiveChunkerStrategy tunables) ---
    # Defaults equal the previously-hardcoded literals, so chunking output is
    # unchanged until a value is tuned here.
    CHUNK_SIZE: int = 2000           # generic-content recursive splitter target (chars)
    CHUNK_OVERLAP: int = 200         # overlap for both splitters (chars)
    CHUNK_MIN_SIZE: int = 350        # below this, a chunk is merged forward
    CHUNK_MERGE_MAX_SIZE: int = 3000 # a merge may not exceed this combined length
    EXERCISE_CHUNK_SIZE: int = 3000  # item-aware splitter headroom for exercise/example

    # --- Guardrail Configuration ---
    # File Upload
    MAX_UPLOAD_SIZE_MB: int = 50

    # RAG Retrieval Quality
    # Cosine distance threshold: chunks with score > this value are too irrelevant to inject.
    # Range: 0.0 (identical) → 2.0 (opposite). 0.45 retains reasonably on-topic chunks.
    RETRIEVAL_SCORE_THRESHOLD: float = 0.55

    # Subject-tunable override for the retrieval threshold. Language subjects (Arabic/English)
    # often have short rule/vocabulary chunks that score less similar, so they get a more
    # lenient threshold. Falls back to RETRIEVAL_SCORE_THRESHOLD when a subject isn't matched.
    RETRIEVAL_SCORE_THRESHOLD_BY_SUBJECT: dict = {"language": 0.70, "default": 0.55}

    # Vector store collection name (langchain-postgres). Subject scoping is done via the
    # subject_id metadata filter, so a single neutral collection serves all subjects.
    PGVECTOR_COLLECTION_NAME: str = "curriculum"

    # Quiz Bank Fallback (used when LLM generation fails)
    # Minimum fraction of required questions the bank must cover before using it.
    QUIZ_BANK_MIN_COVERAGE: float = 0.60
    # Minimum days since a question was answered before it can be reused from the bank.
    QUIZ_BANK_MIN_AGE_DAYS: int = 7

    # LLM Resilience
    LLM_MAX_RETRIES: int = 3

    # Rate Limiting (slowapi format: "N/period" — e.g., "6/minute")
    # Headroom for client-side pre-warming: each quiz cycle issues ~2 /generate calls
    # (the fire-and-forget warm after submit + the CACHED start of the next quiz), so the
    # limit is set above the ~1/quiz a non-warming client would use.
    QUIZ_GENERATE_RATE_LIMIT: str = "6/minute"

    # BKT Evaluation / Spam Detection
    # Minimum time in ms required for an answer to be considered genuine comprehension.
    # Also used as the "guessing" threshold in the parent error-breakdown analytics.
    MINIMUM_GENUINE_TIME_MS: int = 2000

    # --- Subject Selection (auto-quiz subject prioritization) ---
    # Relative weights for the per-subject priority score. Selection is argmax, so only
    # the RELATIVE ordering matters — a weight of 0.0 simply disables that factor (the
    # selector skips computing it). exam_urgency is 0.0 by default because the app does
    # not yet collect exam dates; re-enable it later by bumping this one number (e.g. 0.3).
    SUBJECT_SELECTION_WEIGHTS: dict = {"mastery_gap": 0.4, "neglect": 0.3, "exam_urgency": 0.0}
    # "Neglect" is measured as how many quiz sessions the student has taken since this
    # subject last appeared, normalized by this cap (>= this many ⇒ fully neglected).
    SUBJECT_NEGLECT_QUIZ_WINDOW: int = 10
    # Multiplier applied to the most-recently-quizzed subject's score for variety.
    # 1.0 disables the rotation penalty.
    SUBJECT_ROTATION_PENALTY: float = 0.6

    # --- Skill Selection (Ordered Frontier + SRS) ---
    # Mastery probability needed to move a skill from the frontier into the mastered/SRS zone.
    SKILL_UNLOCK_THRESHOLD: float = 0.85
    # Grade → number of unmastered skills active in the frontier at once.
    SKILL_FRONTIER_WINDOW_BY_GRADE: dict = {
        1: 2, 2: 2, 3: 3, 4: 3, 5: 4, 6: 4,
        7: 5, 8: 5, 9: 5, 10: 5, 11: 5, 12: 5,
    }
    SKILL_DEFAULT_FRONTIER_WINDOW: int = 3
    # Question-budget split across the three zones (must cover frontier/review/preview).
    SKILL_ZONE_BUDGET_SPLIT: dict = {"frontier": 0.60, "review": 0.30, "preview": 0.10}
    # When True, shift budget toward review for struggling students and toward frontier
    # for thriving ones, based on recent quiz accuracy.
    SKILL_ADAPTIVE_BUDGET: bool = True
    # Recent-accuracy thresholds that trigger the adaptive shift (and how many recent
    # sessions to average over).
    SKILL_ADAPTIVE_LOW_ACCURACY: float = 0.50
    SKILL_ADAPTIVE_HIGH_ACCURACY: float = 0.85
    SKILL_ADAPTIVE_RECENT_SESSIONS: int = 3

    # --- Adaptive Auto Quiz-Length ---
    # When the parent picks "Auto" quiz length, the backend sizes the quiz from how much
    # material is currently active (frontier skills + due reviews) instead of a fixed
    # count, then eases it down for struggling students / up for thriving ones (reusing
    # the SKILL_ADAPTIVE_*_ACCURACY thresholds above). The result clamps to [min, max].
    QUIZ_AUTO_MIN_QUESTIONS: int = 3
    QUIZ_AUTO_MAX_QUESTIONS: int = 10
    # Cap on how many due SRS reviews feed the auto length (keeps a long review backlog
    # from ballooning a single quiz).
    QUIZ_AUTO_REVIEW_CAP: int = 4
    # Length multipliers at the accuracy extremes (struggling shrinks, thriving grows).
    QUIZ_AUTO_STRUGGLING_FACTOR: float = 0.7
    QUIZ_AUTO_THRIVING_FACTOR: float = 1.2
    # Error-breakdown analytics (parent Reports → Mastery tab). Quizzes are not timed,
    # so there is no "time pressure" category — only careless / concept-gap / guessing.
    # A wrong answer faster than this (but slower than MINIMUM_GENUINE_TIME_MS) on
    # material the student should know is treated as a careless mistake.
    CARELESS_MAX_TIME_MS: int = 10000
    # Skill mastery at/above which a wrong answer looks careless rather than a gap.
    CARELESS_KNOWN_MASTERY: float = 0.6

    # A quiz session is flagged as "rapid guessing" in the parent Effort & Focus
    # card when its spam clicks reach this fraction of the quiz's question count
    # (e.g. 0.5 = half or more of the answers were rapid guesses).
    GUESSING_SESSION_SPAM_FRACTION: float = 0.5

    # Parent insight & alert thresholds (Reports → Overview).
    INSIGHT_LOW_ACCURACY_PERCENT: float = 55.0    # below this → low-accuracy alert
    INSIGHT_ACCURACY_DROP_PERCENT: float = 5.0    # week-over-week drop that triggers an alert
    INSIGHT_INACTIVITY_DAYS: int = 2              # days with no quiz before flagging inactivity
    WEAK_SUBJECT_MASTERY_PERCENT: float = 50.0    # subject mastery below this → needs attention

    model_config = SettingsConfigDict(env_file=ENV_FILE_PATH, extra="ignore")


settings = Settings()
