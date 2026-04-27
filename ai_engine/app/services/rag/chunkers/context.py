from uuid import UUID
from app.services.rag.chunkers.base import DocumentChunkerStrategy
from app.services.rag.chunkers.markdown_strategy import MarkdownRecursiveChunkerStrategy

class ChunkerContext:
    def __init__(self, strategy: DocumentChunkerStrategy = None):
        self._strategy = strategy if strategy else MarkdownRecursiveChunkerStrategy()

    def set_strategy(self, strategy: DocumentChunkerStrategy):
        self._strategy = strategy

    def execute_chunking(self, full_text: str, document_id: UUID) -> list:
        return self._strategy.chunk(full_text, document_id)
