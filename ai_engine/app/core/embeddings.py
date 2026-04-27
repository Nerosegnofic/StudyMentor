import time
from typing import List
from langchain_cohere import CohereEmbeddings

class RateLimitedCohereEmbeddings(CohereEmbeddings):
    """
    Custom wrapper to safely embed thousands of sentences without hitting
    Cohere's free tier rate limits (100 Requests/Min, 100,000 Tokens/Min).
    """
    def embed_documents(self, texts: List[str]) -> List[List[float]]:
        # Cohere trial tier is limited to 100,000 Tokens Per Minute.
        # With our larger 1500-2000 char chunks, we must use smaller batches and longer sleeps.
        batch_size = 48
        all_embeddings = []
        
        total_batches = (len(texts) + batch_size - 1) // batch_size
        if total_batches > 1:
            print(f"Embedding {len(texts)} items across {total_batches} batches to respect rate limits...")
        
        for i in range(0, len(texts), batch_size):
            batch_num = (i // batch_size) + 1
            if total_batches > 1 and (batch_num == 1 or batch_num % 5 == 0 or batch_num == total_batches):
                print(f"Progress: Batch {batch_num}/{total_batches} embedded (Total Chunks: {len(all_embeddings)})...", flush=True)
                
            batch = texts[i:i + batch_size]
            
            try:
                embeddings = super().embed_documents(batch)
                all_embeddings.extend(embeddings)
            except Exception as e:
                print(f"Rate limit hit. Sleeping 30 seconds to cool down... Details: {e}")
                time.sleep(30)
                embeddings = super().embed_documents(batch)
                all_embeddings.extend(embeddings)
                
            if i + batch_size < len(texts):
                # 15s sleep between 48 chunks (~20k-40k tokens) ensures we stay under 100k/min.
                time.sleep(15)
                
        return all_embeddings
