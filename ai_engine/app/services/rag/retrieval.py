import random
import re
from typing import List, Optional
from app.core.database import get_vector_store
from app.core.config import settings
from app.core.exceptions import InsufficientContextError


# ---------------------------------------------------------------------------
# Subject-aware retrieval threshold.
# Language subjects (Arabic/English) have short rule/vocabulary chunks that
# tend to score less similar, so they get a more lenient distance threshold.
# ---------------------------------------------------------------------------
_LANGUAGE_SUBJECT_PATTERNS = re.compile(
    r"english|connect|انجليز|إنجليز|عربي|عربية|لغتي|لغة\s*عربية|قراءة|نحو",
    re.IGNORECASE,
)


def _is_language_subject(subject_name: Optional[str]) -> bool:
    """True if the subject name looks like an Arabic/English language subject."""
    if not subject_name:
        return False
    return bool(_LANGUAGE_SUBJECT_PATTERNS.search(subject_name))


def get_score_threshold(subject_name: Optional[str] = None) -> float:
    """
    Return the retrieval distance threshold for a subject.

    Language subjects use the lenient 'language' override; everything else
    (and an unknown/missing subject) uses 'default', which mirrors the legacy
    flat RETRIEVAL_SCORE_THRESHOLD for backward compatibility.
    """
    by_subject = settings.RETRIEVAL_SCORE_THRESHOLD_BY_SUBJECT or {}
    default = by_subject.get("default", settings.RETRIEVAL_SCORE_THRESHOLD)
    if _is_language_subject(subject_name):
        return by_subject.get("language", default)
    return default


# ---------------------------------------------------------------------------
# Role Priority for re-ranking: lower number = higher priority in prompt.
# Examples and exercises are most useful for quiz generation; explanations
# provide supporting context; generic content is lowest priority.
# ---------------------------------------------------------------------------
ROLE_PRIORITY = {
    'example': 0,       # Best for question generation — contains worked solutions
    'exercise': 0,      # Equally good — contains practice problems
    'rule': 1,          # Rules inform question design
    'explanation': 2,   # Good context but less directly usable
    'content': 3,       # Generic content — lowest priority
}

# Zone-specific context budgets: how many chunks per skill per zone.
_ZONE_BUDGETS = {
    "frontier": 5,   # Rich context for active learning
    "review": 2,     # Light context for recall questions
    "preview": 1,    # Minimal — just enough for a simple intro question
}


def _rank_with_intra_tier_shuffle(docs: list, key) -> list:
    """Rank docs by a priority `key` (lower = better) but SHUFFLE ties.

    Variety fix: retrieval is deterministic, so repeated quizzes on the same skill
    always picked the same top-N chunks → repetitive questions. Here we group docs by
    their priority value, shuffle each group, then concatenate groups in priority
    order. The best tier (e.g. examples/exercises) still comes first — quality is
    preserved — but *which* of the equally-good chunks lead varies each call, so the
    downstream "take the first `budget`" selection rotates over runs. Stateless
    (unseeded `random`), so every generation differs.
    """
    tiers: dict = {}
    for d in docs:
        tiers.setdefault(key(d), []).append(d)
    ranked: list = []
    for priority in sorted(tiers):
        bucket = tiers[priority]
        random.shuffle(bucket)
        ranked.extend(bucket)
    return ranked


def retrieve_context_for_topics(
    topics: List[str],
    k: int = 10,
    firebase_uid: str = None,
    subject_id: int = None,
    subject_name: str = None,
    is_global: bool = False,
) -> str:
    """
    Retrieves a fair distribution of textbook chunks across multiple topics
    and formats them for injection into the LLM prompt.

    Uses MMR (Maximum Marginal Relevance) retrieval with:
      - Tenant-safe fallback chain (a private subject never drops firebase_uid)
      - Subject-scoped filtering (prevents cross-subject context contamination)
      - Deduplication across topics
      - Empty context guard (never calls LLM with blank curriculum content)

    Args:
        topics: List of skill/topic names to retrieve context for.
        k: Total number of chunks to retrieve across all topics.
        firebase_uid: The authenticated student's Firebase UID. Used to scope
                      retrieval to this student's uploaded documents.
        subject_id: The subject ID of the quiz being generated. Prevents chunks
                    from other subjects being injected into the prompt.
        subject_name: Subject name used only to select a subject-tuned retrieval
                      threshold (language subjects get a more lenient value).
        is_global: Whether the subject is admin-published shared curriculum. Only
                   global subjects may be retrieved by subject_id alone (their
                   chunks carry no firebase_uid); private subjects ALWAYS require
                   the owner's firebase_uid (cross-student isolation).
    """
    vector_store = get_vector_store()
    score_threshold = get_score_threshold(subject_name)

    # Calculate per-topic quota (minimum 2 chunks per topic to ensure coverage)
    quota = max(2, k // max(len(topics), 1))

    seen_contents: set = set()
    final_docs: list = []

    for topic in topics:
        topic_docs = _retrieve_with_safe_fallback(
            vector_store=vector_store,
            topic=topic,
            k=quota * 6,  # Wider pool so the intra-tier shuffle has chunks to rotate among
            firebase_uid=firebase_uid,
            subject_id=subject_id,
            score_threshold=score_threshold,
            is_global=is_global,
        )

        # Rank by role priority (examples/exercises first), shuffling ties so repeated
        # retrievals for the same topic rotate over equally-good chunks.
        topic_docs = _rank_with_intra_tier_shuffle(
            topic_docs,
            key=lambda d: ROLE_PRIORITY.get(d.metadata.get('chunk_role', 'content'), 10),
        )

        added = 0
        for doc in topic_docs:
            if added >= quota:
                break
            if doc.page_content not in seen_contents:
                final_docs.append(doc)
                seen_contents.add(doc.page_content)
                added += 1

    # Hard cap at k + 5 to keep the prompt within token limits
    final_docs = final_docs[:k + 5]

    # Format chunks into the context string injected into the LLM prompt
    context = _format_context(final_docs)

    # Empty context guard: never call the LLM with blank curriculum content.
    # This prevents Gemini from hallucinating questions with no grounding.
    if len(context.strip()) < 50:
        raise InsufficientContextError(
            f"No relevant curriculum context found for topics: {topics}. "
            f"(subject_id={subject_id}, firebase_uid={firebase_uid}). "
            f"Ensure the curriculum document has been uploaded and processed."
        )

    return context


def retrieve_context_for_quiz(
    quiz_payload: list,
    k: int = 15,
    firebase_uid: str = None,
    subject_id: int = None,
    subject_name: str = None,
    is_global: bool = False,
) -> str:
    """
    Zone-aware retrieval: allocates different context budgets per zone.

    Frontier skills get deep context (examples, exercises, explanations).
    Review skills get light context (just enough for a recall question).
    Preview skills get minimal context (learning objectives only).

    Args:
        quiz_payload: List of dicts with 'skill' (name), 'zone', etc.
                      Output of build_quiz_payload().
        k: Maximum total chunks across all skills.
        firebase_uid: Student's Firebase UID for scoping.
        subject_id: Subject ID for scoping.
        subject_name: Subject name used only to select a subject-tuned retrieval
                      threshold (language subjects get a more lenient value).
        is_global: Whether the subject is admin-published shared curriculum. Only
                   global subjects may be retrieved by subject_id alone; private
                   subjects ALWAYS require the owner's firebase_uid.
    """
    vector_store = get_vector_store()
    score_threshold = get_score_threshold(subject_name)

    seen_contents: set = set()
    final_docs: list = []

    for cfg in quiz_payload:
        skill_name = cfg["skill"]
        zone = cfg.get("zone", "frontier")
        difficulty = cfg.get("difficulty", 3)
        budget = _ZONE_BUDGETS.get(zone, 2)

        topic_docs = _retrieve_with_safe_fallback(
            vector_store=vector_store,
            topic=skill_name,
            k=budget * 5,  # Wider pool so the intra-tier shuffle has chunks to rotate among
            firebase_uid=firebase_uid,
            subject_id=subject_id,
            score_threshold=score_threshold,
            is_global=is_global,
        )

        # Rank by role priority — adapted to difficulty level — then shuffle ties so
        # repeated quizzes on the same skill rotate over equally-good chunks (variety).
        # Low difficulty (1-2): prefer explanations, definitions, and rules
        # (facts the student needs to recall), NOT exercises/examples which
        # contain complex problems that bias the LLM toward harder output.
        # High difficulty (3+): prefer examples and exercises as before.
        if zone == "preview" or difficulty <= 2:
            # For preview or easy questions, prefer explanations (objectives/intro/definitions)
            topic_docs = _rank_with_intra_tier_shuffle(
                topic_docs,
                key=lambda d: 0 if d.metadata.get('chunk_role') in ('explanation', 'content', 'rule') else 1,
            )
        else:
            # For frontier/review at medium+ difficulty, prefer examples and exercises
            topic_docs = _rank_with_intra_tier_shuffle(
                topic_docs,
                key=lambda d: ROLE_PRIORITY.get(d.metadata.get('chunk_role', 'content'), 10),
            )

        added = 0
        for doc in topic_docs:
            if added >= budget:
                break
            if doc.page_content not in seen_contents:
                doc.metadata["quiz_zone"] = zone
                final_docs.append(doc)
                seen_contents.add(doc.page_content)
                added += 1

    # Hard cap
    final_docs = final_docs[:k + 5]

    context = _format_context(final_docs)

    if len(context.strip()) < 50:
        raise InsufficientContextError(
            f"No relevant curriculum context found for quiz skills. "
            f"(subject_id={subject_id}, firebase_uid={firebase_uid}). "
            f"Ensure the curriculum document has been uploaded and processed."
        )

    return context


# ---------------------------------------------------------------------------
# Internal Helpers
# ---------------------------------------------------------------------------

def _retrieve_with_safe_fallback(
    vector_store,
    topic: str,
    k: int,
    firebase_uid: Optional[str],
    subject_id: Optional[int],
    score_threshold: Optional[float] = None,
    is_global: bool = False,
) -> list:
    """
    Tenant-safe retrieval fallback using MMR for diversity.

    The tier chain is chosen by subject ownership so a PRIVATE subject can never
    leak another student's chunks:

    Private subject (is_global=False) — owner's chunks only:
        Tier 1: firebase_uid + subject_id + content_type=substantive
        Tier 2: firebase_uid + subject_id            (drop content_type)
        (NO subject_id-only tier — that would drop the owner filter.)

    Global subject (is_global=True) — admin-published shared curriculum whose
    chunks carry no firebase_uid:
        Tier 1: subject_id + content_type=substantive
        Tier 2: subject_id                            (drop content_type)
    """
    tiers = []

    if is_global:
        # Shared curriculum: scope by subject only (chunks have no owner).
        t1 = {"content_type": "substantive"}
        if subject_id is not None:
            t1["subject_id"] = subject_id
        tiers.append(t1)

        if subject_id is not None:
            tiers.append({"subject_id": subject_id})
    else:
        # Private subject: the owner's firebase_uid is mandatory on every tier.
        t1 = {"content_type": "substantive"}
        if firebase_uid:
            t1["firebase_uid"] = firebase_uid
        if subject_id is not None:
            t1["subject_id"] = subject_id
        tiers.append(t1)

        t2 = {}
        if firebase_uid:
            t2["firebase_uid"] = firebase_uid
        if subject_id is not None:
            t2["subject_id"] = subject_id
        if t2:  # Only attempt if we have at least one filter
            tiers.append(t2)

    for filter_dict in tiers:
        docs = _search_with_mmr(vector_store, topic, k, filter_dict, score_threshold=score_threshold)
        if docs:
            return docs

    # All tiers exhausted — return empty list.
    # The caller's InsufficientContextError guard will handle this.
    return []


def _search_with_mmr(
    vector_store,
    topic: str,
    k: int,
    filter_dict: dict,
    lambda_mult: float = 0.5,
    score_threshold: Optional[float] = None,
) -> list:
    """
    MMR (Maximum Marginal Relevance) retrieval: balances relevance
    (similarity to query) with diversity (dissimilarity between selected chunks).

    lambda_mult controls the trade-off:
        1.0 = pure similarity (old behavior)
        0.5 = balanced relevance + diversity (recommended)
        0.0 = maximum diversity

    Falls back to similarity_search_with_score if MMR is unavailable.
    """
    try:
        docs = vector_store.max_marginal_relevance_search(
            topic,
            k=k,
            fetch_k=k * 4,  # Fetch more candidates for better MMR selection
            lambda_mult=lambda_mult,
            filter=filter_dict,
        )
        return docs
    except AttributeError:
        # MMR not available on this vector store — fall back to similarity search
        print(
            f"[Retrieval] MMR not available, falling back to similarity search.",
            flush=True,
        )
        return _search_with_score(vector_store, topic, k, filter_dict, score_threshold=score_threshold)
    except Exception as e:
        print(f"[Retrieval] MMR search failed with filter {filter_dict}: {e}", flush=True)
        return _search_with_score(vector_store, topic, k, filter_dict, score_threshold=score_threshold)


def _search_with_score(
    vector_store, topic: str, k: int, filter_dict: dict, score_threshold: Optional[float] = None
) -> list:
    """
    Fallback: similarity search with score-based relevance filtering.

    PGVector returns cosine distance: 0.0 = identical, 2.0 = opposite.
    Chunks with distance > the threshold are too dissimilar to inject as
    curriculum context — they would degrade quiz quality. The threshold is
    subject-tuned by the caller; defaults to the flat RETRIEVAL_SCORE_THRESHOLD.
    """
    threshold = score_threshold if score_threshold is not None else settings.RETRIEVAL_SCORE_THRESHOLD
    try:
        docs_with_scores = vector_store.similarity_search_with_score(
            topic, k=k, filter=filter_dict
        )
        accepted = []
        rejected_scores = []
        for doc, score in docs_with_scores:
            if score <= threshold:
                accepted.append(doc)
            else:
                rejected_scores.append(round(score, 3))
        if rejected_scores:
            print(
                f"[Retrieval] Filtered {len(rejected_scores)} chunks above threshold "
                f"({threshold}): {rejected_scores[:5]}",
                flush=True,
            )
        return accepted
    except Exception as e:
        print(f"[Retrieval] Warning: Search failed with filter {filter_dict}: {e}", flush=True)
        return []


def _format_context(docs: list) -> str:
    """
    Formats retrieved chunks into the context string injected into the LLM prompt.
    Prepends [Unit > Lesson] breadcrumbs so Gemini knows the curriculum location
    of each chunk, which improves question relevance.
    """
    context_parts = []
    for doc in docs:
        parent_info = []
        if doc.metadata.get('parent_unit'):
            parent_info.append(doc.metadata['parent_unit'])
        if doc.metadata.get('parent_lesson'):
            parent_info.append(doc.metadata['parent_lesson'])

        header = " > ".join(parent_info) if parent_info else ""
        if header:
            context_parts.append(f"[{header}]\n{doc.page_content}")
        else:
            context_parts.append(doc.page_content)

    return "\n\n---\n\n".join(context_parts)
