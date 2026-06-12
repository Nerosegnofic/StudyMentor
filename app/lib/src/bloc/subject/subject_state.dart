// lib/src/bloc/subject/subject_state.dart

import 'package:equatable/equatable.dart';
import '../../domain/models/subject_summary_model.dart';

abstract class SubjectState extends Equatable {
  @override
  List<Object?> get props => [];
}

class SubjectInitial extends SubjectState {}

class SubjectsLoading extends SubjectState {}

class SubjectsLoaded extends SubjectState {
  final List<SubjectSummaryModel> subjects;
  SubjectsLoaded(this.subjects);

  @override
  List<Object?> get props => [subjects];
}

class AvailableSubjectsLoaded extends SubjectState {
  final List<SubjectSummaryModel> subjects;
  AvailableSubjectsLoaded(this.subjects);

  @override
  List<Object?> get props => [subjects];
}

class SubjectAdded extends SubjectState {}

class SubjectRemoved extends SubjectState {
  final String subjectKey;
  SubjectRemoved(this.subjectKey);

  @override
  List<Object?> get props => [subjectKey];
}

class SubjectsError extends SubjectState {
  final String message;
  SubjectsError(this.message);

  @override
  List<Object?> get props => [message];
}
