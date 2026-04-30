import re

def preprocess_parsed_text(text: str) -> str:
    """
    Cleans raw parsed text from LlamaIndex or other parsers to prepare it
    for extraction and chunking. Focuses on removing noise and normalizing whitespace.
    """
    if not text:
        return ""

    cleaned_lines = []
    # Patterns for noise (page numbers, standalone figure labels)
    noise_patterns = [
        re.compile(r'^#+\s*\d+\s*$'), 
        re.compile(r'^#+\s*(Figure|Fig|Table)\s*\d*', re.IGNORECASE)
    ]
    # Footer patterns: "123 | الدرس الأول: ..." or "الدرس الأول: ... 45"
    footer_patterns = [
        # Page number before pipe: "79 | الدرس الخامس: ..."
        re.compile(r'^\d{1,3}\s*\|\s*الدرس.+$'),
        # Page number at end of line after lesson ref: "الدرس الثالث: ... 73"
        re.compile(r'^الدرس.+\s+\d{1,3}\s*$'),
    ]
    
    for line in text.split('\n'):
        stripped = line.strip()
        if stripped.startswith('#') and any(p.match(stripped) for p in noise_patterns):
            cleaned_lines.append(stripped.lstrip('#').strip()) # Demote to plain text
        elif any(p.match(stripped) for p in footer_patterns):
            cleaned_lines.append('')  # Remove footer lines entirely
        else:
            cleaned_lines.append(line) # PRESERVE real headers

    return '\n'.join(cleaned_lines)
