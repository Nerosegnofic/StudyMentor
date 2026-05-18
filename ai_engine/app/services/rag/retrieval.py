from typing import List, Optional
from app.core.database import get_vector_store
from app.core.config import settings
from app.core.exceptions import InsufficientContextError


def retrieve_context_for_topics(
    topics: List[str],
    k: int = 10,
    firebase_uid: str = None,
    subject_id: int = None,
) -> str:
    """
    Retrieves a fair distribution of textbook chunks across multiple topics
    and formats them for injection into the LLM prompt.

    Uses Quota-based (Round Robin) retrieval with:
      - 4-tier safe fallback chain (never drops all filters — data leak risk)
      - Similarity score thresholding (filters irrelevant chunks)
      - Subject-scoped filtering (prevents cross-subject context contamination)
      - Empty context guard (never calls LLM with blank curriculum content)
      - Deduplication across topics

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

    # Role priority for re-ranking: lower number = higher priority in prompt
    ROLE_PRIORITY = {
        'explanation': 0,
        'rule': 0,
        'example': 0,
        'exercise': 0,
        'content': 0,
    }

    seen_contents: set = set()
    final_docs: list = []

    for topic in topics:
        topic_docs = _retrieve_with_safe_fallback(
            vector_store=vector_store,
            topic=topic,
            k=quota * 4,  # Fetch more than needed so we have room to filter and re-rank
            firebase_uid=firebase_uid,
            subject_id=subject_id,
        )

        # Re-rank by role priority (all content roles are equally prioritised here;
        # structural noise should have been excluded by the content_type filter)
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
    4-tier safe retrieval fallback. NEVER drops all filters simultaneously
    (which was the previous data leak risk).

    Tier 1: firebase_uid + subject_id + content_type=substantive  (full filter)
    Tier 2: firebase_uid + subject_id                             (drop content_type)
    Tier 3: subject_id only                                       (global subjects)
    ❌ Tier 4: no filter at all → REMOVED (was a cross-tenant data leak)
    """
    # Tier 1: Full filter (student's docs, correct subject, substantive content only)
    filter_t1 = {"content_type": "substantive"}
    if firebase_uid:
        filter_t1["firebase_uid"] = firebase_uid
    if subject_id is not None:
        filter_t1["subject_id"] = subject_id

    docs = _search_with_score(vector_store, topic, k, filter_t1)
    if docs:
        return docs

    # Tier 2: Drop content_type restriction (include structural chunks as fallback)
    filter_t2 = {}
    if firebase_uid:
        filter_t2["firebase_uid"] = firebase_uid
    if subject_id is not None:
        filter_t2["subject_id"] = subject_id

    if filter_t2:  # Only attempt if we have at least one filter
        docs = _search_with_score(vector_store, topic, k, filter_t2)
        if docs:
            return docs

    # Tier 3: Subject-only filter (for global/shared curriculum subjects)
    if subject_id is not None:
        docs = _search_with_score(vector_store, topic, k, {"subject_id": subject_id})
        if docs:
            return docs

    # All tiers exhausted — return empty list.
    # The caller's InsufficientContextError guard will handle this.
    return []


def _search_with_score(vector_store, topic: str, k: int, filter_dict: dict) -> list:
    """
    Performs a similarity search and filters out chunks that exceed the
    relevance threshold (high cosine distance = low relevance).

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
