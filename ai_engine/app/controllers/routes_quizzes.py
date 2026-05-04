from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
from app.models.schemas import GenerateQuizRequest, GenerateQuizResponse
from app.services.rag.retrieval import retrieve_context_for_topics
from app.services.rag.generation.context import GeneratorContext
from app.services.rag.generation.gemini_strategy import GeminiStrategy
from app.core.database import get_db
from app.core.auth import get_current_user
from app.repositories.mastery_repo import get_all_student_skill_states
from app.services.quiz.builder import build_quiz_payload
from app.models.domain import QuizSession, Question, Skill

DIFFICULTY_LABELS = {1: "Very Easy", 2: "Easy", 3: "Medium", 4: "Hard", 5: "Very Hard"}

router = APIRouter(prefix="/quizzes", tags=["Quizzes"])

generator_context = GeneratorContext(strategy=GeminiStrategy())

@router.post("/generate", response_model=GenerateQuizResponse)
async def generate_quiz(
    request: GenerateQuizRequest,
    db: Session = Depends(get_db),
    student_uid: str = Depends(get_current_user)
):
    try:
        # Step 1: Get the student's BKT mastery profile
        student_profile = get_all_student_skill_states(db, student_uid)
        
        # If the student has no profile yet, build a default one across all skills
        if not student_profile:
            all_skills = db.query(Skill).all()
            student_profile = {skill.name: 0.01 for skill in all_skills}
            
        if not student_profile:
            # Still empty? Add a fallback dummy
            student_profile = {"General Math": 0.01}

        # Step 2: Build the payload using the allocator and priority engine
        payload = build_quiz_payload(student_profile, request.total_questions)
        
        if not payload:
            raise HTTPException(status_code=400, detail="Could not allocate questions based on profile.")

        # Build per-topic instruction lines for the LLM prompt
        instruction_lines = []
        all_topics = []
        
        for cfg in payload:
            label = DIFFICULTY_LABELS.get(cfg["difficulty"], "Medium")
            instruction_lines.append(
                f"- Topic: {cfg['skill']} | Difficulty: {cfg['difficulty']} ({label}) | Questions: {cfg['count']}"
            )
            all_topics.append(cfg["skill"])
        
        topic_instructions = "\n".join(instruction_lines)
        
        # Step 3: PGVector Retrieval
        context = retrieve_context_for_topics(all_topics, k=8)
        
        # Step 4: LangChain structured generation
        response = generator_context.execute_generation(
            topic_instructions=topic_instructions,
            total_count=request.total_questions,
            context=context
        )
        
        # Step 5: Save the generated quiz to the database securely
        quiz_session = QuizSession(
            student_uid=student_uid,
            total_questions=request.total_questions
        )
        db.add(quiz_session)
        db.flush() # flush to get session_id
        
        # We also need to get skill_ids for the skills used
        skill_name_to_id = {s.name: s.skill_id for s in db.query(Skill).filter(Skill.name.in_(all_topics)).all()}
        
        # Attach session_id to response for submission correlation
        for q in response.questions:
            skill_id = skill_name_to_id.get(q.topic, 1) # Map explicitly using the returned topic
            
            db_question = Question(
                question_id=q.question_id,
                skill_id=skill_id,
                session_id=quiz_session.session_id,
                text_content=q.question_text,
                options=q.options,
                correct_answer=q.correct_answer,
                difficulty=q.difficulty,
                source_enum="AI",
                explanation=q.explanation,
                hints=q.hints
            )
            db.add(db_question)
            
        db.commit()
        
        return response
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))

