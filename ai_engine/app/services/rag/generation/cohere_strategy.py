from langchain_cohere import ChatCohere
from app.models.schemas import GenerateQuizResponse
from app.core.prompts import QUIZ_GENERATION_PROMPT
from app.core.config import settings
from app.services.rag.generation.base import QuizGeneratorStrategy

class CohereStrategy(QuizGeneratorStrategy):
    """
    Implementation of Quiz Generation using Cohere.
    """
    def generate(self, topic_instructions: str, total_count: int, context: str) -> GenerateQuizResponse:
        llm = ChatCohere(
            cohere_api_key=settings.COHERE_API_KEY, 
            model="command-r-08-2024", 
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
