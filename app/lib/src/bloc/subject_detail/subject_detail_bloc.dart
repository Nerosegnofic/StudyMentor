import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/models/question_detail_model.dart';
import 'subject_detail_event.dart';
import 'subject_detail_state.dart';

class SubjectDetailBloc extends Bloc<SubjectDetailEvent, SubjectDetailState> {
  final AuthRepository authRepository;

  SubjectDetailBloc({required this.authRepository}) : super(SubjectDetailInitial()) {
    on<LoadSubjectDetailRequested>(_onLoadSubjectDetailRequested);
    on<FetchQuestionDetailRequested>(_onFetchQuestionDetailRequested);
  }

  Future<void> _onLoadSubjectDetailRequested(
    LoadSubjectDetailRequested event,
    Emitter<SubjectDetailState> emit,
  ) async {
    emit(SubjectDetailLoading());
    try {
      final summary = await authRepository.getSubjectOverview(event.studentUid, event.subjectKey);
      final skills = await authRepository.getSkillsForSubject(event.studentUid, event.subjectKey);
      final recentQuizzes = await authRepository.getRecentQuizzes(event.studentUid, event.subjectKey);

      emit(SubjectDetailLoaded(
        summary: summary,
        skills: skills,
        recentQuizzes: recentQuizzes,
      ));
    } catch (e) {
      emit(SubjectDetailError('Failed to load subject details: $e'));
    }
  }

  Future<void> _onFetchQuestionDetailRequested(
    FetchQuestionDetailRequested event,
    Emitter<SubjectDetailState> emit,
  ) async {
    final currentState = state;
    if (currentState is SubjectDetailLoaded) {
      try {
        final detail = await authRepository.getQuestionDetail(event.quizAttemptId, event.questionNumber);
        
        final updatedDetails = Map<String, QuestionDetailModel>.from(currentState.questionDetails);
        final key = '${event.quizAttemptId}_${event.questionNumber}';
        updatedDetails[key] = detail;
        
        emit(currentState.copyWith(questionDetails: updatedDetails));
      } catch (e) {
        // Silently ignore or emit an error state depending on requirements
      }
    }
  }
}
