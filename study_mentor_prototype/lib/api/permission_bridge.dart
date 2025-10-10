import 'package:flutter/services.dart';

/// A bridge to communicate with native Android for checking and requesting
/// special permissions that are not handled by the permission_handler package.
class PermissionBridge {
  static const _channel =
  MethodChannel('com.example.study_mentor_prototype/permissions');

  /// Checks if the 'PACKAGE_USAGE_STATS' permission has been granted.
  static Future<bool> hasUsageStatsPermission() async {
    try {
      final bool hasPermission =
      await _channel.invokeMethod('hasUsageStatsPermission');
      return hasPermission;
    } on PlatformException catch (e) {
      print(
          "PermissionBridge: Failed to check usage stats permission: '${e.message}'.");
      return false;
    }
  }

  /// Opens the system settings screen for the 'PACKAGE_USAGE_STATS' permission.
  static Future<void> requestUsageStatsPermission() async {
    try {
      await _channel.invokeMethod('requestUsageStatsPermission');
    } on PlatformException catch (e) {
      print(
          "PermissionBridge: Failed to request usage stats permission: '${e.message}'.");
    }
  }

  /// Checks if the 'SYSTEM_ALERT_WINDOW' permission has been granted.
  static Future<bool> hasSystemAlertWindowPermission() async {
    try {
      final bool hasPermission =
      await _channel.invokeMethod('hasSystemAlertWindowPermission');
      return hasPermission;
    } on PlatformException catch (e) {
      print(
          "PermissionBridge: Failed to check system alert window permission: '${e.message}'.");
      return false;
    }
  }

  /// Opens the system settings screen for the 'SYSTEM_ALERT_WINDOW' permission.
  static Future<void> requestSystemAlertWindowPermission() async {
    try {
      await _channel.invokeMethod('requestSystemAlertWindowPermission');
    } on PlatformException catch (e) {
      print(
          "PermissionBridge: Failed to request system alert window permission: '${e.message}'.");
    }
  }
}
