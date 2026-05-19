// lib/src/services/permission_service.dart

import 'package:flutter/services.dart';

/// Represents one of the five required student permissions.
enum RequiredPermission {
  systemAlertWindow,
  packageUsageStats,
  postNotifications,
  accessibilityService,
  deviceAdmin,
}

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
    }
  }

  String get rationale {
    switch (this) {
      case RequiredPermission.systemAlertWindow:
        return 'Display Over Other Apps is required to show study reminders and enforce app rules while you use other apps.';
      case RequiredPermission.packageUsageStats:
        return 'Usage Access is required to track screen time and enforce the app usage limits set by the parent.';
      case RequiredPermission.postNotifications:
        return 'Post Notifications is required to send you study reminders and important alerts from the parent.';
      case RequiredPermission.accessibilityService:
        return 'Accessibility Service is required to monitor which apps are open and enforce the rules set by the parent.';
      case RequiredPermission.deviceAdmin:
        return 'Device Administrator is required to protect the app from being uninstalled without the parent\'s permission.';
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

  /// Checks all five permissions in order and returns the first one that is
  /// not yet granted, or `null` if every permission has been granted.
  static Future<RequiredPermission?> firstMissingPermission() async {
    for (final permission in RequiredPermission.values) {
      final granted = await isGranted(permission);
      if (!granted) return permission;
    }
    return null;
  }

  /// Returns `true` if [permission] is currently granted.
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
