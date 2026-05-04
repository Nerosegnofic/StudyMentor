// lib/src/services/installed_apps_service.dart

import 'package:flutter/services.dart';
import '../domain/models/installed_app_model.dart';

/// Flutter-side wrapper for the `com.example.studymentor/installed_apps`
/// native MethodChannel.
///
/// Responsibilities:
///   - [getFromDevice]       — query PackageManager for all installed apps.
///   - [isInventoryDirty]    — check whether a package was installed/removed
///                             since the last sync (set by PackageChangedReceiver).
///   - [markInventoryClean]  — clear the dirty flag after a successful sync.
class InstalledAppsService {
  InstalledAppsService._();
  static final InstalledAppsService instance = InstalledAppsService._();

  static const _channel =
      MethodChannel('com.example.studymentor/installed_apps');

  /// Returns all apps installed on this device that are safe to monitor.
  /// System apps are excluded unless [includeSystemApps] is true.
  Future<List<InstalledAppModel>> getFromDevice({
    bool includeSystemApps = false,
  }) async {
    final raw = await _channel.invokeMethod<List<dynamic>>(
      'getInstalledApps',
      {'includeSystemApps': includeSystemApps},
    );
    if (raw == null) return [];
    return raw
        .cast<Map<dynamic, dynamic>>()
        .map(
          (m) => InstalledAppModel(
            packageName: m['package'] as String,
            appLabel: m['label'] as String,
            isSystemApp: m['isSystem'] as bool? ?? false,
            iconBase64: m['iconBase64'] as String?,
          ),
        )
        .toList();
  }

  /// Returns true if [PackageChangedReceiver] has set the dirty flag since
  /// the last time [markInventoryClean] was called.
  Future<bool> isInventoryDirty() async {
    return await _channel.invokeMethod<bool>('isInventoryDirty') ?? false;
  }

  /// Clears the dirty flag. Call this after a successful DataConnect sync.
  Future<void> markInventoryClean() async {
    await _channel.invokeMethod<void>('markInventoryClean');
  }

  /// Returns the Base64-encoded icon for [packageName], or null if the app
  /// is not installed or the icon cannot be retrieved.
  Future<String?> getAppIcon(String packageName) async {
    try {
      return await _channel.invokeMethod<String>(
        'getAppIcon',
        {'package': packageName},
      );
    } catch (_) {
      return null;
    }
  }
}
