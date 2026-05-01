import os
from uuid import UUID
from langchain_experimental.text_splitter import SemanticChunker
from app.core.embeddings import RateLimitedCohereEmbeddings
from app.core.config import settings
from app.services.rag.chunkers.base import DocumentChunkerStrategy


class SemanticChunkerStrategy(DocumentChunkerStrategy):
    """
    Splits text based on semantic similarity using embeddings.
    
    Instead of relying on markdown headers or fixed character counts,
    this strategy embeds each sentence and detects where the topic
    shifts significantly. This produces chunks that are naturally
    grouped by meaning, making it ideal for textbooks with messy
    or inconsistent formatting.
    
    Breakpoint types:
        - "percentile" (default): splits when the distance between
          sentences exceeds a percentile threshold (e.g., top 5% 
          most dissimilar transitions become split points).
        - "standard_deviation": splits when distance exceeds X 
          standard deviations above the mean.
        - "interquartile": splits based on interquartile range.
    """

    def __init__(
        self,
        breakpoint_type: str = "percentile",
        breakpoint_threshold: float = 85,
    ):
        """
        Args:
            breakpoint_type: Method to determine split points.
            breakpoint_threshold: Sensitivity of the splits.
                For "percentile": 85 means split at the top 15% most
                dissimilar transitions (lower = more chunks).
                For "standard_deviation": number of std devs above mean.
        """
        self._breakpoint_type = breakpoint_type
        self._breakpoint_threshold = breakpoint_threshold

    def _get_embeddings(self):
        """Initialize the Cohere embedding model."""
        if settings.COHERE_API_KEY:
            os.environ["COHERE_API_KEY"] = settings.COHERE_API_KEY

        # Using multilingual model since your textbook is in Arabic
        return RateLimitedCohereEmbeddings(model="embed-multilingual-v3.0")

    def chunk(self, full_text: str, document_id: UUID) -> list:
        """
        Splits text into semantically coherent chunks.
        
        1. Uses Cohere embeddings to compute sentence similarities.
        2. Splits at points where topic shifts are detected.
        3. Attaches document_id metadata to each chunk.
        """
        embeddings = self._get_embeddings()
        semantic_chunker = SemanticChunker(
            embeddings=embeddings,
            breakpoint_threshold_type=self._breakpoint_type,
            breakpoint_threshold_amount=self._breakpoint_threshold,
        )

        langchain_docs = semantic_chunker.create_documents([full_text])

        for doc in langchain_docs:
            doc.metadata["document_id"] = str(document_id)

        print(
            f"[{document_id}] Semantic chunking complete: "
            f"{len(langchain_docs)} chunks created.",
            flush=True,
        )

        return langchain_docs
