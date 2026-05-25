import '../../data/repositories/ai_engine_repository.dart';

abstract class QuizEvent {}

/// Dispatched when the student requests a new quiz.
/// [subjectId] is optional; omitting it lets the backend auto-select
/// the highest-priority subject based on BKT mastery data.
class GenerateQuizEvent extends QuizEvent {
  final int? subjectId;
  final int totalQuestions;
  final int studentGrade;

  GenerateQuizEvent({
    this.subjectId,
    required this.totalQuestions,
    this.studentGrade = 5,
  });
}

/// Dispatched each time the student selects an answer option.
/// The BLoC accumulates answers in state so the submission call
/// can batch them all at once.
class AnswerQuestionEvent extends QuizEvent {
  final StudentAnswer answer;

  AnswerQuestionEvent(this.answer);
}

/// Dispatched when the student taps "Submit Quiz".
class SubmitQuizEvent extends QuizEvent {
  /// The session ID returned by /quizzes/generate — must be sent back
  /// to /quizzes/submit so the server can look up the correct answers.
  final String quizSessionId;

  SubmitQuizEvent(this.quizSessionId);
}

/// Dispatched to reset the BLoC back to [QuizInitial], e.g. after
/// viewing results or navigating away from the quiz screen.
class ResetQuizEvent extends QuizEvent {}
