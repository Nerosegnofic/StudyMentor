import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/ai_engine_repository.dart';
import '../../domain/models/gamification_enums.dart';
import 'quiz_event.dart';
import 'quiz_state.dart';

/// Stable sentinel emitted when quiz generation is rejected because the subject's
/// curriculum is still being prepared (409). Mapped to a localized string by
/// `localizeError` (`quizSubjectStillPreparing`).
const String kQuizSubjectStillPreparingError =
    'This subject is still being prepared. Please try again in a moment.';

class QuizBloc extends Bloc<QuizEvent, QuizState> {
  final AiEngineRepository repository;

  QuizBloc({required this.repository}) : super(QuizInitial()) {
    on<GenerateQuizEvent>(_onGenerate);
    on<AnswerQuestionEvent>(_onAnswer);
    on<SubmitQuizEvent>(_onSubmit);
    on<ResetQuizEvent>(_onReset);
    on<RestoreQuizSessionEvent>(_onRestore);
  }

  // ---------------------------------------------------------------------------
  // Handlers
  // ---------------------------------------------------------------------------

  Future<void> _onGenerate(
    GenerateQuizEvent event,
    Emitter<QuizState> emit,
  ) async {
    emit(QuizLoading());
    final request = GenerateQuizRequest(
      subjectId: event.subjectId,
      totalQuestions: event.totalQuestions,
      studentGrade: event.studentGrade,
      quizContext:
          event.quizContext == QuizContext.forced ? 'FORCED' : 'VOLUNTARY',
    );
    try {
      // Transparently fast when a pre-warmed session exists (quiz_source="CACHED").
      final response = await repository.generateQuiz(request);
      emit(QuizLoaded(quizResponse: response));
    } on SubjectStillProcessingException {
      emit(QuizError(kQuizSubjectStillPreparingError));
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
          totalElapsedMs: event.totalElapsedMs,
        ),
      );
      emit(QuizResultsLoaded(
        result: response,
        quizResponse: current.quizResponse,
        answers: current.currentAnswers,
      ));

      // Pre-warm a cached quiz for EVERY active subject so the next start is
      // instant for any subject (this refills the just-consumed one too). The engine
      // is idempotent, so already-warm subjects are skipped. Fire-and-forget — never
      // blocks or surfaces an error.
      unawaited(repository.warmAllQuizzes());
    } catch (e) {
      emit(QuizError(e.toString()));
    }
  }

  void _onReset(ResetQuizEvent event, Emitter<QuizState> emit) {
    emit(QuizInitial());
  }

  void _onRestore(RestoreQuizSessionEvent event, Emitter<QuizState> emit) {
    emit(QuizLoaded(
      quizResponse: event.quizResponse,
      currentAnswers: event.answers,
    ));
  }
}
