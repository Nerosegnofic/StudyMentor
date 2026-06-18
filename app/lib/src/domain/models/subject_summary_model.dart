// lib/src/domain/models/subject_summary_model.dart

class SubjectSummaryModel {
  final String subjectKey;

  /// AI-engine subject id (needed to toggle focus selection). 0 when unknown
  /// (e.g. the static "available subjects" catalog).
  final int subjectId;
  final String colorHex;
  final int skillsCount;
  final int masteryPercent;
  final int quizzesCompleted;
  final Duration totalTimeSpent;
  final double accuracyPercent;

  /// Admin-published shared curriculum. Globals can't be deleted by parents
  /// (only deselected), so the UI uses this to gate the delete action.
  final bool isGlobal;

  /// Parent "focus" state. Deselected subjects are hidden from the student and
  /// excluded from quizzes. Defaults to true (selected) for backward compatibility.
  final bool isSelected;

  const SubjectSummaryModel({
    required this.subjectKey,
    this.subjectId = 0,
    required this.colorHex,
    required this.skillsCount,
    required this.masteryPercent,
    required this.quizzesCompleted,
    required this.totalTimeSpent,
    required this.accuracyPercent,
    this.isGlobal = false,
    this.isSelected = true,
  });

  factory SubjectSummaryModel.fromJson(Map<String, dynamic> json) {
    return SubjectSummaryModel(
      subjectKey: json['subject_key'] as String,
      subjectId: json['subject_id'] as int? ?? 0,
      colorHex: json['color_hex'] as String? ?? '#2196F3',
      skillsCount: json['skills_count'] as int? ?? 0,
      masteryPercent: json['mastery_percent'] as int? ?? 0,
      quizzesCompleted: json['quizzes_completed'] as int? ?? 0,
      totalTimeSpent: Duration(seconds: json['total_time_spent_seconds'] as int? ?? 0),
      accuracyPercent: (json['accuracy_percent'] as num?)?.toDouble() ?? 0.0,
      isGlobal: json['is_global'] as bool? ?? false,
      isSelected: json['is_selected'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subject_key': subjectKey,
      'subject_id': subjectId,
      'color_hex': colorHex,
      'skills_count': skillsCount,
      'mastery_percent': masteryPercent,
      'quizzes_completed': quizzesCompleted,
      'total_time_spent_seconds': totalTimeSpent.inSeconds,
      'accuracy_percent': accuracyPercent,
      'is_global': isGlobal,
      'is_selected': isSelected,
    };
  }
}
