import 'package:equatable/equatable.dart';
import '../../data/repositories/ai_engine_repository.dart';

abstract class QuizState extends Equatable {
  @override
  List<Object?> get props => [];
}

class QuizInitial extends QuizState {}

class QuizLoading extends QuizState {}

class QuizLoaded extends QuizState {
  final GenerateQuizResponse quizResponse;

  /// Tracks student answers keyed by question_id, built up locally before submission.
  final Map<String, StudentAnswer> currentAnswers;

  QuizLoaded({required this.quizResponse, this.currentAnswers = const {}});

  QuizLoaded copyWith({Map<String, StudentAnswer>? currentAnswers}) {
    return QuizLoaded(
      quizResponse: quizResponse,
      currentAnswers: currentAnswers ?? this.currentAnswers,
    );
  }

  @override
  List<Object?> get props => [quizResponse, currentAnswers];
}

class QuizSubmitting extends QuizState {}

class QuizResultsLoaded extends QuizState {
  final QuizSubmissionResponse result;

  QuizResultsLoaded({required this.result});

  @override
  List<Object?> get props => [result];
}

class QuizError extends QuizState {
  final String message;

  QuizError(this.message);

  @override
  List<Object?> get props => [message];
}
