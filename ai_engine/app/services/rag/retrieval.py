from typing import List
from app.core.database import get_vector_store

def retrieve_context_for_topics(topics: List[str], k: int = 8) -> str:
    """
    Retrieves the most relevant textbook chunks for the given topics.
    Prioritizes 'substantive' content (actual lessons/problems) over 
    'structural' content (TOC/headers).
    """
    vector_store = get_vector_store()
    query = " ".join(topics)
    
    # 1. Try to get only substantive chunks first
    docs = vector_store.similarity_search(
        query, 
        k=k, 
        filter={"content_type": "substantive"}
    )
    
    # 2. If we found very few substantive chunks, fall back to a normal search
    # This ensures we don't return an empty context if the classifier was too strict
    if len(docs) < (k // 2):
        docs = vector_store.similarity_search(query, k=k)
    
    # Combine chunks into context
    context = "\n\n---\n\n".join([doc.page_content for doc in docs])
    return context
