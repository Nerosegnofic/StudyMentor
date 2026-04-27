import re
import unicodedata

class ChunkClassifier:
    """
    A generic classifier to distinguish between substantive educational content
    and structural noise (TOC, headers, unit lists) for Egyptian Primary School books.
    Supports Arabic and English subjects (Math, Science, English, etc.)
    """
    
    @staticmethod
    def classify(text: str) -> dict:
        # Normalize text to handle different Unicode representations (important for Arabic)
        text = unicodedata.normalize('NFKC', text)
        
        substantive_score = 0
        structural_score = 0
        
        # --- 1. STRUCTURAL INDICATORS (TOC, Navigation, Meta, Overviews) ---
        
        # Table of Contents patterns (e.g., "Lesson 1 ...... 136")
        if re.search(r'(\.\.\.|\.\.\.\.|---|_)\s*\d+', text):
            structural_score += 10 # High penalty for TOC

        # Multiple Lesson references in one chunk (Strong Overview/TOC signal)
        lesson_refs = len(re.findall(r'(الدرس|Lesson)\s*\(?\d+\)?', text, re.IGNORECASE))
        if lesson_refs > 1:
            structural_score += 8
            
        # Bullet Point Density (Overview lists often have > 40% bulleted lines)
        lines = [l.strip() for l in text.split('\n') if l.strip()]
        if lines:
            bullet_lines = sum(1 for l in lines if l.startswith(('-', '*', '•')))
            if (bullet_lines / len(lines)) > 0.4:
                structural_score += 5

        # Lesson/Unit/Chapter headers at the start of a chunk
        if re.search(r'^(Unit|Chapter|Lesson|Module|وحدة|فصل|درس|مفهوم)\s*(\d+|(\(\d+))', text.strip(), re.IGNORECASE):
            structural_score += 5

        # Learning Objectives Patterns (Metadata about learning, not the content itself)
        # AR: "يشرح التلميذ", "يستخدم التلميذ", "يضرب التلميذ", "الأهداف"
        objective_markers = [r'يشرح التلميذ', r'يستخدم التلميذ', r'يضرب التلميذ', r'يتعلم التلميذ', r'الأهداف']
        for marker in objective_markers:
            if re.search(marker, text):
                structural_score += 4 # High penalty for "Learning Objective" language

        # OCR Table Headers with no content (Common failure)
        # If a chunk has column headers but no actual data/numbers
        column_headers = ['الوحدات', 'الكسور العشرية', 'جزء من', 'أحاد', 'عشرات']
        header_matches = sum(1 for h in column_headers if h in text)
        if header_matches >= 2 and len(re.findall(r'\d+', text)) < 5:
            structural_score += 7

        # Page numbers/markers (e.g., "Page 56" or just "56" at start/end)
        if re.search(r'^\s*(Page|صفحة)?\s*\d+\s*$', text.strip(), re.IGNORECASE):
            structural_score += 10

        # --- 2. SUBSTANTIVE INDICATORS (Instructional Content) ---
        
        # Action Verbs (Arabic & English) - ALL SUBJECTS
        # Math: أوجد, احسب, حل | Science: صف, فسر, لاحظ | Arabic: أعرب, استخرج, اقرأ | English: Read, Write, Listen
        action_patterns = [
            r'(أوجد|احسب|حل|اختر|أكمل|سؤال|تمرين|قارن|حدد|استنتج|اكتب الناتج)',
            r'(صف|فسر|علل|رتب|صنف|لاحظ|ارسم|اقرأ|استمع|عبر)',
            r'(اذكر|وضح|ميز|حوط|صل|أعرب|استخرج|هات)',
            r'(Find|Solve|Calculate|Choose|Select|Complete|Compare|Question|Exercise|Determine)',
            r'(Describe|Explain|Draw|Read|Write|Listen|Match|Circle|Fill|Label|Identify)',
        ]
        
        for pattern in action_patterns:
            matches = len(re.findall(pattern, text, re.IGNORECASE))
            substantive_score += matches * 3 # Increased weight for action verbs

        # Mathematical & Scientific Symbols
        # High density of symbols = likely a real math/science problem
        math_symbols = len(re.findall(r'[+×÷=<>≤≥±√∫$]', text))
        if math_symbols > 1:
            substantive_score += min(math_symbols, 10)

        # LaTeX/Math patterns (e.g., \frac, \times)
        if re.search(r'(\\\w+|\$)', text):
            substantive_score += 5

        # Final Classification
        content_type = "substantive" if substantive_score >= structural_score else "structural"
        
        return {
            "substantive_score": substantive_score,
            "structural_score": structural_score,
            "content_type": content_type,
            "word_count": len(text.split())
        }
