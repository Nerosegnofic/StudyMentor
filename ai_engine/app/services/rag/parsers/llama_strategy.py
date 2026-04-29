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
            premium_mode=True,
            language="ar",
            system_prompt ="""
            This is a bilingual educational textbook. 
            IMPORTANT: The primary language is Arabic (RTL). 
            Please preserve the RTL reading order for Arabic sections. 
            Keep technical English terms in-line. 
            Output headers as # and sub-headers as ##.

            CRITICAL INSTRUCTION:
            At the end of EVERY SINGLE PAGE, you must extract the core learning objectives taught ON THAT SPECIFIC PAGE. 
            Append them at the bottom of the page's text under the exact header "### Mastery Points". 
            Do not wait until the end of the chapter. Extract the specific, actionable mathematical concepts and skills as a bulleted list in Arabic. 
            Example:
            ### Mastery Points
            - جمع الكسور ذات المقامات الموحدة
            - تبسيط الكسور إلى أبسط صورة
            """,
            verbose=True
        )
        print(f"[{document_id}] Starting LlamaParse extraction...", flush=True)
        documents = parser.load_data(temp_file_path)
        print(f"[{document_id}] Extraction complete! Found {len(documents)} pages.", flush=True)
        return "\n\n".join([doc.text for doc in documents])
