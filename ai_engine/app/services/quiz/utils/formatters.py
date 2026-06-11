import random
from app.models.schemas import QuestionSchema

def shuffle_question_options(question_schema: QuestionSchema) -> QuestionSchema:
    """
    Shuffle the options of a question in-place and keep correct_answer consistent.
    This is the definitive server-side fix for LLM positional bias (always putting
    the correct answer first).
    """
    options = list(question_schema.options)
    random.shuffle(options)
    # correct_answer is a value, not a position — it stays the same string
    return QuestionSchema(
        question_id=question_schema.question_id,
        topic=question_schema.topic,
        question_text=question_schema.question_text,
        options=options,
        correct_answer=question_schema.correct_answer,
        explanation=question_schema.explanation,
        difficulty=question_schema.difficulty,
        hints=question_schema.hints,
    )
