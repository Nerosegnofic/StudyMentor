// lib/src/services/permission_service.dart

import 'package:flutter/services.dart';

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
  String get displayName {
    switch (this) {
      case RequiredPermission.systemAlertWindow:
        return 'Display Over Other Apps';
      case RequiredPermission.packageUsageStats:
        return 'Usage Access';
      case RequiredPermission.postNotifications:
        return 'Post Notifications';
      case RequiredPermission.accessibilityService:
        return 'Accessibility Service';
      case RequiredPermission.deviceAdmin:
        return 'Device Administrator';
      case RequiredPermission.batteryOptimization:
        return 'Disable Battery Optimization';
    }
  }

  /// Rationale shown in the **student** permission gate.
  String get rationale {
    switch (this) {
      case RequiredPermission.systemAlertWindow:
        return 'Display Over Other Apps is required to show study reminders '
            'and enforce app rules while you use other apps.';
      case RequiredPermission.packageUsageStats:
        return 'Usage Access is required to track screen time and enforce the '
            'app usage limits set by the parent.';
      case RequiredPermission.postNotifications:
        return 'Post Notifications is required to send you study reminders and '
            'important alerts from the parent.';
      case RequiredPermission.accessibilityService:
        return 'Accessibility Service is required to monitor which apps are '
            'open and enforce the rules set by the parent.';
      case RequiredPermission.deviceAdmin:
        return 'Device Administrator is required to protect the app from being '
            'uninstalled without the parent\'s permission.';
      case RequiredPermission.batteryOptimization:
        return 'Disabling Battery Optimization keeps background services running '
            'reliably. Without this, Android may shut down StudyMentor\'s '
            'background services on some devices, causing timers and app rules '
            'to stop working.';
    }
  }

  /// Rationale shown in the **parent** permission gate.
  ///
  /// Only [postNotifications] and [batteryOptimization] are used by the parent
  /// flow; the other cases fall back to [rationale] for safety.
  String get parentRationale {
    switch (this) {
      case RequiredPermission.postNotifications:
        return 'StudyMentor notifies you when your child levels up, earns a '
            'badge, or hasn\'t studied in a few days. You can change this any '
            'time in Settings.';
      case RequiredPermission.batteryOptimization:
        return 'To reliably notify you about your child\'s activity, '
            'StudyMentor needs to run in the background. Without this, Android '
            'may delay or drop important alerts on some devices.';
      default:
        return rationale;
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

  /// Iterates all permissions in declaration order and returns the first one
  /// that is not yet granted, or null if every permission has been granted.
  static Future<RequiredPermission?> firstMissingPermission() async {
    for (final permission in RequiredPermission.values) {
      final granted = await isGranted(permission);
      if (!granted) return permission;
    }
    return null;
  }

  /// Iterates [parentPermissions] in order and returns the first one that is
  /// not yet granted, or null if both parent permissions have been granted.
  static Future<RequiredPermission?> firstMissingParentPermission() async {
    for (final permission in parentPermissions) {
      final granted = await isGranted(permission);
      if (!granted) return permission;
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
