// lib/src/domain/models/app_config_model.dart

import 'quiz_count.dart';

/// Represents the global usage and cooldown time limits for a student.
/// One instance per student — applies to ALL restricted apps.
///
/// All fields are clamped on construction:
///   • hours   → 0 – 24
///   • minutes → 0 – 59
class StudentConfigModel {
  final int usageHours;
  final int usageMinutes;
  final int cooldownHours;
  final int cooldownMinutes;
  final QuizCount quizCount;

  const StudentConfigModel({
    this.usageHours = 0,
    this.usageMinutes = 30,
    this.cooldownHours = 0,
    this.cooldownMinutes = 1,
    this.quizCount = const Auto(),
  });

  /// Internal constructor that clamps every field to its valid range.
  /// Named so callers can't bypass clamping accidentally.
  factory StudentConfigModel.validated({
    required int usageHours,
    required int usageMinutes,
    required int cooldownHours,
    required int cooldownMinutes,
    required QuizCount quizCount,
  }) {
    return StudentConfigModel(
      usageHours: usageHours.clamp(0, 24),
      usageMinutes: usageMinutes.clamp(0, 59),
      cooldownHours: cooldownHours.clamp(0, 24),
      cooldownMinutes: cooldownMinutes.clamp(0, 59),
      quizCount: quizCount,
    );
  }

  factory StudentConfigModel.fromJson(Map<String, dynamic> json) =>
      StudentConfigModel.validated(
        usageHours: json['usage_hours'] as int? ?? 0,
        usageMinutes: json['usage_minutes'] as int? ?? 30,
        cooldownHours: json['cooldown_hours'] as int? ?? 0,
        cooldownMinutes: json['cooldown_minutes'] as int? ?? 1,
        quizCount: QuizCount.fromJson(json['quiz_count']),
      );

  StudentConfigModel copyWith({
    int? usageHours,
    int? usageMinutes,
    int? cooldownHours,
    int? cooldownMinutes,
    QuizCount? quizCount,
  }) => StudentConfigModel.validated(
    usageHours: usageHours ?? this.usageHours,
    usageMinutes: usageMinutes ?? this.usageMinutes,
    cooldownHours: cooldownHours ?? this.cooldownHours,
    cooldownMinutes: cooldownMinutes ?? this.cooldownMinutes,
    quizCount: quizCount ?? this.quizCount,
  );

  /// Returns true if all fields are within their valid ranges.
  bool get isValid =>
      usageHours >= 0 &&
      usageHours <= 24 &&
      usageMinutes >= 0 &&
      usageMinutes <= 59 &&
      cooldownHours >= 0 &&
      cooldownHours <= 24 &&
      cooldownMinutes >= 0 &&
      cooldownMinutes <= 59;
}

/// Represents one app rule saved by a parent for a student.
/// Time limits are not stored here — they live in [StudentConfigModel].
class AppRuleModel {
  final String id;
  final String packageName;
  final String appLabel;
  final bool isPaused;

  AppRuleModel({
    required this.id,
    required this.packageName,
    required this.appLabel,
    this.isPaused = false,
  });

  factory AppRuleModel.fromJson(Map<String, dynamic> json) => AppRuleModel(
    id: json['id'] as String,
    packageName: json['package_name'] as String,
    appLabel: json['app_label'] as String,
    isPaused: json['is_paused'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'package_name': packageName,
    'app_label': appLabel,
    'is_paused': isPaused,
  };

  AppRuleModel copyWith({
    String? id, 
    String? packageName, 
    String? appLabel,
    bool? isPaused,
  }) =>
      AppRuleModel(
        id: id ?? this.id,
        packageName: packageName ?? this.packageName,
        appLabel: appLabel ?? this.appLabel,
        isPaused: isPaused ?? this.isPaused,
      );
}

/// A pending (unsaved) app rule being configured in the UI.
/// Time limits are not stored here — they live in [StudentConfigModel].
class PendingAppRule {
  final String packageName;
  final String appLabel;
  final bool isPaused;

  PendingAppRule({
    required this.packageName, 
    required this.appLabel,
    this.isPaused = false,
  });
  
  PendingAppRule copyWith({
    String? packageName,
    String? appLabel,
    bool? isPaused,
  }) {
    return PendingAppRule(
      packageName: packageName ?? this.packageName,
      appLabel: appLabel ?? this.appLabel,
      isPaused: isPaused ?? this.isPaused,
    );
  }
}
