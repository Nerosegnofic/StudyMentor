// lib/src/domain/models/installed_app_model.dart

/// Represents one app installed on a student's device.
/// Populated natively via PackageManager and synced to DataConnect.
class InstalledAppModel {
  final String packageName;
  final String appLabel;
  final bool isSystemApp;

  /// Base64-encoded 48×48 PNG launcher icon.
  /// Null if encoding failed on the native side — UI falls back to a
  /// letter-avatar in that case.
  final String? iconBase64;

  InstalledAppModel({
    required this.packageName,
    required this.appLabel,
    required this.isSystemApp,
    this.iconBase64,
  });

  /// Deserialises a row returned by [DataConnectProvider.getInstalledAppsForStudent].
  factory InstalledAppModel.fromJson(Map<String, dynamic> json) =>
      InstalledAppModel(
        packageName: json['package_name'] as String,
        appLabel: json['app_label'] as String,
        isSystemApp: json['is_system_app'] as bool? ?? false,
        iconBase64: json['icon_base64'] as String?,
      );
}
