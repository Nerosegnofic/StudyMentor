import '../../data/repositories/ai_engine_repository.dart';
import '../../domain/models/gamification_enums.dart';

abstract class QuizEvent {}

/// Dispatched when the student requests a new quiz.
/// [subjectId] is optional; omitting it lets the backend auto-select
/// the highest-priority subject based on BKT mastery data.
class GenerateQuizEvent extends QuizEvent {
  final int? subjectId;
  final int totalQuestions;

  /// When true, the backend computes the quiz length adaptively (parent's "Auto" choice).
  final bool autoLength;
  final int studentGrade;

  /// Whether this quiz was launched voluntarily or forced (mascot/focus-limit).
  /// Threaded to the backend so forced quizzes earn their reward bonus, and reused
  /// when pre-warming the next quiz.
  final QuizContext quizContext;

  GenerateQuizEvent({
    this.subjectId,
    required this.totalQuestions,
    this.autoLength = false,
    this.studentGrade = 5,
    this.quizContext = QuizContext.voluntary,
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

  /// Foreground-only solve time from the client stopwatch (ms). Pauses
  /// when the app is backgrounded so background idle is excluded from the
  /// study-time statistic.
  final int totalElapsedMs;

  SubmitQuizEvent(this.quizSessionId, {required this.totalElapsedMs});
}

/// Dispatched to reset the BLoC back to [QuizInitial], e.g. after
/// viewing results or navigating away from the quiz screen.
class ResetQuizEvent extends QuizEvent {}

/// Dispatched when restoring a previously interrupted quiz session from
/// persistent storage. Bypasses generation and immediately puts the BLoC
/// into [QuizLoaded] with the saved quiz data and submitted answers.
class RestoreQuizSessionEvent extends QuizEvent {
  final GenerateQuizResponse quizResponse;
  final Map<String, StudentAnswer> answers;

  RestoreQuizSessionEvent({
    required this.quizResponse,
    required this.answers,
  });
}
