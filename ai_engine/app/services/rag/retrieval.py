from typing import List, Optional
from app.core.database import get_vector_store
from app.core.config import settings
from app.core.exceptions import InsufficientContextError


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


def retrieve_context_for_topics(
    topics: List[str],
    k: int = 10,
    firebase_uid: str = None,
    subject_id: int = None,
) -> str:
    """
    Retrieves a fair distribution of textbook chunks across multiple topics
    and formats them for injection into the LLM prompt.

    Uses MMR (Maximum Marginal Relevance) retrieval with:
      - 4-tier safe fallback chain (never drops all filters — data leak risk)
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
    """
    vector_store = get_vector_store()

    # Calculate per-topic quota (minimum 2 chunks per topic to ensure coverage)
    quota = max(2, k // max(len(topics), 1))

    seen_contents: set = set()
    final_docs: list = []

    for topic in topics:
        topic_docs = _retrieve_with_safe_fallback(
            vector_store=vector_store,
            topic=topic,
            k=quota * 4,  # Fetch more than needed for MMR diversity pool
            firebase_uid=firebase_uid,
            subject_id=subject_id,
        )

        # Re-rank by role priority (examples/exercises first)
        topic_docs.sort(
            key=lambda d: ROLE_PRIORITY.get(d.metadata.get('chunk_role', 'content'), 10)
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
    """
    vector_store = get_vector_store()

    seen_contents: set = set()
    final_docs: list = []

    for cfg in quiz_payload:
        skill_name = cfg["skill"]
        zone = cfg.get("zone", "frontier")
        budget = _ZONE_BUDGETS.get(zone, 2)

        topic_docs = _retrieve_with_safe_fallback(
            vector_store=vector_store,
            topic=skill_name,
            k=budget * 3,  # Fetch 3x budget for filtering headroom
            firebase_uid=firebase_uid,
            subject_id=subject_id,
        )

        # Re-rank by role priority
        if zone == "preview":
            # For preview, prefer explanations (objectives/intro text)
            topic_docs.sort(
                key=lambda d: 0 if d.metadata.get('chunk_role') in ('explanation', 'content') else 1
            )
        else:
            # For frontier/review, prefer examples and exercises
            topic_docs.sort(
                key=lambda d: ROLE_PRIORITY.get(d.metadata.get('chunk_role', 'content'), 10)
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
) -> list:
    """
    4-tier safe retrieval fallback using MMR for diversity.
    NEVER drops all filters simultaneously (cross-tenant data leak risk).

    Tier 1: firebase_uid + subject_id + content_type=substantive  (full filter)
    Tier 2: firebase_uid + subject_id                             (drop content_type)
    Tier 3: subject_id only                                       (global subjects)
    ❌ Tier 4: no filter at all → REMOVED (was a cross-tenant data leak)
    """
    # Build filter tiers
    tiers = []

    # Tier 1: Full filter (student's docs, correct subject, substantive content only)
    t1 = {"content_type": "substantive"}
    if firebase_uid:
        t1["firebase_uid"] = firebase_uid
    if subject_id is not None:
        t1["subject_id"] = subject_id
    tiers.append(t1)

    # Tier 2: Drop content_type restriction (include structural chunks as fallback)
    t2 = {}
    if firebase_uid:
        t2["firebase_uid"] = firebase_uid
    if subject_id is not None:
        t2["subject_id"] = subject_id
    if t2:  # Only attempt if we have at least one filter
        tiers.append(t2)

    # Tier 3: Subject-only filter (for global/shared curriculum subjects)
    if subject_id is not None:
        tiers.append({"subject_id": subject_id})

    for filter_dict in tiers:
        docs = _search_with_mmr(vector_store, topic, k, filter_dict)
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
        return _search_with_score(vector_store, topic, k, filter_dict)
    except Exception as e:
        print(f"[Retrieval] MMR search failed with filter {filter_dict}: {e}", flush=True)
        return _search_with_score(vector_store, topic, k, filter_dict)


def _search_with_score(vector_store, topic: str, k: int, filter_dict: dict) -> list:
    """
    Fallback: similarity search with score-based relevance filtering.

    PGVector returns cosine distance: 0.0 = identical, 2.0 = opposite.
    Chunks with distance > RETRIEVAL_SCORE_THRESHOLD are too dissimilar to
    inject as curriculum context — they would degrade quiz quality.
    """
    try:
        docs_with_scores = vector_store.similarity_search_with_score(
            topic, k=k, filter=filter_dict
        )
        accepted = []
        rejected_scores = []
        for doc, score in docs_with_scores:
            if score <= settings.RETRIEVAL_SCORE_THRESHOLD:
                accepted.append(doc)
            else:
                rejected_scores.append(round(score, 3))
        if rejected_scores:
            print(
                f"[Retrieval] Filtered {len(rejected_scores)} chunks above threshold "
                f"({settings.RETRIEVAL_SCORE_THRESHOLD}): {rejected_scores[:5]}",
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
