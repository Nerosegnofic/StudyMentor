"""
Unit tests for within-lesson skill de-duplication.

``deduplicate_skills_within_lessons`` merges near-duplicate skills inside a single
lesson based on cosine similarity, keeping the longest (broadest) text as the
representative. It must:
  - merge true near-duplicates while keeping genuinely distinct skills,
  - never compare across lessons,
  - never drop a lesson (>= 1 skill always survives),
  - leave single-skill lessons untouched (no embedding call),
  - be a graceful no-op when embedding fails.

Embeddings are injected via ``embed_fn`` so these tests are deterministic and never
call Cohere. We hand-craft vectors: identical vectors -> cosine 1.0 (merge),
orthogonal vectors -> cosine 0.0 (keep separate).
"""
import pytest

from app.services.rag.processors.skill_deduplicator import (
    deduplicate_skills_within_lessons,
)

# A tiny controllable embedding space. Each skill text maps to a fixed vector;
# texts meant to be "near-duplicates" share the same direction.
_VECTORS = {
    # Two near-duplicate reading skills (same direction).
    "القراءة الجهرية للنص": [1.0, 0.0, 0.0],
    "القراءة الجهرية الصحيحة للنص مع التنغيم": [1.0, 0.0, 0.0],
    # A distinct grammar skill (orthogonal direction).
    "التعرف على المفعول المطلق وإعرابه": [0.0, 1.0, 0.0],
    # A distinct spelling skill (third orthogonal direction).
    "كتابة الهمزة المتطرفة على الواو": [0.0, 0.0, 1.0],
    # A skill that recurs in a different lesson (same text as above, same vector).
    "تحديد عاصمة مصر": [0.5, 0.5, 0.0],
}


def _fake_embed(texts):
    # Unknown texts get a unique-ish nonzero vector so they never accidentally merge.
    out = []
    for i, t in enumerate(texts):
        out.append(_VECTORS.get(t, [0.0, 0.0, float(i + 1)]))
    return out


@pytest.mark.unit
def test_merges_near_duplicates_keeps_distinct_and_longest_representative():
    mastery = [
        {
            "unit": "U1",
            "lesson": "الدرس الثاني: القراءة",
            "objectives": [
                "القراءة الجهرية للنص",                       # dup A (short)
                "التعرف على المفعول المطلق وإعرابه",           # distinct grammar
                "القراءة الجهرية الصحيحة للنص مع التنغيم",     # dup A (long)
                "كتابة الهمزة المتطرفة على الواو",             # distinct spelling
            ],
            "skill_ids": ["s1", "s2", "s3", "s4"],
        }
    ]

    out = deduplicate_skills_within_lessons(mastery, threshold=0.9, embed_fn=_fake_embed)

    objs = out[0]["objectives"]
    # The two reading duplicates collapse to one; grammar + spelling survive -> 3 total.
    assert len(objs) == 3
    # The LONGER reading text is the kept representative.
    assert "القراءة الجهرية الصحيحة للنص مع التنغيم" in objs
    assert "القراءة الجهرية للنص" not in objs
    # Distinct strands are preserved (coverage guardrail).
    assert "التعرف على المفعول المطلق وإعرابه" in objs
    assert "كتابة الهمزة المتطرفة على الواو" in objs


@pytest.mark.unit
def test_single_skill_lesson_is_untouched_without_embedding():
    # embed_fn that explodes if called — proves single-skill lessons skip embedding.
    def _boom(texts):
        raise AssertionError("embed_fn must not be called for a single-skill lesson")

    mastery = [
        {"unit": "U1", "lesson": "L1", "objectives": ["only one skill"], "skill_ids": ["s1"]}
    ]
    out = deduplicate_skills_within_lessons(mastery, threshold=0.9, embed_fn=_boom)
    assert out[0]["objectives"] == ["only one skill"]


@pytest.mark.unit
def test_does_not_merge_across_lessons():
    # The same recurring skill in two different lessons must both survive.
    mastery = [
        {"unit": "U1", "lesson": "L1", "objectives": ["تحديد عاصمة مصر", "كتابة الهمزة المتطرفة على الواو"], "skill_ids": ["a1", "a2"]},
        {"unit": "U1", "lesson": "L2", "objectives": ["تحديد عاصمة مصر", "التعرف على المفعول المطلق وإعرابه"], "skill_ids": ["b1", "b2"]},
    ]
    out = deduplicate_skills_within_lessons(mastery, threshold=0.9, embed_fn=_fake_embed)
    # Both lessons keep both of their (distinct-within-lesson) skills.
    assert len(out) == 2
    assert "تحديد عاصمة مصر" in out[0]["objectives"]
    assert "تحديد عاصمة مصر" in out[1]["objectives"]


@pytest.mark.unit
def test_never_drops_a_lesson_and_keeps_at_least_one_skill():
    mastery = [
        {"unit": "U1", "lesson": "L1", "objectives": ["القراءة الجهرية للنص", "القراءة الجهرية الصحيحة للنص مع التنغيم"], "skill_ids": ["s1", "s2"]},
    ]
    out = deduplicate_skills_within_lessons(mastery, threshold=0.9, embed_fn=_fake_embed)
    assert len(out) == 1
    assert len(out[0]["objectives"]) >= 1


@pytest.mark.unit
def test_graceful_no_op_on_embedding_failure():
    def _failing_embed(texts):
        raise RuntimeError("cohere down")

    mastery = [
        {"unit": "U1", "lesson": "L1", "objectives": ["a", "b", "c"], "skill_ids": ["s1", "s2", "s3"]},
    ]
    out = deduplicate_skills_within_lessons(mastery, threshold=0.9, embed_fn=_failing_embed)
    # Returns the input unchanged rather than raising / dropping skills.
    assert out == mastery


@pytest.mark.unit
def test_empty_input_returns_empty():
    assert deduplicate_skills_within_lessons([], embed_fn=_fake_embed) == []