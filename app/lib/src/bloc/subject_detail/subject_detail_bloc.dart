import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/models/question_detail_model.dart';
import '../../domain/models/skill_progress_model.dart';
import '../../domain/models/subject_summary_model.dart';
import '../../domain/models/quiz_attempt_model.dart';
import 'subject_detail_event.dart';
import 'subject_detail_state.dart';

class SubjectDetailBloc extends Bloc<SubjectDetailEvent, SubjectDetailState> {
  final AuthRepository authRepository;

  SubjectDetailBloc({required this.authRepository}) : super(SubjectDetailInitial()) {
    on<LoadSubjectDetailRequested>(_onLoadSubjectDetailRequested);
    on<FetchSessionQuestionsRequested>(_onFetchSessionQuestionsRequested);
  }

  Future<void> _onLoadSubjectDetailRequested(
    LoadSubjectDetailRequested event,
    Emitter<SubjectDetailState> emit,
  ) async {
    emit(SubjectDetailLoading());
    try {
      // Run all 3 fetches in parallel to reduce total load time
      final results = await Future.wait<dynamic>([
        authRepository.getSubjectOverview(event.studentUid, event.subjectId, event.subjectKey),
        authRepository.getSkillsForSubject(event.studentUid, event.subjectId, event.subjectKey),
        authRepository.getAllQuizzes(event.studentUid, event.subjectId, event.subjectKey),
      ]);

      emit(SubjectDetailLoaded(
        studentUid: event.studentUid,
        summary: results[0] as SubjectSummaryModel,
        skills: results[1] as List<SkillProgressModel>,
        recentQuizzes: results[2] as List<QuizAttemptModel>,
      ));
    } catch (e) {
      emit(SubjectDetailError('Failed to load subject details: $e'));
    }
  }

  Future<void> _onFetchSessionQuestionsRequested(
    FetchSessionQuestionsRequested event,
    Emitter<SubjectDetailState> emit,
  ) async {
    final currentState = state;
    if (currentState is SubjectDetailLoaded) {
      try {
        final questions = await authRepository.getSessionQuestions(
            event.quizAttemptId,
            studentUid: currentState.studentUid);
        final updatedDetails =
            Map<String, QuestionDetailModel>.from(currentState.questionDetails);
        for (final q in questions) {
          updatedDetails['${event.quizAttemptId}_${q.questionNumber}'] = q;
        }
        emit(currentState.copyWith(questionDetails: updatedDetails));
      } catch (e) {
        // silently ignore
      }
    }
  }
}
