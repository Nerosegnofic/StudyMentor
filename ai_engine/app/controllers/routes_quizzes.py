from fastapi import APIRouter, HTTPException
from app.models.schemas import GenerateQuizRequest, GenerateQuizResponse
from app.services.rag.retrieval import retrieve_context_for_topics
from app.services.rag.generation.context import GeneratorContext
from app.services.rag.generation.gemini_strategy import GeminiStrategy
from app.services.rag.generation.cohere_strategy import CohereStrategy

DIFFICULTY_LABELS = {1: "Very Easy", 2: "Easy", 3: "Medium", 4: "Hard", 5: "Very Hard"}

router = APIRouter(prefix="/quizzes", tags=["Quizzes"])

# Instantiate the Context with the Gemini Strategy (Free Tier)
generator_context = GeneratorContext(strategy=GeminiStrategy())

@router.post("/generate", response_model=GenerateQuizResponse)
async def generate_quiz(request: GenerateQuizRequest):
    """
    Generates an adaptive quiz in Egyptian Arabic based on per-topic specifications.
    
    Each topic config specifies the topic name, target difficulty, and question count.
    The LLM is instructed to follow these specifications exactly.
    """
    try:
        # Build per-topic instruction lines for the LLM prompt
        instruction_lines = []
        all_topics = []
        total_count = 0
        
        for cfg in request.topic_configs:
            label = DIFFICULTY_LABELS.get(cfg.difficulty, "Medium")
            instruction_lines.append(
                f"- Topic: {cfg.topic} | Difficulty: {cfg.difficulty} ({label}) | Questions: {cfg.question_count}"
            )
            all_topics.append(cfg.topic)
            total_count += cfg.question_count
        
        topic_instructions = "\n".join(instruction_lines)
        
        # Step 1: PGVector Retrieval
        context = retrieve_context_for_topics(all_topics, k=5)
        print(context)
        
        # Step 2: LangChain structured generation using Strategy Pattern
        response = generator_context.execute_generation(
            topic_instructions=topic_instructions,
            total_count=total_count,
            context=context
        )
        
        return response
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
