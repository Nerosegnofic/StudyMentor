from abc import ABC, abstractmethod
from uuid import UUID

class DocumentParserStrategy(ABC):
    """
    Abstract Base Class defining the interface for document parsers.
    """
    @abstractmethod
    def parse(self, document_id: UUID, temp_file_path: str) -> str:
        pass
