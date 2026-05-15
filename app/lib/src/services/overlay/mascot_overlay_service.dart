import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'mascot_state.dart';
import '../../domain/models/app_config_model.dart';

class MascotOverlayService {
  MascotOverlayService._();
  static final MascotOverlayService instance = MascotOverlayService._();

  static const _overlayChannel = MethodChannel(
    'com.example.studymentor/overlay',
  );
  static const _usageChannel = MethodChannel(
    'com.example.studymentor/usage_stats',
  );
  static const _accessibilityChannel = MethodChannel(
    'com.example.studymentor/accessibility',
  );

  // ── State ──────────────────────────────────────────────────────────────────
  bool _running = false;
  bool _isBlocked = false;
  bool _overlayVisible = false;
  bool _usageTimerVisible = false;
  MascotState _mascotState = MascotState.idle;

  // ── Countdown ──────────────────────────────────────────────────────────────
  Timer? _countdownTimer;
  int _remainingSeconds = 0;

  // ── Polling ────────────────────────────────────────────────────────────────
  Timer? _pollTimer;

  // ── Shared usage counter ───────────────────────────────────────────────────
  // Accumulates seconds spent across ALL restricted apps combined.
  // Resets to zero only when the cooldown ends.
  int _totalUsageSeconds = 0;

  // ── Quiz trigger stream ────────────────────────────────────────────────────
  // Fires whenever the native overlay's "Start Quiz" button is tapped.
  // StudentScreen subscribes to this and pushes the quiz route.
  final StreamController<void> _quizController =
      StreamController<void>.broadcast();

  /// Stream that emits once every time the overlay requests a quiz.
  Stream<void> get quizRequested => _quizController.stream;

  /// Dev helper — call from a button in debug builds to simulate the
  /// overlay triggering a quiz without a real restricted-app session.
  void triggerQuizForTesting() {
    debugPrint('[MascotOverlayService] Quiz trigger (test).');
    _quizController.add(null);
  }

  // ── Config ─────────────────────────────────────────────────────────────────
  Set<String> _monitoredPackages = {};
  StudentConfigModel _config = const StudentConfigModel();
  String? _currentMonitoredPackage; // tracks foreground restricted app

  // ── Per-app timer dismissal state ─────────────────────────────────────────
  // When the user drags the usage timer away, we record which package they
  // dismissed it for. The timer will not reappear while that same app remains
  // in the foreground. It resets when the user fully exits and relaunches the
  // app (i.e. when foreground changes away from it, then back to it, or when
  // a different restricted app is foregrounded).
  String? _timerDismissedForPackage;

  // Tracks whether we were inside a restricted app on the previous poll tick.
  // Used to detect a genuine "exit + re-entry" cycle.
  String? _previousRestrictedForeground;

  // ── Public API ─────────────────────────────────────────────────────────────

  Future<void> init({
    List<AppRuleModel> rules = const [],
    StudentConfigModel config = const StudentConfigModel(),
  }) async {
    _monitoredPackages = {for (var r in rules) r.packageName};
    _config = config;
    _currentMonitoredPackage = null;

    _overlayChannel.setMethodCallHandler(_handleNativeCallback);

    await _accessibilityChannel.invokeMethod('setMonitoredApps', {
      'apps': _monitoredPackages.toList(),
    });

    await _requestOverlayPermission();
    await _requestUsageStatsPermission();
    await _requestAccessibilityPermissionIfNeeded();
  }

  void start() {
    if (_running) return;
    _running = true;
    _pollTimer = Timer.periodic(const Duration(seconds: 1), (_) => _poll());
    debugPrint('[MascotOverlayService] Started.');
  }

  Future<void> stop() async {
    _running = false;
    _pollTimer?.cancel();
    _countdownTimer?.cancel();
    await _hideUsageTimerNative();
    await _hideOverlayNative();
    await _resetAccessibilityState();
    _isBlocked = false;
    _overlayVisible = false;
    _usageTimerVisible = false;
    _remainingSeconds = 0;
    _totalUsageSeconds = 0;
    _quizController.close();
    _currentMonitoredPackage = null;
    _timerDismissedForPackage = null;
    _previousRestrictedForeground = null;
    debugPrint('[MascotOverlayService] Stopped.');
  }

  /// Updates the monitored-app list and global config at runtime without
  /// restarting the service.
  /// Called by [StudentScreen] whenever a fresh [AppRulesLoaded] state arrives.
  Future<void> updateMonitoredApps(
    List<AppRuleModel> rules, {
    StudentConfigModel config = const StudentConfigModel(),
  }) async {
    _monitoredPackages = {for (var r in rules) r.packageName};
    _config = config;
    try {
      await _accessibilityChannel.invokeMethod('setMonitoredApps', {
        'apps': _monitoredPackages.toList(),
      });
    } on PlatformException catch (e) {
      debugPrint(
        '[MascotOverlayService] updateMonitoredApps error: ${e.message}',
      );
    }
    debugPrint(
      '[MascotOverlayService] Monitored apps updated: '
      '${_monitoredPackages.toList()}',
    );
  }

  // ── Getters ────────────────────────────────────────────────────────────────
  bool get isRunning => _running;
  bool get isBlocked => _isBlocked;
  bool get isOverlayVisible => _overlayVisible;
  bool get isUsageTimerVisible => _usageTimerVisible;
  int get remainingSeconds => _remainingSeconds;
  int get totalUsageSeconds => _totalUsageSeconds;
  MascotState get currentState => _mascotState;
  StudentConfigModel get config => _config;

  // ── Native → Dart callback handler ────────────────────────────────────────

  Future<dynamic> _handleNativeCallback(MethodCall call) async {
    switch (call.method) {
      case 'onOverlayDismissed':
        // Student pressed back or home — overlay hides but countdown keeps running.
        if (_isBlocked) {
          _overlayVisible = false;
          debugPrint(
            '[MascotOverlayService] Overlay dismissed — '
            'countdown continues ($_remainingSeconds s remaining).',
          );
        }
        break;

      case 'onMonitoredAppIntercepted':
        // Accessibility service blocked a monitored app during the cooldown.
        // Re-show the overlay with the remaining countdown time.
        if (_isBlocked && !_overlayVisible) {
          debugPrint(
            '[MascotOverlayService] Monitored app intercepted — '
            're-showing overlay.',
          );
          await _showOverlayNative(remainingSeconds: _remainingSeconds);
        }
        break;

      case 'onQuizRequested':
        // The native overlay's "Start Quiz" button was tapped.
        // Signal Flutter to open the quiz screen.
        debugPrint('[MascotOverlayService] Native overlay requested quiz.');
        _quizController.add(null);
        break;

      case 'onUsageTimerDismissed':
        // User dragged the timer off-screen — record which app it was for so
        // we suppress the timer for the remainder of this app session.
        final dismissedPackage = _currentMonitoredPackage;
        if (dismissedPackage != null) {
          _timerDismissedForPackage = dismissedPackage;
          debugPrint(
            '[MascotOverlayService] Usage timer dismissed by user for '
            '$dismissedPackage — suppressed until app is re-opened.',
          );
        }
        _usageTimerVisible = false;
        break;
    }
  }

  // ── Warning phase ──────────────────────────────────────────────────────────

  Future<void> _startWarning() async {
    _isBlocked = true;
    _remainingSeconds =
        (_config.cooldownHours * 3600) + (_config.cooldownMinutes * 60);
    _mascotState = MascotState.idle;
    debugPrint(
      '[MascotOverlayService] Limit reached — '
      'total usage: ${_totalUsageSeconds}s. '
      'Starting cooldown: $_remainingSeconds s.',
    );

    // Clear any dismissal state — cooldown overlay takes full precedence.
    _timerDismissedForPackage = null;
    _previousRestrictedForeground = null;

    await _hideUsageTimerNative();
    await _accessibilityChannel.invokeMethod('setBlocked', {'blocked': true});
    await _showOverlayNative(remainingSeconds: _remainingSeconds);

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      _remainingSeconds--;
      debugPrint('[MascotOverlayService] Countdown: $_remainingSeconds s');

      if (_overlayVisible) {
        try {
          await _overlayChannel.invokeMethod('updateCountdown', {
            'remainingSeconds': _remainingSeconds,
          });
        } catch (_) {}
      }

      if (_remainingSeconds <= 0) {
        timer.cancel();
        await _unblock();
      }
    });
  }

  Future<void> _unblock() async {
    _countdownTimer?.cancel();
    _isBlocked = false;
    _remainingSeconds = 0;
    _totalUsageSeconds = 0; // reset the shared counter after cooldown
    _currentMonitoredPackage = null;
    _timerDismissedForPackage = null;
    _previousRestrictedForeground = null;
    _mascotState = MascotState.idle;

    await _hideUsageTimerNative();
    await _hideOverlayNative();
    await _resetAccessibilityState();
    debugPrint('[MascotOverlayService] Cooldown ended — student is free.');
  }

  // ── Native overlay helpers ─────────────────────────────────────────────────

  Future<void> _showOverlayNative({required int remainingSeconds}) async {
    _overlayVisible = true;
    _usageTimerVisible = false;
    try {
      await _overlayChannel.invokeMethod('showOverlay', {
        'remainingSeconds': remainingSeconds,
      });
    } on PlatformException catch (e) {
      _overlayVisible = false;
      debugPrint('[MascotOverlayService] showOverlay error: ${e.message}');
    }
  }

  Future<void> _hideOverlayNative() async {
    _overlayVisible = false;
    try {
      await _overlayChannel.invokeMethod('hideOverlay');
    } on PlatformException catch (e) {
      debugPrint('[MascotOverlayService] hideOverlay error: ${e.message}');
    }
  }

  Future<void> _showOrUpdateUsageTimerNative({
    required int remainingSeconds,
  }) async {
    try {
      if (_usageTimerVisible) {
        await _overlayChannel.invokeMethod('updateUsageTimer', {
          'remainingSeconds': remainingSeconds,
        });
      } else {
        await _overlayChannel.invokeMethod('showUsageTimer', {
          'remainingSeconds': remainingSeconds,
        });
        _usageTimerVisible = true;
      }
    } on PlatformException catch (e) {
      _usageTimerVisible = false;
      debugPrint('[MascotOverlayService] usage timer error: ${e.message}');
    }
  }

  Future<void> _hideUsageTimerNative() async {
    if (!_usageTimerVisible) return;
    _usageTimerVisible = false;
    try {
      await _overlayChannel.invokeMethod('hideUsageTimer');
    } on PlatformException catch (e) {
      debugPrint('[MascotOverlayService] hideUsageTimer error: ${e.message}');
    }
  }

  // ── Polling ────────────────────────────────────────────────────────────────

  Future<void> _poll() async {
    if (!_running) return;
    try {
      final foreground = await _usageChannel.invokeMethod<String>(
        'getForegroundApp',
      );

      // ── Track restricted-app exit so we can reset the dismissal state ──────
      // If the previous tick was inside a restricted app and this tick is not
      // (or is a *different* restricted app), the user has left that app.
      // When they return to it later it should be treated as a fresh session.
      final previousWasRestricted =
          _previousRestrictedForeground != null &&
          _monitoredPackages.contains(_previousRestrictedForeground!);

      final currentIsRestricted =
          foreground != null && _monitoredPackages.contains(foreground);

      if (previousWasRestricted) {
        if (!currentIsRestricted ||
            foreground != _previousRestrictedForeground) {
          // User exited (or switched away from) the previously tracked
          // restricted app — clear its dismissal lock so the timer reappears
          // if they re-open it.
          if (_timerDismissedForPackage == _previousRestrictedForeground) {
            debugPrint(
              '[MascotOverlayService] User left $_previousRestrictedForeground '
              '— dismissal state cleared.',
            );
            _timerDismissedForPackage = null;
          }
        }
      }

      // Update previous-restricted tracker.
      _previousRestrictedForeground = currentIsRestricted ? foreground : null;

      if (foreground == null) {
        await _hideUsageTimerNative();
        _currentMonitoredPackage = null;
        return;
      }

      if (_isBlocked) {
        // Fallback: if poll still sees a monitored app while overlay is hidden,
        // re-show it (primary path is via AccessibilityService).
        await _hideUsageTimerNative();
        if (_monitoredPackages.contains(foreground) && !_overlayVisible) {
          debugPrint(
            '[MascotOverlayService] Poll fallback: monitored app in foreground '
            '— re-showing overlay.',
          );
          await _showOverlayNative(remainingSeconds: _remainingSeconds);
        }
        return;
      }

      if (!_monitoredPackages.contains(foreground)) {
        // Not a restricted app — stop tracking and hide the usage timer.
        _currentMonitoredPackage = null;
        await _hideUsageTimerNative();
        return;
      }

      // ── Accumulate into the shared counter ─────────────────────────────
      // Every second spent in ANY restricted app adds to the same total.
      _currentMonitoredPackage = foreground;
      _totalUsageSeconds++;

      final thresholdSeconds =
          (_config.usageHours * 3600) + (_config.usageMinutes * 60);
      final remainingToBlock = (thresholdSeconds - _totalUsageSeconds).clamp(
        0,
        thresholdSeconds,
      );

      debugPrint(
        '[MascotOverlayService] Restricted app in foreground: $foreground — '
        'shared usage: ${_totalUsageSeconds}s / ${thresholdSeconds}s',
      );

      // ── Respect per-app timer dismissal ────────────────────────────────
      // Only suppress when the dismissed package matches the *current* app.
      // A different restricted app always gets its own fresh timer.
      if (_timerDismissedForPackage == foreground) {
        debugPrint(
          '[MascotOverlayService] Timer suppressed for $foreground '
          '(dismissed by user this session).',
        );
        // Still accumulate usage and trigger cooldown if limit is hit.
        if (_totalUsageSeconds >= thresholdSeconds) {
          await _startWarning();
        }
        return;
      }

      await _showOrUpdateUsageTimerNative(remainingSeconds: remainingToBlock);

      if (_totalUsageSeconds >= thresholdSeconds) {
        await _startWarning();
      }
    } on PlatformException catch (e) {
      debugPrint('[MascotOverlayService] poll error: ${e.message}');
    }
  }

  // ── Accessibility helpers ──────────────────────────────────────────────────

  Future<void> _resetAccessibilityState() async {
    try {
      await _accessibilityChannel.invokeMethod('setBlocked', {
        'blocked': false,
      });
    } on PlatformException catch (e) {
      debugPrint(
        '[MascotOverlayService] resetAccessibilityState error: ${e.message}',
      );
    }
  }

  // ── Permissions ────────────────────────────────────────────────────────────

  Future<void> _requestOverlayPermission() async {
    try {
      await _overlayChannel.invokeMethod('requestOverlayPermission');
    } on PlatformException catch (e) {
      debugPrint(
        '[MascotOverlayService] overlay permission error: ${e.message}',
      );
    }
  }

  Future<void> _requestUsageStatsPermission() async {
    try {
      await _usageChannel.invokeMethod('requestUsageStatsPermission');
    } on PlatformException catch (e) {
      debugPrint(
        '[MascotOverlayService] usage stats permission error: ${e.message}',
      );
    }
  }

  Future<void> _requestAccessibilityPermissionIfNeeded() async {
    try {
      final isEnabled = await _accessibilityChannel.invokeMethod<bool>(
        'isAccessibilityEnabled',
      );
      if (isEnabled != true) {
        await _accessibilityChannel.invokeMethod(
          'requestAccessibilityPermission',
        );
      } else {
        debugPrint('[MascotOverlayService] Accessibility already enabled.');
      }
    } on PlatformException catch (e) {
      debugPrint(
        '[MascotOverlayService] accessibility permission error: ${e.message}',
      );
    }
  }
}
