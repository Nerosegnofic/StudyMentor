from typing import List
from app.core.database import get_vector_store

def retrieve_context_for_topics(topics: List[str], k: int = 10) -> str:
    """
    Retrieves a fair distribution of textbook chunks across multiple topics.
    Uses Quota-based (Round Robin) retrieval with smart metadata filtering.
    
    Strategy:
        1. For each topic, search independently (prevents dominant topics).
        2. Prioritize 'substantive' chunks (exercises, examples, rules).
        3. Exclude structural noise (TOC, unit headers, concept headers).
        4. Deduplicate across topics.
    """
    vector_store = get_vector_store()
    
    # Calculate quota per topic (minimum 2 chunks per topic)
    quota = max(2, k // len(topics))
    
    # 1. Define priority (Lower number = Higher priority)
    ROLE_PRIORITY = {
        'explanation': 0,
        'rule': 0,
        'example': 0,
        'exercise': 0,
        'content': 0
    }
    
    seen_contents = set()
    final_docs = []
    
    for topic in topics:
        # 2. Search for this topic (fetch more than needed to allow for re-ranking)
        topic_docs = vector_store.similarity_search(
            topic, 
            k=quota * 4, 
            filter={"content_type": "substantive"}
        )
        
        # 3. Fallback
        if len(topic_docs) < 1:
            topic_docs = vector_store.similarity_search(topic, k=quota * 4)
        
        # 4. RE-RANK: Sort by Role Priority first, then by Similarity (original order)
        topic_docs.sort(key=lambda d: ROLE_PRIORITY.get(d.metadata.get('chunk_role', 'content'), 10))
        
        # 5. Filter by useful roles and deduplicate
        added = 0
        for doc in topic_docs:
            if added >= quota:
                break
                
            if doc.page_content not in seen_contents:
                final_docs.append(doc)
                seen_contents.add(doc.page_content)
                added += 1
    
    # Limit to a reasonable total
    final_docs = final_docs[:k + 5]
    
    # Combine chunks into context, including parent info for the LLM
    context_parts = []
    for doc in final_docs:
        # Prepend parent context so the LLM knows where this chunk comes from
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
    
    context = "\n\n---\n\n".join(context_parts)
    return context
