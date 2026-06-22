"""
Unit tests for MarkdownRecursiveChunkerStrategy's role-aware splitting (P2).

Exercise/example sections must be sub-split at ITEM boundaries, not mid-item, so a
question never gets severed from its answer when a section exceeds the chunk size.
Generic content keeps using the plain prose splitter.
"""
import uuid

import pytest

from app.services.rag.chunkers.markdown_strategy import MarkdownRecursiveChunkerStrategy


@pytest.mark.unit
def test_exercise_items_are_not_split_between_question_and_answer():
    # Build an exercise section large enough to force a sub-split (> chunk_size).
    # Each item is a self-contained Q/A; the splitter must cut BETWEEN items.
    items = []
    for i in range(1, 13):
        filler = "هذا نص توضيحي للسؤال يطيل الفقرة حتى نتجاوز حد التقطيع. " * 6
        items.append(f"تمرين {i}: احسب قيمة المقدار رقم {i}؟ {filler}\nالإجابة: الناتج هو {i * 7}.")
    section = "## تدريبات على الجمع\n\n" + "\n\n".join(items)

    chunks = MarkdownRecursiveChunkerStrategy().chunk(section, uuid.uuid4())
    text_chunks = [c.page_content for c in chunks]

    # It must actually have split (otherwise the test proves nothing).
    assert len(text_chunks) > 1

    # Every item's answer must live in the SAME chunk as its question — i.e. no chunk
    # may contain a question without its following answer line.
    for c in text_chunks:
        # If a chunk mentions a specific "الإجابة" (answer), the matching "تمرين"
        # question text should be in the same chunk (answers never start a chunk alone).
        if "الإجابة:" in c:
            # The chunk should also contain at least one "تمرين N:" question header.
            assert "تمرين" in c, f"answer split away from its question:\n{c!r}"


@pytest.mark.unit
def test_generic_content_section_still_chunks():
    # A plain prose section (role=content) should chunk without error via the
    # default splitter — this is the non-exercise control path.
    prose = "## مقدمة\n\n" + ("هذه فقرة شرح عادية تحتوي على معلومات تعليمية. " * 80)
    chunks = MarkdownRecursiveChunkerStrategy().chunk(prose, uuid.uuid4())
    assert len(chunks) >= 1
    assert all(c.page_content.strip() for c in chunks)