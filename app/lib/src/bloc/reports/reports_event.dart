import 'package:equatable/equatable.dart';

abstract class ReportsEvent extends Equatable {
  const ReportsEvent();

  @override
  List<Object?> get props => [];
}

class LoadWeeklyReportRequested extends ReportsEvent {
  final String studentUid;

  const LoadWeeklyReportRequested({required this.studentUid});

  @override
  List<Object?> get props => [studentUid];
}

/// Loads the subject chip list, then auto-loads the first subject's mastery.
class LoadReportSubjectsRequested extends ReportsEvent {
  final String studentUid;

  const LoadReportSubjectsRequested({required this.studentUid});

  @override
  List<Object?> get props => [studentUid];
}

class LoadSubjectMasteryRequested extends ReportsEvent {
  final String studentUid;
  final int subjectId;

  const LoadSubjectMasteryRequested({required this.studentUid, required this.subjectId});

  @override
  List<Object?> get props => [studentUid, subjectId];
}

class LoadStudyHabitsRequested extends ReportsEvent {
  final String studentUid;

  const LoadStudyHabitsRequested({required this.studentUid});

  @override
  List<Object?> get props => [studentUid];
}
