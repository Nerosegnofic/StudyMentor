from uuid import UUID
from app.services.rag.parsers.base import DocumentParserStrategy
from app.services.rag.parsers.llama_strategy import LlamaParseStrategy

class ParserContext:
    def __init__(self, strategy: DocumentParserStrategy = None):
        self._strategy = strategy if strategy else LlamaParseStrategy()

    def set_strategy(self, strategy: DocumentParserStrategy):
        self._strategy = strategy

    def execute_parse(self, document_id: UUID, temp_file_path: str, language: str = "ar") -> str:
        return self._strategy.parse(document_id, temp_file_path, language=language)
