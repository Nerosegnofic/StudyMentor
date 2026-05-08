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
    get_student_skill_state,
    get_priority_subject,
    get_subject_by_id,
    get_skills_by_subject_id,
    get_skills_by_names,
    create_quiz_session,
    upsert_student_subject_profile_last_quizzed,
    save_questions,
    get_quiz_session_by_id,
    get_question_by_id,
    save_question_response
)
from app.services.quiz.builder import build_quiz_payload
from app.services.evaluation.bkt_engine import BKTEngine
from app.models.domain import Question, QuestionResponse

DIFFICULTY_LABELS = {1: "Very Easy", 2: "Easy", 3: "Medium", 4: "Hard", 5: "Very Hard"}

router = APIRouter(prefix="/quizzes", tags=["Quizzes"])

generator_context = GeneratorContext(strategy=GeminiStrategy())
bkt_engine = BKTEngine()

@router.post("/generate", response_model=GenerateQuizResponse)
async def generate_quiz(
    request: GenerateQuizRequest,
    db: Session = Depends(get_db),
    # The student_uid is "injected" here by FastAPI.
    # It calls get_current_user() first. If that function fails (e.g. bad token),
    # this whole function is skipped and the user gets a 401 Unauthorized automatically.
    student_uid: str = Depends(get_current_user)
):
    try:
        # Step 0: Determine the Subject
        if request.subject_id is None:
            # Auto-select the subject
            subject = get_priority_subject(db, student_uid)
            if not subject:
                raise HTTPException(
                    status_code=404, 
                    detail="No subjects with skills found. Please upload curriculum documents first."
                )
        else:
            # Manually selected subject
            subject = get_subject_by_id(db, request.subject_id)
            if not subject:
                raise HTTPException(status_code=404, detail=f"Subject with ID {request.subject_id} not found.")

        target_subject_id = subject.subject_id
        target_subject_name = subject.name

        # Step 1: Get the student's BKT mastery profile
        # Filter by subject if needed, but for now we get all and let build_quiz_payload handle it.
        # However, to be more precise, we should only consider skills for this subject.
        student_profile = get_all_student_skill_states(db, student_uid)
        
        # If the student has no profile yet, build a default one across all skills of THIS subject
        if not student_profile:
            all_skills = get_skills_by_subject_id(db, target_subject_id)
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
        
        # Step 3: PGVector Retrieval (scoped to this student's documents)
        context = retrieve_context_for_topics(all_topics, k=10, firebase_uid=student_uid)
        
        # Step 4: LangChain structured generation
        response = generator_context.execute_generation(
            topic_instructions=topic_instructions,
            total_count=request.total_questions,
            context=context
        )
        
        # Step 5: Save the generated quiz to the database securely
        quiz_session = create_quiz_session(db, student_uid, target_subject_id, request.total_questions)
        
        # Upsert the StudentSubjectProfile to update last_quizzed_at
        upsert_student_subject_profile_last_quizzed(db, student_uid, target_subject_id)
        
        # We also need to get skill_ids for the skills used
        skills_used = get_skills_by_names(db, all_topics)
        skill_name_to_id = {s.name: s.skill_id for s in skills_used}
        
        
        db_questions = []
        for q in response.questions:
            skill_id = skill_name_to_id.get(q.topic, 1) # Map explicitly using the returned topic
            
            db_questions.append(Question(
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
            ))
            
        save_questions(db, db_questions)
        db.commit()
        
        return GenerateQuizResponse(
            quiz_session_id=str(quiz_session.session_id),
            selected_subject_id=target_subject_id,
            selected_subject_name=target_subject_name,
            quiz_title=response.quiz_title,
            questions=response.questions
        )
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/submit", response_model=QuizSubmissionResponse)
async def submit_quiz(
    request: QuizSubmissionRequest, 
    db: Session = Depends(get_db),
    # Same as /generate, we trust this UID because it was cryptographically verified
    # by the Firebase SDK in the core/auth.py dependency.
    student_uid: str = Depends(get_current_user)
):
    try:
        total_questions = len(request.answers)
        if total_questions == 0:
            raise HTTPException(status_code=400, detail="Answers list cannot be empty.")
            
        triggered_punishment = False
        correct_answers = 0
        
        # We also want to update the QuizSession score
        quiz_session = get_quiz_session_by_id(db, request.quiz_session_id)

        # Guard: reject if session doesn't exist
        if not quiz_session:
            raise HTTPException(status_code=404, detail="Quiz session not found.")

        # Guard: reject if the quiz was already submitted
        if quiz_session.end_time is not None:
            raise HTTPException(status_code=409, detail="This quiz has already been submitted.")

        # Guard: reject if the quiz belongs to a different student
        if quiz_session.student_uid != student_uid:
            raise HTTPException(status_code=403, detail="You are not allowed to submit this quiz.")
        
        for ans in request.answers:
            # Secure Server-Side Grading
            db_question = get_question_by_id(db, ans.question_id)
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
            save_question_response(db, db_response)

            # Mark question as submitted
            db_question.submitted_at = datetime.utcnow()
            
            # Lookup skill and update BKT
            difficulty = db_question.difficulty
            skill_name = db_question.skill.name if db_question.skill else "General Math"
            skill_state = get_student_skill_state(db, student_uid, skill_name)
            
            punished, new_spam_count = bkt_engine.update_mastery(
                skill_state=skill_state,
                skill_name=skill_name,
                difficulty=difficulty,
                correct=is_correct,
                response_time=ans.time_taken_ms / 1000.0,
                hints_used=ans.hints_used,
                current_session_spam_count=quiz_session.consecutive_spam_clicks if quiz_session else 0
            )
            if quiz_session:
                quiz_session.consecutive_spam_clicks = new_spam_count
                
            if punished:
                triggered_punishment = True
                
        score = (correct_answers / total_questions) * 100
        if quiz_session:
            quiz_session.score = score
            quiz_session.end_time = datetime.utcnow() # Assigning the end timestamp upon submission
            
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