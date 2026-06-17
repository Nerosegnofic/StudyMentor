import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/ai_engine_repository.dart';
import '../../domain/models/gamification_enums.dart';
import 'quiz_event.dart';
import 'quiz_state.dart';

class QuizBloc extends Bloc<QuizEvent, QuizState> {
  final AiEngineRepository repository;

  /// The request used for the current quiz, replayed after submit to pre-warm
  /// the next one (same subject / count / grade / context).
  GenerateQuizRequest? _lastRequest;

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
    final request = GenerateQuizRequest(
      subjectId: event.subjectId,
      totalQuestions: event.totalQuestions,
      studentGrade: event.studentGrade,
      quizContext:
          event.quizContext == QuizContext.forced ? 'FORCED' : 'VOLUNTARY',
    );
    _lastRequest = request;
    try {
      // Transparently fast when a pre-warmed session exists (quiz_source="CACHED").
      final response = await repository.generateQuiz(request);
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

      // Pre-warm the next quiz for the same subject/params so the next start is
      // instant. Fire-and-forget — the engine creates an unsubmitted session that
      // a later /generate returns as CACHED. Never blocks or surfaces an error.
      final lastRequest = _lastRequest;
      if (lastRequest != null) {
        unawaited(repository.prewarmNextQuiz(lastRequest));
      }
    } catch (e) {
      emit(QuizError(e.toString()));
    }
  }

  void _onReset(ResetQuizEvent event, Emitter<QuizState> emit) {
    emit(QuizInitial());
  }
}
