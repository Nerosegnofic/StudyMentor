import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'mascot_state.dart';
import '../../domain/models/app_config_model.dart';
import '../../services/settings_service.dart';

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
  bool _usageNotificationVisible = false;
  MascotState _mascotState = MascotState.idle;

  // ── Countdown ──────────────────────────────────────────────────────────────
  // No separate timer — the existing _pollTimer drives the countdown so there
  // is only ever one 1-second tick source and no cancellation races.
  int _remainingSeconds = 0;

  // Guard flag: prevents _startWarning from being entered twice on the same
  // tick if an awaited call yields and _poll fires again before it finishes.
  bool _warningStarting = false;

  // ── Polling ────────────────────────────────────────────────────────────────
  Timer? _pollTimer;

  // ── Shared usage counter ───────────────────────────────────────────────────
  int _totalUsageSeconds = 0;

  // ── Threshold alerts ───────────────────────────────────────────────────────
  /// Tracks which one-shot alert thresholds (in seconds) have already fired
  /// this session. Cleared on unblock or stop so they re-arm next session.
  final Set<int> _firedThresholds = {};

  // ── Quiz trigger stream ────────────────────────────────────────────────────
  final StreamController<void> _quizController =
      StreamController<void>.broadcast();

  Stream<void> get quizRequested => _quizController.stream;

  void triggerQuizForTesting() {
    debugPrint('[MascotOverlayService] Quiz trigger (test).');
    _quizController.add(null);
  }

  // ── Settings ───────────────────────────────────────────────────────────────
  // Lazily loaded; null until the first poll that needs it.
  SettingsService? _settingsService;

  Future<bool> _isTimerNotificationEnabled() async {
    _settingsService ??= await SettingsService.create();
    return _settingsService!.timerNotificationEnabled;
  }

  // ── Config ─────────────────────────────────────────────────────────────────
  Set<String> _monitoredPackages = {};
  StudentConfigModel _config = const StudentConfigModel();

  // ── Public API ─────────────────────────────────────────────────────────────

  Future<void> init({
    List<AppRuleModel> rules = const [],
    StudentConfigModel config = const StudentConfigModel(),
  }) async {
    _monitoredPackages = {for (var r in rules) r.packageName};
    _config = config;

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
    await _hideUsageNotification();
    await _hideOverlayNative();
    await _resetAccessibilityState();
    _isBlocked = false;
    _overlayVisible = false;
    _usageNotificationVisible = false;
    _remainingSeconds = 0;
    _totalUsageSeconds = 0;
    _warningStarting = false;
    _firedThresholds.clear();
    _quizController.close();
    debugPrint('[MascotOverlayService] Stopped.');
  }

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
  bool get isUsageNotificationVisible => _usageNotificationVisible;
  int get remainingSeconds => _remainingSeconds;
  int get totalUsageSeconds => _totalUsageSeconds;
  MascotState get currentState => _mascotState;
  StudentConfigModel get config => _config;

  // ── Native → Dart callback handler ────────────────────────────────────────

  Future<dynamic> _handleNativeCallback(MethodCall call) async {
    switch (call.method) {
      case 'onOverlayDismissed':
        if (_isBlocked) {
          _overlayVisible = false;
          debugPrint(
            '[MascotOverlayService] Overlay dismissed — '
            'countdown continues ($_remainingSeconds s remaining).',
          );
        }
        break;

      case 'onMonitoredAppIntercepted':
        if (_isBlocked) {
          debugPrint(
            '[MascotOverlayService] Monitored app intercepted — '
            'bringing Flutter quiz screen to foreground.',
          );
          try {
            await _overlayChannel.invokeMethod('bringAppToForeground');
          } catch (_) {}
        }
        break;

      case 'onQuizRequested':
        debugPrint('[MascotOverlayService] Native overlay requested quiz.');
        _quizController.add(null);
        break;
    }
  }

  // ── Warning phase ──────────────────────────────────────────────────────────

  Future<void> _startWarning() async {
    // Prevent a second _poll tick from entering here while we're still
    // awaiting native calls — otherwise the countdown gets reset mid-flight.
    if (_warningStarting) return;
    _warningStarting = true;

    _isBlocked = true;
    _remainingSeconds =
        (_config.cooldownHours * 3600) + (_config.cooldownMinutes * 60);
    _mascotState = MascotState.idle;
    debugPrint(
      '[MascotOverlayService] Limit reached — '
      'total usage: ${_totalUsageSeconds}s. '
      'Starting cooldown: $_remainingSeconds s.',
    );

    await _hideUsageNotification();
    await _accessibilityChannel.invokeMethod('setBlocked', {'blocked': true});

    try {
      await _overlayChannel.invokeMethod('bringAppToForeground');
    } catch (_) {}

    _quizController.add(null);

    // Countdown is now driven by _poll() — no separate timer needed.
    _warningStarting = false;
  }

  Future<void> _unblock() async {
    _isBlocked = false;
    _remainingSeconds = 0;
    _totalUsageSeconds = 0;
    _mascotState = MascotState.idle;
    _firedThresholds.clear();

    await _hideUsageNotification();
    await _hideOverlayNative();
    await _resetAccessibilityState();
    debugPrint('[MascotOverlayService] Cooldown ended — student is free.');
  }

  // ── Native overlay helpers ─────────────────────────────────────────────────

  Future<void> _hideOverlayNative() async {
    _overlayVisible = false;
    try {
      await _overlayChannel.invokeMethod('hideOverlay');
    } on PlatformException catch (e) {
      debugPrint('[MascotOverlayService] hideOverlay error: ${e.message}');
    }
  }

  // ── Usage notification helpers ─────────────────────────────────────────────

  /// Posts or updates the persistent usage-timer notification.
  /// Reads [SettingsService.timerNotificationEnabled] on every call so that
  /// toggling the setting takes effect on the very next poll tick — no restart
  /// required.
  Future<void> _showOrUpdateUsageNotification({
    required int remainingSeconds,
  }) async {
    final enabled = await _isTimerNotificationEnabled();
    if (!enabled) {
      // Setting was just turned off — cancel immediately if still visible.
      await _hideUsageNotification();
      return;
    }

    try {
      if (_usageNotificationVisible) {
        await _overlayChannel.invokeMethod('updateUsageTimer', {
          'remainingSeconds': remainingSeconds,
        });
      } else {
        await _overlayChannel.invokeMethod('showUsageTimer', {
          'remainingSeconds': remainingSeconds,
        });
        _usageNotificationVisible = true;
      }
    } on PlatformException catch (e) {
      debugPrint(
        '[MascotOverlayService] usage notification error: ${e.message}',
      );
    }
  }

  Future<void> _hideUsageNotification() async {
    if (!_usageNotificationVisible) return;
    _usageNotificationVisible = false;
    try {
      await _overlayChannel.invokeMethod('hideUsageTimer');
    } on PlatformException catch (e) {
      debugPrint('[MascotOverlayService] hideUsageTimer error: ${e.message}');
    }
  }

  // ── Threshold alert helpers ────────────────────────────────────────────────

  /// Fires a one-shot audible alert notification when [remainingToBlock] first
  /// crosses one of the defined thresholds (300 s, 60 s, 10 s).
  /// Each threshold fires at most once per session; [_firedThresholds] is
  /// cleared in [_unblock] and [stop] so alerts re-arm for the next session.
  Future<void> _maybeFireThresholdAlert(int remainingToBlock) async {
    const thresholds = [300, 60, 10];
    for (final threshold in thresholds) {
      if (!_firedThresholds.contains(threshold) &&
          remainingToBlock <= threshold &&
          remainingToBlock > 0) {
        _firedThresholds.add(threshold);
        try {
          await _overlayChannel.invokeMethod('showThresholdAlert', {
            'remainingSeconds': remainingToBlock,
          });
          debugPrint(
            '[MascotOverlayService] Threshold alert fired: '
            '${remainingToBlock}s remaining (threshold: ${threshold}s).',
          );
        } on PlatformException catch (e) {
          debugPrint(
            '[MascotOverlayService] showThresholdAlert error: ${e.message}',
          );
        }
        // Only fire one threshold per tick in case multiple are crossed at once.
        break;
      }
    }
  }

  // ── Polling ────────────────────────────────────────────────────────────────

  Future<void> _poll() async {
    if (!_running) return;
    try {
      final foreground = await _usageChannel.invokeMethod<String>(
        'getForegroundApp',
      );

      if (foreground == null) {
        await _hideUsageNotification();
        return;
      }

      if (_isBlocked) {
        await _hideUsageNotification();

        // Drive the cooldown countdown from the existing poll timer so there
        // is only one tick source and no Timer cancellation races.
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
          debugPrint('[MascotOverlayService] Countdown: $_remainingSeconds s');
          if (_remainingSeconds <= 0) {
            await _unblock();
            return;
          }
        }

        if (_monitoredPackages.contains(foreground)) {
          debugPrint(
            '[MascotOverlayService] Poll fallback: monitored app in foreground '
            '— bringing Flutter quiz screen to foreground.',
          );
          try {
            await _overlayChannel.invokeMethod('bringAppToForeground');
          } catch (_) {}
        }
        return;
      }

      if (!_monitoredPackages.contains(foreground)) {
        await _hideUsageNotification();
        return;
      }

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

      await _showOrUpdateUsageNotification(remainingSeconds: remainingToBlock);
      await _maybeFireThresholdAlert(remainingToBlock);

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
