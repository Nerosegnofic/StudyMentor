// lib/src/services/permission_service.dart

import 'package:flutter/services.dart';
import '../../l10n/app_localizations.dart';

/// Represents the six permissions required by the student setup flow.
///
/// Order matters: [firstMissingPermission] iterates [RequiredPermission.values]
/// in declaration order, so [batteryOptimization] is always the final step.
enum RequiredPermission {
  systemAlertWindow,
  packageUsageStats,
  postNotifications,
  accessibilityService,
  deviceAdmin,

  /// Step 6 — prevents Android from aggressively killing background services
  /// (UsageTimerService, StudyMentorAccessibilityService) due to battery
  /// optimisation. Must be granted to complete setup.
  batteryOptimization,
}

/// The two permissions required by the parent setup flow, in order.
///
///   1. [RequiredPermission.postNotifications]  — receive child activity alerts
///   2. [RequiredPermission.batteryOptimization] — keep polling job reliable
const List<RequiredPermission> parentPermissions = [
  RequiredPermission.postNotifications,
  RequiredPermission.batteryOptimization,
];

extension RequiredPermissionDetails on RequiredPermission {
  String displayName(AppLocalizations loc) {
    switch (this) {
      case RequiredPermission.systemAlertWindow:
        return loc.permissionDisplayNameSystemAlertWindow;
      case RequiredPermission.packageUsageStats:
        return loc.permissionDisplayNamePackageUsageStats;
      case RequiredPermission.postNotifications:
        return loc.permissionDisplayNamePostNotifications;
      case RequiredPermission.accessibilityService:
        return loc.permissionDisplayNameAccessibilityService;
      case RequiredPermission.deviceAdmin:
        return loc.permissionDisplayNameDeviceAdmin;
      case RequiredPermission.batteryOptimization:
        return loc.permissionDisplayNameBatteryOptimization;
    }
  }

  /// Rationale shown in the **student** permission gate.
  String rationale(AppLocalizations loc) {
    switch (this) {
      case RequiredPermission.systemAlertWindow:
        return loc.permissionRationaleSystemAlertWindow;
      case RequiredPermission.packageUsageStats:
        return loc.permissionRationalePackageUsageStats;
      case RequiredPermission.postNotifications:
        return loc.permissionRationalePostNotifications;
      case RequiredPermission.accessibilityService:
        return loc.permissionRationaleAccessibilityService;
      case RequiredPermission.deviceAdmin:
        return loc.permissionRationaleDeviceAdmin;
      case RequiredPermission.batteryOptimization:
        return loc.permissionRationaleBatteryOptimization;
    }
  }

  /// Rationale shown in the **parent** permission gate.
  ///
  /// Only [postNotifications] and [batteryOptimization] are used by the parent
  /// flow; the other cases fall back to [rationale] for safety.
  String parentRationale(AppLocalizations loc) {
    switch (this) {
      case RequiredPermission.postNotifications:
        return loc.permissionParentRationalePostNotifications;
      case RequiredPermission.batteryOptimization:
        return loc.permissionParentRationaleBatteryOptimization;
      default:
        return rationale(loc);
    }
  }
}

/// Dart-side interface for the native permission channel.
///
/// The channel handles:
///   • Checking whether each permission is currently granted.
///   • Opening the correct system Settings page for the user to grant it.
class PermissionService {
  PermissionService._();

  static const _channel = MethodChannel('com.example.studymentor/permissions');

  /// Returns the first permission (in declaration order) that is not yet
  /// granted, or null if every permission has been granted.
  ///
  /// The native `isGranted` checks run concurrently (instead of 6 sequential
  /// round-trips) — the result is identical because we still pick the first
  /// not-granted permission in [RequiredPermission.values] order.
  static Future<RequiredPermission?> firstMissingPermission() async {
    const permissions = RequiredPermission.values;
    final results = await Future.wait(permissions.map(isGranted));
    for (var i = 0; i < permissions.length; i++) {
      if (!results[i]) return permissions[i];
    }
    return null;
  }

  /// Returns the first not-yet-granted [parentPermissions] entry (in order), or
  /// null if both are granted. Checks run concurrently; order is preserved.
  static Future<RequiredPermission?> firstMissingParentPermission() async {
    final results = await Future.wait(parentPermissions.map(isGranted));
    for (var i = 0; i < parentPermissions.length; i++) {
      if (!results[i]) return parentPermissions[i];
    }
    return null;
  }

  /// Returns true if [permission] is currently granted.
  static Future<bool> isGranted(RequiredPermission permission) async {
    try {
      return await _channel.invokeMethod<bool>('isGranted', {
            'permission': permission.name,
          }) ??
          false;
    } on PlatformException {
      return false;
    }
  }

  /// Opens the system Settings page where the user can grant [permission].
  static Future<void> openSettings(RequiredPermission permission) async {
    try {
      await _channel.invokeMethod('openSettings', {
        'permission': permission.name,
      });
    } on PlatformException catch (e) {
      // Non-fatal — log and move on.
      // ignore: avoid_print
      print('[PermissionService] openSettings error: $e');
    }
  }
}
