import time
from typing import List
from langchain_cohere import CohereEmbeddings

class RateLimitedCohereEmbeddings(CohereEmbeddings):
    """
    Custom wrapper to safely embed thousands of sentences without hitting
    Cohere's free tier rate limits (100 Requests/Min, 100,000 Tokens/Min).
    """
    def embed_documents(self, texts: List[str]) -> List[List[float]]:
        # Cohere max batch size is 96. We'll send exactly 96 texts at a time.
        batch_size = 96
        all_embeddings = []
        
        total_batches = (len(texts) + batch_size - 1) // batch_size
        if total_batches > 1:
            print(f"Embedding {len(texts)} items across {total_batches} batches to respect rate limits...")
        
        for i in range(0, len(texts), batch_size):
            batch = texts[i:i + batch_size]
            
            try:
                embeddings = super().embed_documents(batch)
                all_embeddings.extend(embeddings)
            except Exception as e:
                print(f"Rate limit hit. Sleeping 60 seconds to cool down... Details: {e}")
                time.sleep(60)
                # Retry after cooldown
                embeddings = super().embed_documents(batch)
                all_embeddings.extend(embeddings)
                
            # If there are more batches left, sleep before sending the next one
            if i + batch_size < len(texts):
                # Sleep 6 seconds between batches -> ~10 batches a minute.
                # 10 batches * 96 sentences = ~960 sentences/minute.
                # This keeps us safely below the 100,000 TPM and 100 RPM limit.
                time.sleep(6)
                
        return all_embeddings
