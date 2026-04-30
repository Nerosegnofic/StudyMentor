// lib/src/domain/models/app_config_model.dart

/// Represents one app rule saved by a parent for a student.
class AppRuleModel {
  final String id;
  final String packageName;
  final String appLabel;
  final int usageDurationMinutes;
  final int cooldownDurationMinutes;

  AppRuleModel({
    required this.id,
    required this.packageName,
    required this.appLabel,
    required this.usageDurationMinutes,
    required this.cooldownDurationMinutes,
  });

  factory AppRuleModel.fromJson(Map<String, dynamic> json) => AppRuleModel(
        id: json['id'] as String,
        packageName: json['package_name'] as String,
        appLabel: json['app_label'] as String,
        usageDurationMinutes: json['usage_duration_minutes'] as int,
        cooldownDurationMinutes: json['cooldown_duration_minutes'] as int,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'package_name': packageName,
        'app_label': appLabel,
        'usage_duration_minutes': usageDurationMinutes,
        'cooldown_duration_minutes': cooldownDurationMinutes,
      };

  AppRuleModel copyWith({
    String? id,
    String? packageName,
    String? appLabel,
    int? usageDurationMinutes,
    int? cooldownDurationMinutes,
  }) =>
      AppRuleModel(
        id: id ?? this.id,
        packageName: packageName ?? this.packageName,
        appLabel: appLabel ?? this.appLabel,
        usageDurationMinutes:
            usageDurationMinutes ?? this.usageDurationMinutes,
        cooldownDurationMinutes:
            cooldownDurationMinutes ?? this.cooldownDurationMinutes,
      );
}

/// A pending (unsaved) rule being configured in the UI.
/// Has no id yet — id is assigned by the database on insert.
class PendingAppRule {
  final String packageName;
  final String appLabel;
  int usageDurationMinutes;
  int cooldownDurationMinutes;

  PendingAppRule({
    required this.packageName,
    required this.appLabel,
    this.usageDurationMinutes = 30,
    this.cooldownDurationMinutes = 10,
  });
}
