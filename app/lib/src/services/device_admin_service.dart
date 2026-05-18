// lib/src/services/device_admin_service.dart

import 'package:flutter/services.dart';

/// Dart interface for the native DeviceAdminPlugin method channel.
///
/// Responsibilities:
///   • Querying / requesting Device Administrator rights (prevents uninstall).
///   • Notifying the native accessibility service when student mode is active
///     (enables the Settings / DeviceAdmin revocation guard).
class DeviceAdminService {
  DeviceAdminService._();

  static const _channel = MethodChannel('com.example.studymentor/device_admin');

  /// Returns true if this app currently holds Device Administrator rights.
  static Future<bool> isAdminActive() async {
    try {
      return await _channel.invokeMethod<bool>('isAdminActive') ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Opens the system Device Admin activation dialog.
  /// The user must tap "Activate" — there is no programmatic way to skip this.
  static Future<void> requestAdmin() async {
    try {
      await _channel.invokeMethod('requestAdmin');
    } on PlatformException catch (e) {
      // Non-fatal — the user may deny; we'll re-check isAdminActive later.
      // ignore: avoid_print
      print('[DeviceAdmin] requestAdmin error: $e');
    }
  }

  /// Tells the native accessibility service whether a student is currently
  /// logged in. Must be called on every relevant auth state change so the
  /// service stays in sync even when it was restarted by the OS.
  static Future<void> setStudentMode({required bool active}) async {
    try {
      await _channel.invokeMethod('setStudentMode', {'active': active});
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('[DeviceAdmin] setStudentMode error: $e');
    }
  }

  /// Convenience method called when a student logs in.
  /// Enables the accessibility guard and, if we don't yet have admin rights,
  /// prompts the user to grant them.
  static Future<void> onStudentLogin() async {
    await setStudentMode(active: true);
    final hasAdmin = await isAdminActive();
    if (!hasAdmin) {
      await requestAdmin();
    }
  }

  /// Convenience method called when a student logs out or a parent logs in.
  /// Disables the accessibility guard; Device Admin rights are intentionally
  /// kept active (they can only be removed by a parent via device settings).
  static Future<void> onStudentLogout() async {
    await setStudentMode(active: false);
  }
}
