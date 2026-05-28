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

class LoadAvailableSubjectsRequested extends SubjectEvent {}

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
