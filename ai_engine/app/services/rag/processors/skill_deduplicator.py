"""
Programmatic within-lesson skill de-duplication (post-extraction safety net).

The LLM skill extractor (mastery_refiner) is prompted to consolidate near-duplicate
skills, but that is non-deterministic and can drift. This pass is the deterministic
guardrail: after extraction, embed each lesson's skill texts and merge skills whose
cosine similarity is at/above a threshold — but ONLY within the same lesson.

Within-lesson scope is deliberate (see plan): a lesson is a single teachable context,
so two near-identical skills there are genuinely redundant. We never compare across
lessons, so a skill that legitimately recurs in every lesson (e.g. "reading
comprehension" in a language book) is left alone, and the per-(name, subject_id)
upsert + chunk skill_names tagging stay consistent.

Best-effort and non-fatal: if Cohere is unavailable or embedding fails, the input is
returned unchanged — skill de-duplication must never block ingestion.
"""
from typing import Callable, List, Optional

from app.core.config import settings

# Type of the pluggable embedding function: list of texts -> list of vectors.
EmbedFn = Callable[[List[str]], List[List[float]]]


def _default_embed_fn(texts: List[str]) -> List[List[float]]:
    """Embed with the same Cohere model the rest of the pipeline uses.

    Built lazily (and per-call) so importing this module never requires Cohere,
    and so a missing key surfaces as a caught exception -> graceful no-op.
    """
    from app.core.embeddings import RateLimitedCohereEmbeddings

    embedder = RateLimitedCohereEmbeddings(
        cohere_api_key=settings.COHERE_API_KEY,
        model=settings.COHERE_EMBEDDING_MODEL,
    )
    return embedder.embed_documents(texts)


def _cosine(a: List[float], b: List[float]) -> float:
    dot = sum(x * y for x, y in zip(a, b))
    na = sum(x * x for x in a) ** 0.5
    nb = sum(y * y for y in b) ** 0.5
    if na == 0.0 or nb == 0.0:
        return 0.0
    return dot / (na * nb)


def _dedupe_one_lesson(
    objectives: List[str],
    skill_ids: List[str],
    embeddings: List[List[float]],
    threshold: float,
):
    """Greedy single-link clustering within one lesson.

    Walks objectives in order; each one either joins an existing kept cluster (if it
    is >= threshold similar to that cluster's representative) or starts a new one.
    The representative is the LONGEST text seen in the cluster (most descriptive /
    broadest), and it keeps its own skill_id. Order of first appearance is preserved.
    Returns (kept_objectives, kept_skill_ids).
    """
    kept_idx: List[int] = []  # representative index per kept cluster
    for i, _ in enumerate(objectives):
        merged_into = None
        for k in kept_idx:
            if _cosine(embeddings[i], embeddings[k]) >= threshold:
                merged_into = k
                break
        if merged_into is None:
            kept_idx.append(i)
        else:
            # Promote the longer text to be the cluster representative.
            if len(objectives[i]) > len(objectives[merged_into]):
                pos = kept_idx.index(merged_into)
                kept_idx[pos] = i

    kept_idx_sorted = sorted(kept_idx)
    kept_objs = [objectives[i] for i in kept_idx_sorted]
    kept_ids = [skill_ids[i] if i < len(skill_ids) else "" for i in kept_idx_sorted]
    return kept_objs, kept_ids


def deduplicate_skills_within_lessons(
    mastery_data: List[dict],
    threshold: Optional[float] = None,
    embed_fn: Optional[EmbedFn] = None,
) -> List[dict]:
    """Merge near-duplicate skills within each lesson.

    Args:
        mastery_data: standard mastery shape
            [{'unit', 'lesson', 'objectives': [str], 'skill_ids': [str]}].
        threshold: cosine-similarity merge threshold; defaults to
            settings.SKILL_DEDUP_SIMILARITY_THRESHOLD.
        embed_fn: injectable embedding function (defaults to Cohere). Tests pass a fake.

    Returns:
        A new mastery list with within-lesson near-duplicates merged. On any failure
        (no Cohere key, embedding error) returns the input unchanged. Never drops a
        lesson; every lesson keeps >= 1 skill.
    """
    if not mastery_data:
        return mastery_data

    if threshold is None:
        threshold = settings.SKILL_DEDUP_SIMILARITY_THRESHOLD
    if embed_fn is None:
        if not settings.COHERE_API_KEY:
            print("[SkillDedup] COHERE_API_KEY not set. Skipping de-duplication.", flush=True)
            return mastery_data
        embed_fn = _default_embed_fn

    result: List[dict] = []
    total_before = 0
    total_after = 0
    try:
        for entry in mastery_data:
            objectives = entry.get("objectives", []) or []
            skill_ids = entry.get("skill_ids", []) or []
            total_before += len(objectives)

            if len(objectives) <= 1:
                # Nothing to compare — pass through untouched (no embedding call).
                result.append(entry)
                total_after += len(objectives)
                continue

            embeddings = embed_fn(objectives)
            kept_objs, kept_ids = _dedupe_one_lesson(
                objectives, skill_ids, embeddings, threshold
            )

            if len(kept_objs) < len(objectives):
                print(
                    f"[SkillDedup] lesson '{entry.get('lesson', '')}': "
                    f"{len(objectives)} -> {len(kept_objs)} skills.",
                    flush=True,
                )

            new_entry = dict(entry)
            new_entry["objectives"] = kept_objs
            new_entry["skill_ids"] = kept_ids
            result.append(new_entry)
            total_after += len(kept_objs)
    except Exception as e:
        # Best-effort: never block ingestion on de-duplication.
        print(f"[SkillDedup] De-duplication failed ({e}). Using original skills.", flush=True)
        return mastery_data

    if total_after < total_before:
        print(
            f"[SkillDedup] [OK] Merged within-lesson duplicates: "
            f"{total_before} -> {total_after} skills total.",
            flush=True,
        )
    return result