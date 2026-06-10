// lib/src/services/permission_service.dart

import 'package:flutter/services.dart';

/// Represents one of the six student permissions — five mandatory, one optional.
///
/// Order matters: [firstMissingPermission] iterates [RequiredPermission.values]
/// in declaration order, so [batteryOptimization] is always offered last.
enum RequiredPermission {
  systemAlertWindow,
  packageUsageStats,
  postNotifications,
  accessibilityService,
  deviceAdmin,

  /// Step 6 — recommended but not mandatory.
  ///
  /// Prevents Android from aggressively killing background services
  /// (UsageTimerService, StudyMentorAccessibilityService) due to battery
  /// optimisation. The student may skip this step; the app remains functional
  /// but background services may be terminated on aggressive OEM ROMs.
  batteryOptimization,
}

extension RequiredPermissionDetails on RequiredPermission {
  /// Whether the user is allowed to skip this permission without completing
  /// setup. Currently only [batteryOptimization] is optional.
  bool get isOptional => this == RequiredPermission.batteryOptimization;

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
            'to stop working. This step is recommended but not required.';
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
  /// that is not yet granted, or null if every permission has been granted
  /// (including optional ones that were already accepted or are not applicable).
  ///
  /// Optional permissions that have been *skipped* are not tracked here — the
  /// gate screen handles skip state locally and calls [onAllGranted] directly.
  static Future<RequiredPermission?> firstMissingPermission() async {
    for (final permission in RequiredPermission.values) {
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
