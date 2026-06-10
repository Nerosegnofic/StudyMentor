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

class LoadSubjectMasteryRequested extends ReportsEvent {
  final String studentUid;
  final String subjectKey;

  const LoadSubjectMasteryRequested({required this.studentUid, required this.subjectKey});

  @override
  List<Object?> get props => [studentUid, subjectKey];
}

class LoadStudyHabitsRequested extends ReportsEvent {
  final String studentUid;

  const LoadStudyHabitsRequested({required this.studentUid});

  @override
  List<Object?> get props => [studentUid];
}
