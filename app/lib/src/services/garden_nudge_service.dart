// lib/src/services/garden_nudge_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../data/repositories/ai_engine_repository.dart';
import 'local_notification_service.dart';
import 'notification_localizations.dart';

/// Unique name / task name used to register the garden-nudge
/// [OneTimeWorkRequest] with WorkManager.
const kGardenNudgeTaskName = 'gardenNudge';

/// Tag used to register and later cancel the garden-nudge work request.
const kGardenNudgeTaskTag = 'CHILD_GARDEN_NUDGE_TASK';

/// Schedules and runs the daily "garden nudge" — a once-a-day reminder
/// pointing the student at the subject they've neglected the longest.
///
/// Implemented as a self-rescheduling [OneTimeWorkRequest] chain (rather than
/// a periodic task) so the very first fire can land at a fixed 18:00 local
/// time regardless of when the student first logs in, while every
/// subsequent fire is exactly 24h after the previous one.
///
/// The 18:00 firing time is intentionally fixed and not user-configurable —
/// unlike the streak reminder, the garden nudge is a passive ambient feature.
/// (Documented here for reference; see dissertation for the design rationale.)
///
/// [runTask] executes in a fresh background isolate (see `callbackDispatcher`
/// in `main.dart`), so it cannot rely on any in-memory state from the
/// foreground app — all dedup/preference state is read from
/// [SharedPreferences] and all progress data comes from the AI engine.
class GardenNudgeService {
  GardenNudgeService._();

  /// Registers the next [OneTimeWorkRequest].
  ///
  /// [delay] defaults to the duration until the next 18:00 local time
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
      kGardenNudgeTaskName,
      kGardenNudgeTaskName,
      tag: kGardenNudgeTaskTag,
      initialDelay: delay ?? _delayUntilNext18(),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: policy,
    );
  }

  /// Cancels the pending/scheduled garden-nudge work and clears per-student
  /// dedup state. Call on logout.
  static Future<void> cancel(String studentUid) async {
    await Workmanager().cancelByTag(kGardenNudgeTaskTag);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_garden_nudge_date_$studentUid');
  }

  /// The actual nudge logic, called from `callbackDispatcher` when
  /// [kGardenNudgeTaskName] fires. Always re-enqueues the next run (24h
  /// later) before returning, except when no student is signed in (logout
  /// already cancelled the chain).
  static Future<void> runTask() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final studentUid = user.uid;

      final prefs = await SharedPreferences.getInstance();

      final enabled =
          prefs.getBool('pref_${studentUid}_CHILD_GARDEN_NUDGE') ?? true;
      if (!enabled) {
        await scheduleNext(delay: const Duration(hours: 24));
        return;
      }

      final today = _dateKey(DateTime.now());
      if (prefs.getString('last_garden_nudge_date_$studentUid') == today) {
        await scheduleNext(delay: const Duration(hours: 24));
        return;
      }

      final plants = await AiEngineRepository.instance.getGarden();
      final cutoff = DateTime.now().subtract(const Duration(days: 3));
      final neglected = plants
          .where((p) => p.updatedAt == null || p.updatedAt!.isBefore(cutoff))
          .toList();

      if (neglected.isEmpty) {
        await scheduleNext(delay: const Duration(hours: 24));
        return;
      }

      // Never-studied subjects (updatedAt == null) come first; within each
      // group, the lowest mastery score breaks ties.
      neglected.sort((a, b) {
        if (a.updatedAt == null && b.updatedAt == null) {
          return a.masteryPercent.compareTo(b.masteryPercent);
        }
        if (a.updatedAt == null) return -1;
        if (b.updatedAt == null) return 1;
        final cmp = a.updatedAt!.compareTo(b.updatedAt!);
        if (cmp != 0) return cmp;
        return a.masteryPercent.compareTo(b.masteryPercent);
      });

      final target = neglected.first;

      await LocalNotificationService.instance.init();
      final loc = await NotificationLocalizations.current();
      await LocalNotificationService.instance.show(
        id: kNotifIdGardenNudge,
        channelId: kChannelChildGarden,
        title: loc.notifGardenNudgeTitle(target.subjectName),
        body: loc.notifGardenNudgeBody(target.subjectName),
      );

      await prefs.setString('last_garden_nudge_date_$studentUid', today);
      await scheduleNext(delay: const Duration(hours: 24));
    } catch (_) {
      // Never let a failure kill the daily chain.
      try {
        await scheduleNext(delay: const Duration(hours: 24));
      } catch (_) {}
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  static Duration _delayUntilNext18() {
    final now = DateTime.now();
    var target = DateTime(now.year, now.month, now.day, 18);
    if (!target.isAfter(now)) {
      target = target.add(const Duration(days: 1));
    }
    return target.difference(now);
  }

  static String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
