import os
from uuid import UUID
from llama_parse import LlamaParse
from app.core.config import settings
from app.services.rag.parsers.base import DocumentParserStrategy

class LlamaParseStrategy(DocumentParserStrategy):
    """
    Implementation of Document Parsing using LlamaParse API.
    """
    def parse(self, document_id: UUID, temp_file_path: str) -> str:
        if settings.LLAMA_CLOUD_API_KEY:
            os.environ["LLAMA_CLOUD_API_KEY"] = settings.LLAMA_CLOUD_API_KEY
            
        parser = LlamaParse(
            result_type="markdown",
            language="ar",
            verbose=True
        )
        print(f"[{document_id}] Starting LlamaParse extraction...")
        documents = parser.load_data(temp_file_path)
        print(f"[{document_id}] Extraction complete! Found {len(documents)} pages.")
        return "\n\n".join([doc.text for doc in documents])
