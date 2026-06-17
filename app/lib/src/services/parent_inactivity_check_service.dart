// lib/src/services/parent_inactivity_check_service.dart

import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../data/providers/dataconnect_provider.dart';
import 'local_notification_service.dart';
import 'notification_localizations.dart';

/// Unique name / task name used to register the parent-inactivity-check
/// [OneTimeWorkRequest] with WorkManager.
const kParentInactivityCheckTaskName = 'parentInactivityCheck';

/// Tag used to register and later cancel the parent-inactivity-check work
/// request.
const kParentInactivityCheckTaskTag = 'PARENT_INACTIVITY_CHECK_TASK';

/// A child is considered inactive once this much time has passed since their
/// `referenceTime` (see [runTask]).
const _kInactivityThreshold = Duration(days: 3);

/// Schedules and runs the daily "inactivity check" on the parent's device —
/// alerts the parent when a child hasn't completed a quiz in 3+ days.
///
/// Implemented as a self-rescheduling [OneTimeWorkRequest] chain (rather than
/// a periodic task) so the very first fire can land at a fixed 20:00 local
/// time regardless of when the parent first logs in, while every subsequent
/// fire is exactly 24h after the previous one — the same pattern as
/// `GardenNudgeService` and `StreakReminderService`.
///
/// [runTask] executes in a fresh background isolate (see `callbackDispatcher`
/// in `main.dart`), so all state is read from [SharedPreferences] — in
/// particular `parentUid`, cached by `AuthBloc` on parent login.
class ParentInactivityCheckService {
  ParentInactivityCheckService._();

  /// Registers the next [OneTimeWorkRequest].
  ///
  /// [delay] defaults to the duration until the next 20:00 local time
  /// (today if it hasn't passed yet, otherwise tomorrow). Pass
  /// `Duration(hours: 24)` when re-enqueuing after a run.
  ///
  /// [policy] controls what happens if a task with the same unique name is
  /// already pending. Use [ExistingWorkPolicy.keep] when (re-)registering on
  /// login/app start so an in-flight daily chain isn't disrupted, and
  /// [ExistingWorkPolicy.replace] (the default) when re-enqueuing from
  /// within [runTask].
  static Future<void> scheduleNext({
    Duration? delay,
    ExistingWorkPolicy policy = ExistingWorkPolicy.replace,
  }) async {
    await Workmanager().registerOneOffTask(
      kParentInactivityCheckTaskName,
      kParentInactivityCheckTaskName,
      tag: kParentInactivityCheckTaskTag,
      initialDelay: delay ?? _delayUntilNext20(),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: policy,
    );
  }

  /// Cancels the pending/scheduled inactivity-check work. Call on parent
  /// logout.
  static Future<void> cancel() async {
    await Workmanager().cancelByTag(kParentInactivityCheckTaskTag);
  }

  /// The actual check logic, called from `callbackDispatcher` when
  /// [kParentInactivityCheckTaskName] fires. Always re-enqueues the next run
  /// (24h later) before returning, except when no parent session is cached
  /// (logout already cancelled the chain).
  ///
  /// For each child, `referenceTime = lastActiveAt ?? createdAt` — a student
  /// who has never completed a quiz has `lastActiveAt == null`, so falling
  /// back to `createdAt` ensures a dormant new account is still caught.
  ///
  /// Dedup: `last_inactivity_notified_reference_{childUid}` stores the
  /// `referenceTime` at the time of the last notification. If it still
  /// matches the current `referenceTime`, the parent was already notified for
  /// this exact inactivity period and the child is skipped. Once the child
  /// studies again, `referenceTime` changes, the stored value no longer
  /// matches, and the next inactivity period permits a fresh notification.
  static Future<void> runTask() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final parentUid = prefs.getString('parentUid');
      if (parentUid == null) return;

      final enabled =
          prefs.getBool('pref_${parentUid}_PARENT_INACTIVITY') ?? true;
      if (!enabled) {
        await scheduleNext(delay: const Duration(hours: 24));
        return;
      }

      final students = await DataConnectProvider().getStudentsByParent(
        parentUid,
      );
      await LocalNotificationService.instance.init();
      final loc = await NotificationLocalizations.current();

      final cutoff = DateTime.now().subtract(_kInactivityThreshold);

      for (final student in students) {
        final childUid = student['uid'] as String;
        final lastActiveAt = student['last_active_at'] as String?;
        final referenceTime = DateTime.parse(
          lastActiveAt ?? student['created_at'] as String,
        );

        if (!referenceTime.isBefore(cutoff)) continue;

        final referenceKey = referenceTime.toIso8601String();
        final dedupKey = 'last_inactivity_notified_reference_$childUid';
        if (prefs.getString(dedupKey) == referenceKey) continue;

        final studentEnabled = prefs.getBool(
              'pref_${parentUid}_notif_student_$childUid',
            ) ??
            true;
        if (!studentEnabled) continue;

        final studentName = student['full_name'] as String;
        await LocalNotificationService.instance.show(
          id: stableIntFromUuid(childUid),
          channelId: kChannelParentAlerts,
          title: loc.notifInactivityTitle(studentName),
          body: loc.notifInactivityBody,
        );

        await prefs.setString(dedupKey, referenceKey);
      }

      await scheduleNext(delay: const Duration(hours: 24));
    } catch (_) {
      // Never let a failure kill the daily chain.
      try {
        await scheduleNext(delay: const Duration(hours: 24));
      } catch (_) {}
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  static Duration _delayUntilNext20() {
    final now = DateTime.now();
    var target = DateTime(now.year, now.month, now.day, 20);
    if (!target.isAfter(now)) {
      target = target.add(const Duration(days: 1));
    }
    return target.difference(now);
  }
}
