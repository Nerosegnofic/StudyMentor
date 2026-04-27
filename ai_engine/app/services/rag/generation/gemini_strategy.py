from langchain_google_genai import ChatGoogleGenerativeAI
from app.models.schemas import GenerateQuizResponse
from app.core.prompts import QUIZ_GENERATION_PROMPT
from app.core.config import settings
from app.services.rag.generation.base import QuizGeneratorStrategy

class GeminiStrategy(QuizGeneratorStrategy):
    """
    Implementation of Quiz Generation using Google Gemini (Free API Tier).
    Requires 'langchain-google-genai' to be installed.
    """
    def generate(self, topic_instructions: str, total_count: int, context: str) -> GenerateQuizResponse:
        llm = ChatGoogleGenerativeAI(
            google_api_key=settings.GEMINI_API_KEY,
            model="gemini-2.5-flash",
            temperature=0.2
        )
        
        structured_llm = llm.with_structured_output(GenerateQuizResponse)
        chain = QUIZ_GENERATION_PROMPT | structured_llm
        
        response = chain.invoke({
            "topic_instructions": topic_instructions,
            "total_count": total_count,
            "context": context
        })
        
        return response
