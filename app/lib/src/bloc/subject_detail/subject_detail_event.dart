import 'package:equatable/equatable.dart';

abstract class SubjectDetailEvent extends Equatable {
  const SubjectDetailEvent();

  @override
  List<Object?> get props => [];
}

class LoadSubjectDetailRequested extends SubjectDetailEvent {
  final String studentUid;
  final String subjectKey;

  const LoadSubjectDetailRequested({required this.studentUid, required this.subjectKey});

  @override
  List<Object?> get props => [studentUid, subjectKey];
}

class FetchQuestionDetailRequested extends SubjectDetailEvent {
  final String quizAttemptId;
  final int questionNumber;

  const FetchQuestionDetailRequested({required this.quizAttemptId, required this.questionNumber});

  @override
  List<Object?> get props => [quizAttemptId, questionNumber];
}

class FetchSessionQuestionsRequested extends SubjectDetailEvent {
  final String quizAttemptId;

  const FetchSessionQuestionsRequested({required this.quizAttemptId});

  @override
  List<Object?> get props => [quizAttemptId];
}
