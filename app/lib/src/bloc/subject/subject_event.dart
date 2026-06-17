// lib/src/bloc/subject/subject_event.dart

import 'package:equatable/equatable.dart';

abstract class SubjectEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadSubjectsRequested extends SubjectEvent {
  final String studentUid;
  LoadSubjectsRequested({required this.studentUid});

  @override
  List<Object?> get props => [studentUid];
}

class LoadAvailableSubjectsRequested extends SubjectEvent {
  final String studentUid;
  LoadAvailableSubjectsRequested({required this.studentUid});

  @override
  List<Object?> get props => [studentUid];
}

/// Ensures private Subject rows exist for the given subject names (used after a curriculum
/// upload assigns a subject).
class AddSubjectsRequested extends SubjectEvent {
  final String studentUid;
  final List<String> selectedKeys;

  AddSubjectsRequested({
    required this.studentUid,
    required this.selectedKeys,
  });

  @override
  List<Object?> get props => [studentUid, selectedKeys];
}

/// Parent adds GLOBAL subjects from the Add-Subjects catalog by selecting (activating)
/// them for the student.
class SelectGlobalSubjectsRequested extends SubjectEvent {
  final String studentUid;
  final List<int> subjectIds;

  SelectGlobalSubjectsRequested({
    required this.studentUid,
    required this.subjectIds,
  });

  @override
  List<Object?> get props => [studentUid, subjectIds];
}

class RemoveSubjectRequested extends SubjectEvent {
  final String studentUid;
  final String subjectKey;

  RemoveSubjectRequested({
    required this.studentUid,
    required this.subjectKey,
  });

  @override
  List<Object?> get props => [studentUid, subjectKey];
}

/// Parent removes a GLOBAL subject from the student: wipes the child's progress in it and
/// returns it to the Add-Subjects catalog (the shared subject is preserved).
class RemoveGlobalSubjectRequested extends SubjectEvent {
  final String studentUid;
  final int subjectId;

  RemoveGlobalSubjectRequested({
    required this.studentUid,
    required this.subjectId,
  });

  @override
  List<Object?> get props => [studentUid, subjectId];
}

/// Parent toggles whether a subject is "focused" for the student. Deselected
/// subjects stay in the system but are hidden from the student and skipped by quizzes.
class ToggleSubjectSelectionRequested extends SubjectEvent {
  final String studentUid;
  final int subjectId;
  final bool isSelected;

  ToggleSubjectSelectionRequested({
    required this.studentUid,
    required this.subjectId,
    required this.isSelected,
  });

  @override
  List<Object?> get props => [studentUid, subjectId, isSelected];
}
