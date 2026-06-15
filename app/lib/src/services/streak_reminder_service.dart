// lib/src/services/streak_reminder_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import 'local_notification_service.dart';
import 'student_local_notification_handler.dart';

/// Unique name / task name used to register the streak-reminder
/// [OneTimeWorkRequest] with WorkManager.
const kStreakReminderTaskName = 'streakReminder';

/// Tag used to register and later cancel the streak-reminder work request.
const kStreakReminderTaskTag = 'CHILD_STREAK_REMINDER_TASK';

/// Reminder time ("HH:mm", 24h) used when the student hasn't configured a
/// custom time.
const kDefaultStreakReminderTime = '19:00';

/// Schedules and runs the daily "streak reminder" — an evening nudge telling
/// the student to take a quiz before their streak resets.
///
/// Implemented as a self-rescheduling [OneTimeWorkRequest] chain (rather than
/// a periodic task) so the very first fire can land at the student's
/// configured reminder time (default 19:00) regardless of when the student
/// first logs in, while every subsequent fire is exactly 24h after the
/// previous one.
///
/// [runTask] executes in a fresh background isolate (see `callbackDispatcher`
/// in `main.dart`), so it cannot rely on any in-memory state from the
/// foreground app — in particular, the [StudentLocalNotificationHandler]'s
/// `_firedEvents` dedup set is not available here.
/// `last_streak_reminder_date_{studentUid}` in [SharedPreferences] is the
/// sole same-day dedup mechanism for the student-facing reminder.
///
/// [runTask] also performs `STREAK_BROKEN` detection for the parent: this is
/// a separate, unconditional check (independent of the
/// `CHILD_STREAK_REMINDER` preference) using its own dedup mechanism —
/// `last_known_streak_{studentUid}`.
class StreakReminderService {
  StreakReminderService._();

  /// Registers the next [OneTimeWorkRequest].
  ///
  /// [delay] defaults to the duration until the next occurrence of the
  /// student's configured reminder time — read from
  /// `pref_{uid}_CHILD_STREAK_REMINDER_TIME` ("HH:mm"), falling back to
  /// [kDefaultStreakReminderTime]. Pass `Duration(hours: 24)` when
  /// re-enqueuing after a run.
  ///
  /// [policy] controls what happens if a task with the same unique name is
  /// already pending. Use [ExistingWorkPolicy.keep] when (re-)registering on
  /// login/app start so an in-flight daily chain isn't disrupted, and
  /// [ExistingWorkPolicy.replace] (the default) when re-enqueuing from within
  /// [runTask] or rescheduling after a reminder-time change.
  static Future<void> scheduleNext({
    Duration? delay,
    ExistingWorkPolicy policy = ExistingWorkPolicy.replace,
  }) async {
    await Workmanager().registerOneOffTask(
      kStreakReminderTaskName,
      kStreakReminderTaskName,
      tag: kStreakReminderTaskTag,
      initialDelay: delay ?? await _delayUntilNextReminderTime(),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: policy,
    );
  }

  /// Cancels the pending/scheduled streak-reminder work and clears
  /// per-student dedup state. Call on logout.
  static Future<void> cancel(String studentUid) async {
    await Workmanager().cancelByTag(kStreakReminderTaskTag);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_streak_reminder_date_$studentUid');
  }

  /// Cancels the current chain and re-registers it to next fire at
  /// [reminderTime] ("HH:mm"). Call when the student changes their reminder
  /// time in Settings.
  static Future<void> rescheduleForTime(String reminderTime) async {
    await Workmanager().cancelByTag(kStreakReminderTaskTag);
    await scheduleNext(delay: _delayUntilTime(reminderTime));
  }

  /// The actual reminder logic, called from `callbackDispatcher` when
  /// [kStreakReminderTaskName] fires. Always re-enqueues the next run (24h
  /// later) before returning, except when no student is signed in (logout
  /// already cancelled the chain).
  static Future<void> runTask() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final studentUid = user.uid;

      final prefs = await SharedPreferences.getInstance();
      final today = _dateKey(DateTime.now());

      // ── STREAK_BROKEN detection (parent-facing) ───────────────────────────
      //
      // Runs unconditionally, before the CHILD_STREAK_REMINDER preference
      // check below: that preference only controls whether the *student*
      // sees a same-day reminder, and must not suppress the *parent's*
      // streak-broken alert.
      await _detectAndReportStreakBroken(prefs, studentUid, today);

      final enabled =
          prefs.getBool('pref_${studentUid}_CHILD_STREAK_REMINDER') ?? true;
      final alreadySentToday =
          prefs.getString('last_streak_reminder_date_$studentUid') == today;
      final studiedToday =
          prefs.getString('last_active_at_$studentUid') == today;

      if (enabled && !alreadySentToday && !studiedToday) {
        final streak = prefs.getInt('current_streak_$studentUid') ?? 0;

        await LocalNotificationService.instance.init();
        if (streak > 0) {
          await LocalNotificationService.instance.show(
            id: kNotifIdStreakReminder,
            channelId: kChannelChildStreak,
            title: "Don't break your streak! \u{1F525}",
            body: 'One quiz keeps your $streak-day streak alive.',
          );
        } else {
          await LocalNotificationService.instance.show(
            id: kNotifIdStreakReminder,
            channelId: kChannelChildStreak,
            title: 'Start a new streak today!',
            body: 'Take a quick quiz and begin your learning streak.',
          );
        }

        await prefs.setString('last_streak_reminder_date_$studentUid', today);
      }

      // Keep the STREAK_BROKEN baseline current for the next run's detection.
      await prefs.setInt(
        'last_known_streak_$studentUid',
        prefs.getInt('current_streak_$studentUid') ?? 0,
      );

      await scheduleNext(delay: const Duration(hours: 24));
    } catch (_) {
      // Never let a failure kill the daily chain.
      try {
        await scheduleNext(delay: const Duration(hours: 24));
      } catch (_) {}
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  /// Detects whether [studentUid]'s streak broke since the last run of this
  /// task and, if so, writes a `STREAK_BROKEN` event for the parent.
  ///
  /// A streak breaks at midnight if no quiz was completed that day, so this
  /// cannot be detected reliably in the foreground — this background task is
  /// the only place it can be caught.
  ///
  /// Dedup: `last_known_streak_{studentUid}` is reset to 0 once the break is
  /// reported, so this condition won't fire again until a new streak is built
  /// (raising `current_streak_{studentUid}` above 0 again) and broken.
  static Future<void> _detectAndReportStreakBroken(
    SharedPreferences prefs,
    String studentUid,
    String today,
  ) async {
    final lastActiveAt = prefs.getString('last_active_at_$studentUid');
    final lastKnownStreak = prefs.getInt('last_known_streak_$studentUid') ?? 0;

    if (lastKnownStreak <= 0 || lastActiveAt == today) return;

    final parentUid = prefs.getString('parent_uid_$studentUid');
    if (parentUid != null) {
      final studentName =
          prefs.getString('student_full_name_$studentUid') ?? 'Your child';
      await StudentLocalNotificationHandler.writeNotificationEvent(
        fromStudentUid: studentUid,
        toParentUid: parentUid,
        eventType: 'STREAK_BROKEN',
        payload: {
          'title': "$studentName's streak ended",
          'body':
              'Their $lastKnownStreak-day streak was broken. A little encouragement might help.',
          'screen': 'STUDENT_DETAIL',
          'childId': studentUid,
          'previousStreak': '$lastKnownStreak',
        },
      );
    }

    await prefs.setInt('last_known_streak_$studentUid', 0);
  }

  static Future<Duration> _delayUntilNextReminderTime() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return _delayUntilTime(kDefaultStreakReminderTime);

    final prefs = await SharedPreferences.getInstance();
    final time =
        prefs.getString('pref_${user.uid}_CHILD_STREAK_REMINDER_TIME') ??
        kDefaultStreakReminderTime;
    return _delayUntilTime(time);
  }

  /// Duration from now until the next occurrence of [time] ("HH:mm") —
  /// today if it hasn't passed yet, otherwise tomorrow.
  static Duration _delayUntilTime(String time) {
    final parts = time.split(':');
    final hour = int.tryParse(parts[0]) ?? 19;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;

    final now = DateTime.now();
    var target = DateTime(now.year, now.month, now.day, hour, minute);
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
