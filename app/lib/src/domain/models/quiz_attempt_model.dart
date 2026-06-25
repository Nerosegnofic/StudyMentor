// lib/src/domain/models/quiz_attempt_model.dart

class QuizAttemptModel {
  final String id;
  final String studentUid;
  final String subjectKey;
  final String skillTag;
  final DateTime attemptedAt;
  final int correctAnswers;
  final int totalQuestions;
  final Duration duration;
  final bool passed;
  final List<int> correctAnswerNumbers;

  const QuizAttemptModel({
    required this.id,
    required this.studentUid,
    required this.subjectKey,
    required this.skillTag,
    required this.attemptedAt,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.duration,
    required this.passed,
    required this.correctAnswerNumbers,
  });

  factory QuizAttemptModel.fromJson(Map<String, dynamic> json) {
    return QuizAttemptModel(
      id: json['id'] as String,
      studentUid: json['student_uid'] as String,
      subjectKey: json['subject_key'] as String,
      skillTag: json['skill_tag'] as String,
      attemptedAt: DateTime.parse(json['attempted_at'] as String),
      correctAnswers: json['correct_answers'] as int? ?? 0,
      totalQuestions: json['total_questions'] as int? ?? 0,
      duration: Duration(seconds: json['duration_seconds'] as int? ?? 0),
      passed: json['passed'] as bool? ?? false,
      correctAnswerNumbers: (json['correct_answer_numbers'] as List<dynamic>?)?.map((e) => e as int).toList() ?? [],
    );
  }

}
