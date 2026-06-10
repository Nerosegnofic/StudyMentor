import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/auth_repository.dart';
import 'reports_event.dart';
import 'reports_state.dart';

class ReportsBloc extends Bloc<ReportsEvent, ReportsState> {
  final AuthRepository repository;

  ReportsBloc({required this.repository}) : super(const ReportsState()) {
    on<LoadWeeklyReportRequested>(_onLoadWeeklyReport);
    on<LoadSubjectMasteryRequested>(_onLoadSubjectMastery);
    on<LoadStudyHabitsRequested>(_onLoadStudyHabits);
  }

  Future<void> _onLoadWeeklyReport(
    LoadWeeklyReportRequested event,
    Emitter<ReportsState> emit,
  ) async {
    emit(state.copyWith(isWeeklyLoading: true, weeklyError: null));
    try {
      final report = await repository.getWeeklyReport(event.studentUid);
      emit(state.copyWith(
        isWeeklyLoading: false,
        weeklyReport: report,
      ));
    } catch (e) {
      emit(state.copyWith(
        isWeeklyLoading: false,
        weeklyError: 'Failed to load weekly report: $e',
      ));
    }
  }

  Future<void> _onLoadSubjectMastery(
    LoadSubjectMasteryRequested event,
    Emitter<ReportsState> emit,
  ) async {
    emit(state.copyWith(isMasteryLoading: true, masteryError: null));
    try {
      final report = await repository.getSubjectMasteryReport(
        event.studentUid,
        event.subjectKey,
      );
      emit(state.copyWith(
        isMasteryLoading: false,
        masteryReport: report,
      ));
    } catch (e) {
      emit(state.copyWith(
        isMasteryLoading: false,
        masteryError: 'Failed to load subject mastery: $e',
      ));
    }
  }

  Future<void> _onLoadStudyHabits(
    LoadStudyHabitsRequested event,
    Emitter<ReportsState> emit,
  ) async {
    emit(state.copyWith(isHabitsLoading: true, habitsError: null));
    try {
      final report = await repository.getStudyHabitsReport(event.studentUid);
      emit(state.copyWith(
        isHabitsLoading: false,
        habitsReport: report,
      ));
    } catch (e) {
      emit(state.copyWith(
        isHabitsLoading: false,
        habitsError: 'Failed to load study habits: $e',
      ));
    }
  }
}
