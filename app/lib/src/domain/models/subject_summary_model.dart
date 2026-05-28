// lib/src/domain/models/subject_summary_model.dart

class SubjectSummaryModel {
  final String subjectKey;
  final String colorHex;
  final int skillsCount;
  final int masteryPercent;
  final int quizzesCompleted;
  final Duration totalTimeSpent;
  final double accuracyPercent;

  const SubjectSummaryModel({
    required this.subjectKey,
    required this.colorHex,
    required this.skillsCount,
    required this.masteryPercent,
    required this.quizzesCompleted,
    required this.totalTimeSpent,
    required this.accuracyPercent,
  });

  factory SubjectSummaryModel.fromJson(Map<String, dynamic> json) {
    return SubjectSummaryModel(
      subjectKey: json['subject_key'] as String,
      colorHex: json['color_hex'] as String? ?? '#2196F3',
      skillsCount: json['skills_count'] as int? ?? 0,
      masteryPercent: json['mastery_percent'] as int? ?? 0,
      quizzesCompleted: json['quizzes_completed'] as int? ?? 0,
      totalTimeSpent: Duration(seconds: json['total_time_spent_seconds'] as int? ?? 0),
      accuracyPercent: (json['accuracy_percent'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subject_key': subjectKey,
      'color_hex': colorHex,
      'skills_count': skillsCount,
      'mastery_percent': masteryPercent,
      'quizzes_completed': quizzesCompleted,
      'total_time_spent_seconds': totalTimeSpent.inSeconds,
      'accuracy_percent': accuracyPercent,
    };
  }
}
