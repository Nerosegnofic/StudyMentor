from abc import ABC, abstractmethod
from uuid import UUID

class DocumentChunkerStrategy(ABC):
    @abstractmethod
    def chunk(self, full_text: str, document_id: UUID) -> list:
        """Splits text and returns a list of LangChain Document objects."""
        pass
