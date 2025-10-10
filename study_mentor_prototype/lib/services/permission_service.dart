import 'package:study_mentor_prototype/api/permission_bridge.dart';

/// A service to handle checking and requesting special Android permissions.
/// This service acts as a simplified interface to the PermissionBridge.
class PermissionService {
  /// Checks if both the Usage Stats and System Alert Window permissions
  /// have been granted by the user in the system settings.
  static Future<bool> hasAllPermissions() async {
    // These calls now go through our custom native bridge.
    final hasUsageStats = await PermissionBridge.hasUsageStatsPermission();
    final hasSystemAlertWindow =
    await PermissionBridge.hasSystemAlertWindowPermission();

    print("Permission Check: Has Usage Stats? $hasUsageStats, Has System Alert Window? $hasSystemAlertWindow");

    return hasUsageStats && hasSystemAlertWindow;
  }

  /// Opens the system settings screen for the Usage Stats permission.
  ///
  /// This will navigate the user to the appropriate Android settings page.
  static Future<void> requestUsageStatsPermission() async {
    await PermissionBridge.requestUsageStatsPermission();
  }

  /// Opens the system settings screen for the System Alert Window (Draw Over Apps) permission.
  ///
  /// This will navigate the user to the appropriate Android settings page.
  static Future<void> requestSystemAlertWindowPermission() async {
    await PermissionBridge.requestSystemAlertWindowPermission();
  }
}
