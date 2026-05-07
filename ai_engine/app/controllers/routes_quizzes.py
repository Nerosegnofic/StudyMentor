from datetime import datetime
from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
from app.models.schemas import (
    GenerateQuizRequest, 
    GenerateQuizResponse,
    QuizSubmissionRequest,
    QuizSubmissionResponse
)
from app.services.rag.retrieval import retrieve_context_for_topics
from app.services.rag.generation.context import GeneratorContext
from app.services.rag.generation.gemini_strategy import GeminiStrategy
from app.core.database import get_db
from app.core.auth import get_current_user
from app.repositories import (
    get_all_student_skill_states,
    get_student_bkt_profile,
    get_student_skill_state
)
from app.services.quiz.builder import build_quiz_payload
from app.services.evaluation.bkt_engine import BKTEngine
from app.models.domain import QuizSession, Question, Skill, QuestionResponse

DIFFICULTY_LABELS = {1: "Very Easy", 2: "Easy", 3: "Medium", 4: "Hard", 5: "Very Hard"}

router = APIRouter(prefix="/quizzes", tags=["Quizzes"])

generator_context = GeneratorContext(strategy=GeminiStrategy())
bkt_engine = BKTEngine()

@router.post("/generate", response_model=GenerateQuizResponse)
async def generate_quiz(
    request: GenerateQuizRequest,
    db: Session = Depends(get_db),
    student_uid: str = Depends(get_current_user)
):
    try:
        # Step 1: Get the student's BKT mastery profile
        # Filter by subject if needed, but for now we get all and let build_quiz_payload handle it.
        # However, to be more precise, we should only consider skills for this subject.
        student_profile = get_all_student_skill_states(db, student_uid)
        
        # If the student has no profile yet, build a default one across all skills of THIS subject
        if not student_profile:
            all_skills = db.query(Skill).filter(Skill.subject_id == request.subject_id).all()
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
        context = retrieve_context_for_topics(all_topics, k=10)
        
        # Step 4: LangChain structured generation
        response = generator_context.execute_generation(
            topic_instructions=topic_instructions,
            total_count=request.total_questions,
            context=context
        )
        
        # Step 5: Save the generated quiz to the database securely
        quiz_session = QuizSession(
            student_uid=student_uid,
            subject_id=request.subject_id,
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

@router.post("/submit", response_model=QuizSubmissionResponse)
async def submit_quiz(
    request: QuizSubmissionRequest, 
    db: Session = Depends(get_db),
    student_uid: str = Depends(get_current_user)
):
    try:
        total_questions = len(request.answers)
        if total_questions == 0:
            raise HTTPException(status_code=400, detail="Answers list cannot be empty.")
            
        bkt_profile = get_student_bkt_profile(db, student_uid)
        triggered_punishment = False
        correct_answers = 0
        
        # We also want to update the QuizSession score
        quiz_session = db.query(QuizSession).filter(QuizSession.session_id == request.quiz_session_id).first()
        
        for ans in request.answers:
            # Secure Server-Side Grading
            db_question = db.query(Question).filter(Question.question_id == ans.question_id).first()
            if not db_question:
                continue # Skip invalid questions
                
            is_correct = (ans.selected_option == db_question.correct_answer)
            if is_correct:
                correct_answers += 1
                
            # Save the student's response securely
            db_response = QuestionResponse(
                question_id=db_question.question_id,
                student_uid=student_uid,
                selected_option=ans.selected_option,
                is_correct=is_correct,
                time_taken_ms=ans.time_taken_ms,
                hints_used=ans.hints_used
            )
            db.add(db_response)

            # Mark question as submitted
            db_question.submitted_at = datetime.utcnow()
            
            # Lookup skill and update BKT
            difficulty = db_question.difficulty
            skill_name = db_question.skill.name if db_question.skill else "General Math"
            skill_state = get_student_skill_state(db, student_uid, skill_name)
            
            punished = bkt_engine.update_mastery(
                profile=bkt_profile,
                skill_state=skill_state,
                skill_name=skill_name,
                difficulty=difficulty,
                correct=is_correct,
                response_time=ans.time_taken_ms / 1000.0,
                hints_used=ans.hints_used
            )
            if punished:
                triggered_punishment = True
                
        score = (correct_answers / total_questions) * 100
        if quiz_session:
            quiz_session.score = score
            
        db.commit()
        
        if score >= 85:
            feedback = "ممتاز! لقد أبليت بلاءً حسناً."
        elif score >= 50:
            feedback = "جيد، ولكن يمكنك التحسن بمزيد من الممارسة."
        else:
            feedback = "لا تقلق، استمر في المحاولة وسوف تنجح."
                
        if triggered_punishment:
            feedback += " 🛑 تبدو أنك كنت تجيب بسرعة كبيرة جداً. يرجى أخذ الوقت الكافي للتفكير في المرة القادمة!"
        
        return QuizSubmissionResponse(
            score=score,
            total_questions=total_questions,
            feedback=feedback
        )
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))

