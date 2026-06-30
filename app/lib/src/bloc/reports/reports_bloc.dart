import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/auth_repository.dart';
import 'reports_event.dart';
import 'reports_state.dart';

class ReportsBloc extends Bloc<ReportsEvent, ReportsState> {
  final AuthRepository repository;

  ReportsBloc({required this.repository}) : super(const ReportsState()) {
    on<LoadWeeklyReportRequested>(_onLoadWeeklyReport);
    on<LoadReportSubjectsRequested>(_onLoadReportSubjects);
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

  Future<void> _onLoadReportSubjects(
    LoadReportSubjectsRequested event,
    Emitter<ReportsState> emit,
  ) async {
    emit(state.copyWith(isMasteryLoading: true, masteryError: null));
    try {
      final subjects = await repository.getReportSubjects(event.studentUid);
      if (subjects.isEmpty) {
        emit(state.copyWith(
          subjects: subjects,
          isMasteryLoading: false,
          masteryReport: null,
        ));
        return;
      }
      final first = subjects.first;
      final report = await repository.getSubjectMasteryReport(
        event.studentUid,
        first.id,
        // Reuse the mastery already fetched for the chip — avoids a second
        // all-subjects analytics request inside getSubjectMasteryReport.
        knownTotalMasteryPercent: first.masteryPercent,
      );
      emit(state.copyWith(
        subjects: subjects,
        selectedSubjectId: first.id,
        isMasteryLoading: false,
        masteryReport: report,
      ));
    } catch (e) {
      emit(state.copyWith(
        isMasteryLoading: false,
        masteryError: 'Failed to load subjects: $e',
      ));
    }
  }

  Future<void> _onLoadSubjectMastery(
    LoadSubjectMasteryRequested event,
    Emitter<ReportsState> emit,
  ) async {
    emit(state.copyWith(
      isMasteryLoading: true,
      masteryError: null,
      selectedSubjectId: event.subjectId,
    ));
    try {
      // Reuse the already-loaded chip mastery so getSubjectMasteryReport can
      // skip the redundant all-subjects analytics fetch.
      double? knownMastery;
      for (final s in state.subjects) {
        if (s.id == event.subjectId) {
          knownMastery = s.masteryPercent;
          break;
        }
      }
      final report = await repository.getSubjectMasteryReport(
        event.studentUid,
        event.subjectId,
        knownTotalMasteryPercent: knownMastery,
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
