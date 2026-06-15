// lib/src/services/parent_notification_poll_service.dart

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../data/providers/dataconnect_provider.dart';
import 'local_notification_service.dart';
import 'notification_preferences_cache.dart';

/// Unique name / task name used to register the parent-notification-poll
/// [PeriodicTask] with WorkManager.
const kParentNotificationPollTaskName = 'parentNotificationPoll';

/// Tag used to register and later cancel the parent-notification-poll work
/// request.
const kParentNotificationPollTaskTag = 'PARENT_NOTIFICATION_POLL_TASK';

/// Polls for `LocalNotificationEvent` rows written by a parent's children and
/// surfaces them as local notifications on the parent's device.
///
/// Registered as a periodic task (every 15 minutes — the WorkManager
/// minimum) on parent login, and cancelled on parent logout.
///
/// [runTask] executes in a fresh background isolate (see `callbackDispatcher`
/// in `main.dart`), so all state is read from [SharedPreferences] — in
/// particular `parentUid`, cached by `AuthBloc` on parent login, which also
/// doubles as the "is this a parent session" check.
class ParentNotificationPollService {
  ParentNotificationPollService._();

  /// Registers the periodic poll task. Safe to call on every parent
  /// login/app-start — [ExistingPeriodicWorkPolicy.keep] prevents duplicate
  /// concurrent polling tasks if registration runs more than once for the
  /// same parent.
  static Future<void> register() async {
    await Workmanager().registerPeriodicTask(
      kParentNotificationPollTaskName,
      kParentNotificationPollTaskName,
      tag: kParentNotificationPollTaskTag,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
  }

  /// Cancels the polling task. Call on parent logout.
  static Future<void> cancel() async {
    await Workmanager().cancelByTag(kParentNotificationPollTaskTag);
  }

  /// The actual poll logic, called from `callbackDispatcher` when
  /// [kParentNotificationPollTaskName] fires.
  ///
  /// Marks every fetched event as read *before* posting any notifications —
  /// this is the dedup boundary. Any event written by a student device after
  /// that point is left unread and picked up on the next poll, so it can
  /// never be lost. If the task is killed after marking-as-read but before
  /// all notifications post, the worst case is one missed notification in
  /// this batch — never a duplicate, since an event can never be processed
  /// twice.
  static Future<void> runTask() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final parentUid = prefs.getString('parentUid');
      if (parentUid == null) return;

      final provider = DataConnectProvider();
      final events = await provider.getUnreadLocalNotificationEvents(
        parentUid,
      );

      if (events.isNotEmpty) {
        final fetchedEventIds = events
            .map((event) => event['id'] as String)
            .toList();
        await provider.markLocalNotificationEventsRead(fetchedEventIds);

        await LocalNotificationService.instance.init();

        for (final event in events) {
          final eventType = event['event_type'] as String;
          final mapping = _channelAndPreferenceFor(eventType);
          if (mapping == null) continue;
          final (channelId, preference) = mapping;

          final enabled =
              prefs.getBool('pref_${parentUid}_$preference') ?? true;
          if (!enabled) continue;

          Map<String, dynamic> payload;
          try {
            payload =
                jsonDecode(event['payload'] as String) as Map<String, dynamic>;
          } catch (_) {
            continue;
          }

          await LocalNotificationService.instance.show(
            id: stableIntFromUuid(event['id'] as String),
            channelId: channelId,
            title: payload['title'] as String? ?? '',
            body: payload['body'] as String? ?? '',
          );
        }
      }

      // Opportunistic cache refresh — best-effort, never retried. A parent
      // who keeps the app open for weeks without logging out would otherwise
      // accumulate indefinitely stale preferences; since this task is already
      // on the network, the refresh costs nothing meaningful.
      try {
        await NotificationPreferencesCache.refresh(parentUid);
      } catch (_) {}
    } catch (_) {
      // A failed poll just means these events are picked up on the next run.
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  /// Maps an event type to its notification channel and the parent
  /// preference category that gates it. Returns null for event types that
  /// have no parent-facing notification.
  static (String, String)? _channelAndPreferenceFor(String eventType) {
    switch (eventType) {
      case 'LEVEL_UP':
      case 'BADGE_EARNED':
        return (kChannelParentProgress, 'PARENT_CHILD_PROGRESS');
      case 'STREAK_BROKEN':
        return (kChannelParentAlerts, 'PARENT_STREAK_ALERTS');
      default:
        return null;
    }
  }
}
