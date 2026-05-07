// lib/src/domain/models/installed_app_model.dart

/// Represents one app installed on a student's device.
/// Populated natively via PackageManager and synced to DataConnect.
/// Icons are NOT stored — the UI renders a first-letter avatar instead.
class InstalledAppModel {
  final String packageName;
  final String appLabel;
  final bool isSystemApp;

  InstalledAppModel({
    required this.packageName,
    required this.appLabel,
    required this.isSystemApp,
  });

  /// Deserialises a row returned by [DataConnectProvider.getInstalledAppsForStudent].
  factory InstalledAppModel.fromJson(Map<String, dynamic> json) =>
      InstalledAppModel(
        packageName: json['package_name'] as String,
        appLabel: json['app_label'] as String,
        isSystemApp: json['is_system_app'] as bool? ?? false,
      );
}
