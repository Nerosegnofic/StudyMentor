from uuid import UUID
from app.services.rag.parsers.base import DocumentParserStrategy

class PyMuPDFStrategy(DocumentParserStrategy):
    """
    Local fallback strategy for PDF parsing using PyMuPDF (fitz).
    Faster and free, but less accurate for complex layouts.
    Requires: pip install pymupdf
    """
    def parse(self, document_id: UUID, temp_file_path: str) -> str:
        try:
            import fitz
        except ImportError:
            raise ImportError("PyMuPDF is not installed. Please install it using 'pip install pymupdf'")
            
        print(f"[{document_id}] Starting local PyMuPDF extraction...")
        doc = fitz.open(temp_file_path)
        text_blocks = []
        for page in doc:
            text_blocks.append(page.get_text())
        doc.close()
        
        print(f"[{document_id}] Extraction complete! Found {len(text_blocks)} pages.")
        return "\n\n".join(text_blocks)
