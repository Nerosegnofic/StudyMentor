// lib/src/services/student_local_notification_handler.dart

import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../data/providers/dataconnect_provider.dart';
import 'local_notification_service.dart';
import 'notification_localizations.dart';

// Streak values that trigger a milestone celebration.
const _kStreakMilestones = {7, 14, 30};

// Streak values that trigger a near-milestone nudge (milestone − 1).
const _kNearMilestones = {6, 13, 29};

/// Task name / tag for the retry queue used when
/// `InsertLocalNotificationEvent` fails (no network, timeout) right after a
/// local notification fires.
///
/// The retry task carries the full event in its [Workmanager] input data
/// (`eventType`, `payload`, `fromStudentUid`, `toParentUid`) — see
/// `callbackDispatcher` in `main.dart`, which is the retry task's only way to
/// access this data.
const kStudentEventWriteTaskName = 'studentEventWrite';

/// Tag used to register the student-event-write retry task.
const kStudentEventWriteTaskTag = 'STUDENT_EVENT_WRITE_TASK';

/// Fires student-side local notifications in response to gamification events.
///
/// Called directly from the relevant BLoC — there is no notification BLoC.
/// Each method is a one-shot fire-and-forget call; errors are swallowed so
/// a notification failure never crashes the quiz flow.
///
/// Preference notes:
///   CHILD_MILESTONE_CELEBRATION is always on and is not user-configurable.
///   Preference checks for other categories will be added as those triggers
///   are implemented in subsequent phases.
class StudentLocalNotificationHandler {
  StudentLocalNotificationHandler._();

  static final instance = StudentLocalNotificationHandler._();

  // ── Deduplication guard ─────────────────────────────────────────────────────
  //
  // Tracks event keys ("{eventType}_{uniqueIdentifier}", e.g. "LEVEL_UP_5",
  // "STREAK_MILESTONE_7", "BADGE_EARNED_badge_math_bronze") that have already
  // fired a local notification and/or InsertLocalNotificationEvent this
  // session. In-memory only and intentionally not persisted — cleared on
  // logout via [clearFiredEvents].
  final Set<String> _firedEvents = {};

  /// Returns true the first time [key] is claimed, false on every
  /// subsequent call with the same [key]. Callers must skip both the local
  /// notification and any InsertLocalNotificationEvent call when this returns
  /// false.
  bool _claimEvent(String key) => _firedEvents.add(key);

  /// Clears all recorded event keys. Call on logout so the next session
  /// starts with a clean slate.
  void clearFiredEvents() => _firedEvents.clear();

  // ── Cross-device event writes ───────────────────────────────────────────────

  /// Writes a cross-device `LocalNotificationEvent` so the parent learns
  /// about [eventType] within 15 minutes via the parent's polling
  /// WorkManager task.
  ///
  /// Called immediately after the local notification fires — the local
  /// notification and this write are part of the same "celebration moment"
  /// for the student, but they are independent operations: a failure here
  /// must never affect the student's own notification or the calling flow.
  ///
  /// On failure (no network, timeout) the write is enqueued as a
  /// [OneTimeWorkRequest] tagged [kStudentEventWriteTaskTag] with a
  /// [NetworkType.connected] constraint, so it retries as soon as
  /// connectivity is restored.
  static Future<void> writeNotificationEvent({
    required String fromStudentUid,
    required String toParentUid,
    required String eventType,
    required Map<String, dynamic> payload,
  }) async {
    final payloadJson = jsonEncode(payload);
    try {
      await DataConnectProvider().insertLocalNotificationEvent(
        fromStudentUid: fromStudentUid,
        toParentUid: toParentUid,
        eventType: eventType,
        payload: payloadJson,
      );
    } catch (_) {
      try {
        await Workmanager().registerOneOffTask(
          '${kStudentEventWriteTaskName}_${eventType}_${DateTime.now().microsecondsSinceEpoch}',
          kStudentEventWriteTaskName,
          tag: kStudentEventWriteTaskTag,
          constraints: Constraints(networkType: NetworkType.connected),
          inputData: {
            'eventType': eventType,
            'payload': payloadJson,
            'fromStudentUid': fromStudentUid,
            'toParentUid': toParentUid,
          },
        );
      } catch (_) {
        // If even enqueuing the retry fails, drop silently — a notification
        // failure must never crash the calling flow.
      }
    }
  }

  /// The parent's uid for [studentUid], cached in [SharedPreferences] by
  /// `AuthBloc._cacheStudentContext` at login. Returns null if not cached
  /// (e.g. login happened before this cache existed) — callers should skip
  /// the cross-device write in that case rather than block on a network call.
  static Future<String?> _parentUidFor(String studentUid) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('parent_uid_$studentUid');
  }

  /// The student's display name, cached in [SharedPreferences] by
  /// `AuthBloc._cacheStudentContext` at login. Falls back to "Your child" if
  /// not cached.
  static Future<String> _studentDisplayName(String studentUid) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('student_full_name_$studentUid') ?? 'Your child';
  }

  // ── Level-up ────────────────────────────────────────────────────────────────

  /// Posts a level-up celebration on [kChannelChildMilestones] and writes the
  /// matching `LEVEL_UP` event for the parent.
  ///
  /// Preference: CHILD_MILESTONE_CELEBRATION — always on, no check needed.
  ///
  /// Called from [GamificationBloc] when [GamificationRewardProcessed] is
  /// emitted with a non-null [leveledUpTo].
  Future<void> handleLevelUp(int newLevel) async {
    if (!_claimEvent('LEVEL_UP_$newLevel')) return;

    final studentUid = FirebaseAuth.instance.currentUser?.uid;

    try {
      final loc = await NotificationLocalizations.current();
      await LocalNotificationService.instance.show(
        id: kNotifIdLevelUp,
        channelId: kChannelChildMilestones,
        title: loc.notifLevelUpTitle(newLevel),
        body: loc.notifLevelUpBody,
        payload: studentUid != null ? 'STUDENT_PROFILE:$studentUid' : null,
      );
    } catch (_) {
      // Notification failure must not surface to the user or interrupt the
      // quiz result flow. Silently swallow.
    }

    if (studentUid == null) return;
    final parentUid = await _parentUidFor(studentUid);
    if (parentUid == null) return;

    final studentName = await _studentDisplayName(studentUid);
    await writeNotificationEvent(
      fromStudentUid: studentUid,
      toParentUid: parentUid,
      eventType: 'LEVEL_UP',
      payload: {
        'screen': 'STUDENT_DETAIL',
        'childId': studentUid,
        'studentName': studentName,
        'level': '$newLevel',
      },
    );
  }

  // ── Streak milestone ─────────────────────────────────────────────────────────

  /// Posts a streak milestone celebration on [kChannelChildMilestones] when
  /// [currentStreak] is exactly 7, 14, or 30, and writes the matching
  /// `STREAK_MILESTONE` event for the parent.
  ///
  /// Preference: CHILD_MILESTONE_CELEBRATION — always on, no check needed.
  ///
  /// Called from [GamificationBloc] when [GamificationRewardProcessed] is
  /// emitted with [streakIncremented] true and [currentStreak] in
  /// [_kStreakMilestones]. Only call this method after confirming the streak
  /// actually incremented — not on every quiz completion.
  Future<void> handleStreakMilestone(int currentStreak) async {
    assert(
      _kStreakMilestones.contains(currentStreak),
      'handleStreakMilestone called with non-milestone streak: $currentStreak',
    );
    if (!_claimEvent('STREAK_MILESTONE_$currentStreak')) return;

    try {
      final loc = await NotificationLocalizations.current();
      await LocalNotificationService.instance.show(
        id: kNotifIdStreakMilestone,
        channelId: kChannelChildMilestones,
        title: loc.notifStreakMilestoneTitle(currentStreak),
        body: loc.notifStreakMilestoneBody(currentStreak),
      );
    } catch (_) {
      // Swallow — notification failure must not interrupt the quiz result flow.
    }

    final studentUid = FirebaseAuth.instance.currentUser?.uid;
    if (studentUid == null) return;
    final parentUid = await _parentUidFor(studentUid);
    if (parentUid == null) return;

    final studentName = await _studentDisplayName(studentUid);
    await writeNotificationEvent(
      fromStudentUid: studentUid,
      toParentUid: parentUid,
      eventType: 'STREAK_MILESTONE',
      payload: {
        'screen': 'STUDENT_DETAIL',
        'childId': studentUid,
        'studentName': studentName,
        'streakDays': '$currentStreak',
      },
    );
  }

  // ── Near-milestone nudge ─────────────────────────────────────────────────────

  /// Posts a near-milestone nudge on [kChannelChildStreak] when
  /// [currentStreak] is exactly 6, 13, or 29 (one day before a milestone).
  ///
  /// Preference: CHILD_NEAR_MILESTONE — user-configurable. The caller is
  /// responsible for checking this preference before calling this method.
  /// (Preference checking will be wired in Phase 5 when the settings UI
  /// reads from SharedPreferences cache.)
  ///
  /// Called from [GamificationBloc] when [GamificationRewardProcessed] is
  /// emitted with [streakIncremented] true and [currentStreak] in
  /// [_kNearMilestones].
  Future<void> handleNearMilestone(int currentStreak) async {
    assert(
      _kNearMilestones.contains(currentStreak),
      'handleNearMilestone called with non-near-milestone streak: $currentStreak',
    );
    if (!_claimEvent('NEAR_MILESTONE_$currentStreak')) return;

    // The milestone the student is one day away from.
    final nextMilestone = currentStreak + 1;

    try {
      final loc = await NotificationLocalizations.current();
      await LocalNotificationService.instance.show(
        id: kNotifIdNearMilestone,
        channelId: kChannelChildStreak,
        title: loc.notifNearMilestoneTitle,
        body: loc.notifNearMilestoneBody(nextMilestone),
      );
    } catch (_) {
      // Swallow — notification failure must not interrupt the quiz result flow.
    }

    // Near-milestone is student-only — no parent cross-device event needed.
  }
}
