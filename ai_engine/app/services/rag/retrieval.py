from typing import List
from app.core.database import get_vector_store

def retrieve_context_for_topics(topics: List[str], k: int = 5) -> str:
    """
    Retrieves the most relevant textbook chunks for the given math topics
    using a vector database similarity search.
    
    Args:
        topics (List[str]): The math topics to search for.
        k (int): Number of chunks to retrieve (default is 5).
        
    Returns:
        str: A concatenated block of markdown chunk context.
    """
    vector_store = get_vector_store()
    
    # Combine topics into a single query string for retrieval
    query = " ".join(topics)
    docs = vector_store.similarity_search(query, k=k)
    
    # Combine the returned document chunks into a single context string
    context = "\n\n---\n\n".join([doc.page_content for doc in docs])
    return context
