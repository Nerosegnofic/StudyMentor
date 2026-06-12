import 'package:equatable/equatable.dart';
import '../../domain/models/subject_summary_model.dart';
import '../../domain/models/skill_progress_model.dart';
import '../../domain/models/quiz_attempt_model.dart';
import '../../domain/models/question_detail_model.dart';

abstract class SubjectDetailState extends Equatable {
  const SubjectDetailState();

  @override
  List<Object?> get props => [];
}

class SubjectDetailInitial extends SubjectDetailState {}

class SubjectDetailLoading extends SubjectDetailState {}

class SubjectDetailLoaded extends SubjectDetailState {
  final SubjectSummaryModel summary;
  final List<SkillProgressModel> skills;
  final List<QuizAttemptModel> recentQuizzes;
  final Map<String, QuestionDetailModel> questionDetails;

  const SubjectDetailLoaded({
    required this.summary,
    required this.skills,
    required this.recentQuizzes,
    this.questionDetails = const {},
  });

  SubjectDetailLoaded copyWith({
    SubjectSummaryModel? summary,
    List<SkillProgressModel>? skills,
    List<QuizAttemptModel>? recentQuizzes,
    Map<String, QuestionDetailModel>? questionDetails,
  }) {
    return SubjectDetailLoaded(
      summary: summary ?? this.summary,
      skills: skills ?? this.skills,
      recentQuizzes: recentQuizzes ?? this.recentQuizzes,
      questionDetails: questionDetails ?? this.questionDetails,
    );
  }

  @override
  List<Object?> get props => [summary, skills, recentQuizzes, questionDetails];
}

class SubjectDetailError extends SubjectDetailState {
  final String message;

  const SubjectDetailError(this.message);

  @override
  List<Object?> get props => [message];
}
