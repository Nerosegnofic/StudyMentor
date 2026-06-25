// lib/src/services/local_notification_service.dart

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// ── Channel IDs ───────────────────────────────────────────────────────────────

/// Parent-side: child levels up or earns a badge.
const kChannelParentProgress = 'PARENT_PROGRESS';

/// Parent-side: streak broken, inactivity, weak subject.
const kChannelParentAlerts = 'PARENT_ALERTS';

/// Parent-side: weekly reports (optional Phase 6).
const kChannelParentReports = 'PARENT_REPORTS';

/// Student-side: app-timer warnings (foreground service overlay — HIGH).
const kChannelChildTimer = 'CHILD_TIMER';

/// Student-side: streak reminders and near-milestone nudges.
const kChannelChildStreak = 'CHILD_STREAK';

/// Student-side: level-up, badge, and streak-milestone celebrations.
const kChannelChildMilestones = 'CHILD_MILESTONES';

/// Student-side: garden / neglected-subject nudges.
const kChannelChildGarden = 'CHILD_GARDEN';

// ── Notification IDs ──────────────────────────────────────────────────────────
//
// IDs must be stable so that:
//   • cancel(id:) hits the right notification.
//   • Posting the same logical notification twice replaces the previous one
//     rather than stacking (Android replaces when id matches).
//
// Scheduled notifications (streak reminder, garden nudge) get a fixed ID so
// rescheduling cancels the previous pending intent before creating a new one.

const kNotifIdStreakReminder = 1001;
const kNotifIdGardenNudge = 1002;

/// Fixed ID for level-up celebrations.
///
/// Using a fixed ID means a second level-up notification (if the student
/// levels up twice in quick succession) replaces the first rather than
/// stacking. Acceptable behaviour for a celebration toast.
const kNotifIdLevelUp = 1003;

/// Fixed ID for streak milestone celebrations (7, 14, 30 days).
///
/// Replaces the previous milestone notification rather than stacking.
const kNotifIdStreakMilestone = 1004;

/// Fixed ID for near-milestone nudges (6, 13, 29 days).
///
/// Replaces rather than stacks — only one nudge is relevant at a time.
const kNotifIdNearMilestone = 1005;

/// Derives a stable 32-bit non-negative notification ID from a
/// [NotificationEvent] UUID, so each parent-facing event gets its own
/// notification slot — same-channel events (e.g. two `PARENT_PROGRESS`
/// events) don't overwrite each other in the tray.
int stableIntFromUuid(String uuid) => uuid.hashCode & 0x7FFFFFFF;

// ── Service ───────────────────────────────────────────────────────────────────

/// Thin wrapper around [FlutterLocalNotificationsPlugin].
///
/// Usage:
/// ```dart
/// // Once, after Firebase.initializeApp():
/// await LocalNotificationService.instance.init();
///
/// // Post an immediate notification:
/// await LocalNotificationService.instance.show(
///   id: kNotifIdStreakReminder,
///   channelId: kChannelChildStreak,
///   title: 'Don\'t break your streak! 🔥',
///   body: 'One quiz keeps your 5-day streak alive.',
/// );
///
/// ```
class LocalNotificationService {
  LocalNotificationService._();

  static final instance = LocalNotificationService._();

  /// A [GlobalKey] wired into [MaterialApp.navigatorKey] so the tap handler
  /// can push routes without a [BuildContext].
  final navigatorKey = GlobalKey<NavigatorState>();

  final _plugin = FlutterLocalNotificationsPlugin();

  bool _initialised = false;

  // ── init ────────────────────────────────────────────────────────────────────

  /// Initialises the plugin and creates all notification channels.
  ///
  /// Safe to call multiple times — subsequent calls are no-ops.
  /// Must be called after [Firebase.initializeApp()] in main().
  Future<void> init() async {
    if (_initialised) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    await _plugin.initialize(
      settings: const InitializationSettings(android: androidSettings),
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    await _createChannels();

    _initialised = true;
  }

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Posts an immediate notification on [channelId].
  ///
  /// [id] identifies the notification. Posting with the same [id] replaces
  /// the previous notification rather than stacking a new one.
  ///
  /// [payload] is an optional string passed back to [_onNotificationTapped]
  /// when the user taps the notification. Use it to encode a deep-link target,
  /// e.g. `"STUDENT_DETAIL:uid123"`.
  Future<void> show({
    required int id,
    required String channelId,
    required String title,
    required String body,
    String? payload,
  }) async {
    _assertInitialised();
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: _details(channelId),
      payload: payload,
    );
  }

  // ── Channel creation ────────────────────────────────────────────────────────

  Future<void> _createChannels() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin == null) return; // not on Android

    final channels = [
      // ── Parent channels ───────────────────────────────────────────────────
      const AndroidNotificationChannel(
        kChannelParentProgress,
        'Child Progress',
        description: 'Notifies when your child levels up or earns a badge.',
        importance: Importance.defaultImportance,
        playSound: true,
      ),
      const AndroidNotificationChannel(
        kChannelParentAlerts,
        'Performance Alerts',
        description:
            'Alerts for broken streaks, inactivity, and weak subjects.',
        importance: Importance.defaultImportance,
        playSound: true,
      ),
      const AndroidNotificationChannel(
        kChannelParentReports,
        'Weekly Reports',
        description: 'Weekly summary of your child\'s learning progress.',
        importance: Importance.low,
        playSound: false,
      ),
      // ── Student channels ──────────────────────────────────────────────────
      const AndroidNotificationChannel(
        kChannelChildTimer,
        'App Timer',
        description: 'Alerts when an app timer is about to expire.',
        importance: Importance.high,
        playSound: true,
      ),
      const AndroidNotificationChannel(
        kChannelChildStreak,
        'Streak Reminders',
        description: 'Daily reminders to keep your learning streak alive.',
        importance: Importance.defaultImportance,
        playSound: true,
      ),
      const AndroidNotificationChannel(
        kChannelChildMilestones,
        'Milestones & Rewards',
        description: 'Celebrations for level-ups, badges, and streak records.',
        importance: Importance.defaultImportance,
        playSound: true,
      ),
      const AndroidNotificationChannel(
        kChannelChildGarden,
        'Garden Nudges',
        description: 'Reminders to tend to neglected subjects in your garden.',
        importance: Importance.low,
        playSound: false,
      ),
    ];

    for (final channel in channels) {
      await androidPlugin.createNotificationChannel(channel);
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  /// Builds [NotificationDetails] for the given [channelId].
  ///
  /// The channel must already exist (created in [_createChannels]).
  /// Importance and sound on Android 8+ are controlled by the channel, not
  /// the individual notification — these values are ignored after first channel
  /// creation. They are set here anyway so that the details object is
  /// self-consistent and correctly reflects each channel's intent.
  NotificationDetails _details(String channelId) {
    final isHighPriority = channelId == kChannelChildTimer;
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        _channelName(channelId),
        importance: isHighPriority
            ? Importance.high
            : Importance.defaultImportance,
        priority: isHighPriority ? Priority.high : Priority.defaultPriority,
      ),
    );
  }

  String _channelName(String channelId) {
    switch (channelId) {
      case kChannelParentProgress:
        return 'Child Progress';
      case kChannelParentAlerts:
        return 'Performance Alerts';
      case kChannelParentReports:
        return 'Weekly Reports';
      case kChannelChildTimer:
        return 'App Timer';
      case kChannelChildStreak:
        return 'Streak Reminders';
      case kChannelChildMilestones:
        return 'Milestones & Rewards';
      case kChannelChildGarden:
        return 'Garden Nudges';
      default:
        return channelId;
    }
  }

  void _assertInitialised() {
    assert(
      _initialised,
      'LocalNotificationService.init() must be called before using the service.',
    );
  }

  // ── Tap handler ─────────────────────────────────────────────────────────────

  /// Called when the user taps a notification while the app is in the
  /// foreground or background (not terminated).
  ///
  /// [response.payload] will contain whatever string was passed to [show] or
  /// [schedule]. Deep-link routing will be wired up in Phase 4 once the
  /// navigation targets are known.
  // Payload convention: "<screen>:<uid>", e.g. "STUDENT_PROFILE:uid123".
  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null) return;

    if (payload.startsWith('STUDENT_PROFILE:')) {
      navigatorKey.currentState?.pushNamed('/student-profile');
    }
  }
}
