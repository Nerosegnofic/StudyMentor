// lib/src/domain/models/app_config_model.dart

/// Represents one app rule saved by a parent for a student.
class AppRuleModel {
  final String id;
  final String packageName;
  final String appLabel;
  final int usageHours;
  final int usageMinutes;
  final int cooldownHours;
  final int cooldownMinutes;

  AppRuleModel({
    required this.id,
    required this.packageName,
    required this.appLabel,
    required this.usageHours,
    required this.usageMinutes,
    required this.cooldownHours,
    required this.cooldownMinutes,
  });

  factory AppRuleModel.fromJson(Map<String, dynamic> json) => AppRuleModel(
        id: json['id'] as String,
        packageName: json['package_name'] as String,
        appLabel: json['app_label'] as String,
        usageHours: (json['usage_hours'] as int?) ?? 0,
        usageMinutes: (json['usage_minutes'] as int?) ?? 0,
        cooldownHours: (json['cooldown_hours'] as int?) ?? 0,
        cooldownMinutes: (json['cooldown_minutes'] as int?) ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'package_name': packageName,
        'app_label': appLabel,
        'usage_hours': usageHours,
        'usage_minutes': usageMinutes,
        'cooldown_hours': cooldownHours,
        'cooldown_minutes': cooldownMinutes,
      };

  AppRuleModel copyWith({
    String? id,
    String? packageName,
    String? appLabel,
    int? usageHours,
    int? usageMinutes,
    int? cooldownHours,
    int? cooldownMinutes,
  }) =>
      AppRuleModel(
        id: id ?? this.id,
        packageName: packageName ?? this.packageName,
        appLabel: appLabel ?? this.appLabel,
        usageHours: usageHours ?? this.usageHours,
        usageMinutes: usageMinutes ?? this.usageMinutes,
        cooldownHours: cooldownHours ?? this.cooldownHours,
        cooldownMinutes: cooldownMinutes ?? this.cooldownMinutes,
      );
}

/// A pending (unsaved) rule being configured in the UI.
class PendingAppRule {
  final String packageName;
  final String appLabel;
  final String? iconBase64;
  int usageHours;
  int usageMinutes;
  int cooldownHours;
  int cooldownMinutes;

  PendingAppRule({
    required this.packageName,
    required this.appLabel,
    this.iconBase64,
    this.usageHours = 0,
    this.usageMinutes = 30,
    this.cooldownHours = 0,
    this.cooldownMinutes = 10,
  });
}
