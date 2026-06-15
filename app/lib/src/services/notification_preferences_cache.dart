// lib/src/services/notification_preferences_cache.dart

import 'package:shared_preferences/shared_preferences.dart';

import '../data/providers/dataconnect_provider.dart';

/// Category whose reminder time drives [StreakReminderService]'s daily
/// schedule.
const _kStreakReminderCategory = 'CHILD_STREAK_REMINDER';

/// Reminder time ("HH:mm") written for [_kStreakReminderCategory] when the
/// fetched row has no `reminderTime`, so the streak-reminder WorkManager task
/// always has a value to read.
const kDefaultStreakReminderTime = '19:00';

/// Reads and writes the SharedPreferences mirror of `NotificationPreference`
/// rows that background WorkManager tasks (the parent poll, inactivity
/// check, garden nudge and streak reminder tasks) rely on — those tasks run
/// in isolated background isolates and cannot make a Data Connect call to
/// read preferences directly.
///
/// Cache keys:
///   `pref_{userUid}_{category}`                  -> "true" | "false"
///   `pref_{userUid}_CHILD_STREAK_REMINDER_TIME`  -> "HH:mm"
class NotificationPreferencesCache {
  NotificationPreferencesCache._();

  /// Fetches all `NotificationPreference` rows for [userUid] and overwrites
  /// the corresponding SharedPreferences keys. Called for both parent and
  /// student sessions on login/app-start, and opportunistically by
  /// [ParentNotificationPollService] after each successful poll.
  ///
  /// Propagates any Data Connect failure — callers should treat this as
  /// best-effort and swallow errors so a failed refresh never blocks login or
  /// a background task's main work.
  static Future<void> refresh(String userUid) async {
    final rows = await DataConnectProvider().getLocalNotificationPreferences(
      userUid,
    );
    final prefs = await SharedPreferences.getInstance();
    for (final row in rows) {
      final category = row['category'] as String;
      final enabled = row['enabled'] as bool;
      final reminderTime = row['reminder_time'] as String?;

      await prefs.setBool('pref_${userUid}_$category', enabled);

      if (category == _kStreakReminderCategory) {
        await prefs.setString(
          'pref_${userUid}_${_kStreakReminderCategory}_TIME',
          reminderTime ?? kDefaultStreakReminderTime,
        );
      } else if (reminderTime != null) {
        await prefs.setString('pref_${userUid}_${category}_TIME', reminderTime);
      }
    }
  }

  /// Calls `UpsertLocalNotificationPreference` and, on success, updates the
  /// matching SharedPreferences key(s) — the boolean `pref_{userUid}_{category}`
  /// key always, and `pref_{userUid}_{category}_TIME` when [reminderTime] is
  /// non-null.
  ///
  /// Throws without touching the cache on failure, so the cache stays
  /// consistent with the last confirmed Data Connect state. Callers (settings
  /// UI) should revert their optimistic toggle and show an error on failure
  /// rather than writing to the cache themselves.
  static Future<void> updatePreference({
    required String userUid,
    required String category,
    required bool enabled,
    String? reminderTime,
  }) async {
    await DataConnectProvider().upsertLocalNotificationPreference(
      userUid: userUid,
      category: category,
      enabled: enabled,
      reminderTime: reminderTime,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pref_${userUid}_$category', enabled);
    if (reminderTime != null) {
      await prefs.setString('pref_${userUid}_${category}_TIME', reminderTime);
    }
  }

  /// Removes every `pref_{userUid}_*` key. Call on logout — scoped to
  /// [userUid] so a shared device with both a parent and a student session
  /// keeps the other role's cached preferences.
  static Future<void> clear(String userUid) async {
    final prefs = await SharedPreferences.getInstance();
    final prefix = 'pref_${userUid}_';
    final keys = prefs.getKeys().where((k) => k.startsWith(prefix)).toList();
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}
