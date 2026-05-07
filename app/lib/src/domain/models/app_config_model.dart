// lib/src/domain/models/app_config_model.dart

/// Represents the global usage and cooldown time limits for a student.
/// One instance per student — applies to ALL restricted apps.
class StudentConfigModel {
  final int usageHours;
  final int usageMinutes;
  final int cooldownHours;
  final int cooldownMinutes;

  const StudentConfigModel({
    this.usageHours = 0,
    this.usageMinutes = 30,
    this.cooldownHours = 0,
    this.cooldownMinutes = 10,
  });

  StudentConfigModel copyWith({
    int? usageHours,
    int? usageMinutes,
    int? cooldownHours,
    int? cooldownMinutes,
  }) => StudentConfigModel(
    usageHours: usageHours ?? this.usageHours,
    usageMinutes: usageMinutes ?? this.usageMinutes,
    cooldownHours: cooldownHours ?? this.cooldownHours,
    cooldownMinutes: cooldownMinutes ?? this.cooldownMinutes,
  );
}

/// Represents one app rule saved by a parent for a student.
/// Time limits are not stored here — they live in [StudentConfigModel].
class AppRuleModel {
  final String id;
  final String packageName;
  final String appLabel;

  AppRuleModel({
    required this.id,
    required this.packageName,
    required this.appLabel,
  });

  factory AppRuleModel.fromJson(Map<String, dynamic> json) => AppRuleModel(
    id: json['id'] as String,
    packageName: json['package_name'] as String,
    appLabel: json['app_label'] as String,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'package_name': packageName,
    'app_label': appLabel,
  };

  AppRuleModel copyWith({
    String? id,
    String? packageName,
    String? appLabel,
  }) => AppRuleModel(
    id: id ?? this.id,
    packageName: packageName ?? this.packageName,
    appLabel: appLabel ?? this.appLabel,
  );
}

/// A pending (unsaved) app rule being configured in the UI.
/// Time limits are not stored here — they live in [StudentConfigModel].
class PendingAppRule {
  final String packageName;
  final String appLabel;

  PendingAppRule({
    required this.packageName,
    required this.appLabel,
  });
}
