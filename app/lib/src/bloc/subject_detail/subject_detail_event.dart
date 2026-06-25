import 'package:equatable/equatable.dart';

abstract class SubjectDetailEvent extends Equatable {
  const SubjectDetailEvent();

  @override
  List<Object?> get props => [];
}

class LoadSubjectDetailRequested extends SubjectDetailEvent {
  final String studentUid;
  final int subjectId;
  final String subjectKey;

  const LoadSubjectDetailRequested({
    required this.studentUid,
    required this.subjectId,
    required this.subjectKey,
  });

  @override
  List<Object?> get props => [studentUid, subjectId, subjectKey];
}

class FetchSessionQuestionsRequested extends SubjectDetailEvent {
  final String quizAttemptId;

  const FetchSessionQuestionsRequested({required this.quizAttemptId});

  @override
  List<Object?> get props => [quizAttemptId];
}
