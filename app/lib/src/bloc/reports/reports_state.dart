import 'package:equatable/equatable.dart';
import '../../domain/models/report_models.dart';

class ReportsState extends Equatable {
  final WeeklyReportModel? weeklyReport;
  final bool isWeeklyLoading;
  final String? weeklyError;

  final List<SubjectChipModel> subjects;
  final int? selectedSubjectId;
  final SubjectMasteryReport? masteryReport;
  final bool isMasteryLoading;
  final String? masteryError;

  final StudyHabitsReport? habitsReport;
  final bool isHabitsLoading;
  final String? habitsError;

  const ReportsState({
    this.weeklyReport,
    this.isWeeklyLoading = false,
    this.weeklyError,
    this.subjects = const [],
    this.selectedSubjectId,
    this.masteryReport,
    this.isMasteryLoading = false,
    this.masteryError,
    this.habitsReport,
    this.isHabitsLoading = false,
    this.habitsError,
  });

  ReportsState copyWith({
    WeeklyReportModel? weeklyReport,
    bool? isWeeklyLoading,
    String? weeklyError,
    List<SubjectChipModel>? subjects,
    int? selectedSubjectId,
    SubjectMasteryReport? masteryReport,
    bool? isMasteryLoading,
    String? masteryError,
    StudyHabitsReport? habitsReport,
    bool? isHabitsLoading,
    String? habitsError,
  }) {
    return ReportsState(
      weeklyReport: weeklyReport ?? this.weeklyReport,
      isWeeklyLoading: isWeeklyLoading ?? this.isWeeklyLoading,
      weeklyError: weeklyError, // Override with null if not provided in some cases, but here we can just use normal copyWith
      subjects: subjects ?? this.subjects,
      selectedSubjectId: selectedSubjectId ?? this.selectedSubjectId,
      masteryReport: masteryReport ?? this.masteryReport,
      isMasteryLoading: isMasteryLoading ?? this.isMasteryLoading,
      masteryError: masteryError,
      habitsReport: habitsReport ?? this.habitsReport,
      isHabitsLoading: isHabitsLoading ?? this.isHabitsLoading,
      habitsError: habitsError,
    );
  }

  // Helper to clear errors
  ReportsState copyWithClearWeeklyError() => ReportsState(
        weeklyReport: weeklyReport,
        isWeeklyLoading: isWeeklyLoading,
        weeklyError: null,
        masteryReport: masteryReport,
        isMasteryLoading: isMasteryLoading,
        masteryError: masteryError,
        habitsReport: habitsReport,
        isHabitsLoading: isHabitsLoading,
        habitsError: habitsError,
      );

  ReportsState copyWithClearMasteryError() => ReportsState(
        weeklyReport: weeklyReport,
        isWeeklyLoading: isWeeklyLoading,
        weeklyError: weeklyError,
        masteryReport: masteryReport,
        isMasteryLoading: isMasteryLoading,
        masteryError: null,
        habitsReport: habitsReport,
        isHabitsLoading: isHabitsLoading,
        habitsError: habitsError,
      );

  ReportsState copyWithClearHabitsError() => ReportsState(
        weeklyReport: weeklyReport,
        isWeeklyLoading: isWeeklyLoading,
        weeklyError: weeklyError,
        masteryReport: masteryReport,
        isMasteryLoading: isMasteryLoading,
        masteryError: masteryError,
        habitsReport: habitsReport,
        isHabitsLoading: isHabitsLoading,
        habitsError: null,
      );

  @override
  List<Object?> get props => [
        weeklyReport,
        isWeeklyLoading,
        weeklyError,
        subjects,
        selectedSubjectId,
        masteryReport,
        isMasteryLoading,
        masteryError,
        habitsReport,
        isHabitsLoading,
        habitsError,
      ];
}

