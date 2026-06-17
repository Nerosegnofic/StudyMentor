import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/ai_engine_repository.dart';
import 'quiz_event.dart';
import 'quiz_state.dart';

class QuizBloc extends Bloc<QuizEvent, QuizState> {
  final AiEngineRepository repository;

  QuizBloc({required this.repository}) : super(QuizInitial()) {
    on<GenerateQuizEvent>(_onGenerate);
    on<AnswerQuestionEvent>(_onAnswer);
    on<SubmitQuizEvent>(_onSubmit);
    on<ResetQuizEvent>(_onReset);
  }

  // ---------------------------------------------------------------------------
  // Handlers
  // ---------------------------------------------------------------------------

  Future<void> _onGenerate(
    GenerateQuizEvent event,
    Emitter<QuizState> emit,
  ) async {
    emit(QuizLoading());
    try {
      final response = await repository.generateQuiz(
        GenerateQuizRequest(
          subjectId: event.subjectId,
          totalQuestions: event.totalQuestions,
          autoLength: event.autoLength,
          studentGrade: event.studentGrade,
        ),
      );
      emit(QuizLoaded(quizResponse: response));
    } catch (e) {
      emit(QuizError(e.toString()));
    }
  }

  void _onAnswer(AnswerQuestionEvent event, Emitter<QuizState> emit) {
    if (state is! QuizLoaded) return;
    final current = state as QuizLoaded;
    final updated = Map<String, StudentAnswer>.from(current.currentAnswers);
    updated[event.answer.questionId] = event.answer;
    emit(current.copyWith(currentAnswers: updated));
  }

  Future<void> _onSubmit(
    SubmitQuizEvent event,
    Emitter<QuizState> emit,
  ) async {
    if (state is! QuizLoaded) return;
    final current = state as QuizLoaded;
    emit(QuizSubmitting());
    try {
      final response = await repository.submitQuiz(
        QuizSubmissionRequest(
          quizSessionId: event.quizSessionId,
          answers: current.currentAnswers.values.toList(),
          clientLocalDate: DateTime.now().toIso8601String().split('T')[0],
        ),
      );
      emit(QuizResultsLoaded(
        result: response,
        quizResponse: current.quizResponse,
        answers: current.currentAnswers,
      ));
    } catch (e) {
      emit(QuizError(e.toString()));
    }
  }

  void _onReset(ResetQuizEvent event, Emitter<QuizState> emit) {
    emit(QuizInitial());
  }
}
