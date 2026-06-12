from langchain_cohere import ChatCohere
from langchain_core.prompts import ChatPromptTemplate
from app.models.schemas import GenerateQuizResponse
from app.core.config import settings
from app.services.rag.generation.base import QuizGeneratorStrategy

class CohereStrategy(QuizGeneratorStrategy):
    """
    Implementation of Quiz Generation using Cohere.
    """
    def generate(self, quiz_prompt: ChatPromptTemplate, topic_instructions: str, total_count: int, context: str, student_grade: str = "5th", subject_name: str = "", variance_block: str = "") -> GenerateQuizResponse:
        llm = ChatCohere(
            cohere_api_key=settings.COHERE_API_KEY, 
            model=settings.COHERE_MODEL, 
            temperature=0.2
        )
        
        structured_llm = llm.with_structured_output(GenerateQuizResponse)
        chain = quiz_prompt | structured_llm
        
        response = chain.invoke({
            "topic_instructions": topic_instructions,
            "total_count": total_count,
            "context": context,
            "student_grade": student_grade,
            "subject_name": subject_name,
            "variance_block": variance_block,
        })
        
        return response
