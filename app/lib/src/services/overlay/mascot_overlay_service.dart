import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'mascot_state.dart';
import '../../domain/models/app_config_model.dart';
import '../../services/settings_service.dart';

class MascotOverlayService {
  MascotOverlayService._();
  static final MascotOverlayService instance = MascotOverlayService._();

  // ── Channels ───────────────────────────────────────────────────────────────

  static const _overlayChannel = MethodChannel(
    'com.example.studymentor/overlay',
  );
  static const _accessibilityChannel = MethodChannel(
    'com.example.studymentor/accessibility',
  );
  static const _timerServiceChannel = MethodChannel(
    'com.example.studymentor/timer_service',
  );

  // ── Mirrored state ─────────────────────────────────────────────────────────

  bool _running = false;
  bool _isBlocked = false;
  bool _overlayVisible = false;
  bool _usageNotificationVisible = false;
  bool _cooldownNotificationVisible = false;
  MascotState _mascotState = MascotState.idle;

  int _remainingCooldownSeconds = 0;
  int _totalUsageSeconds = 0;

  // ── Quiz trigger stream ────────────────────────────────────────────────────

  // Re-created lazily so it is never closed when a cold-launch onLimitReached
  // arrives before init() has been called.
  bool _pendingQuizTrigger = false;
  StreamController<void>? _quizController;

  StreamController<void> get _quizStream {
    if (_quizController == null || _quizController!.isClosed) {
      _quizController = StreamController<void>.broadcast();
    }
    return _quizController!;
  }

  Stream<void> get quizRequested => _quizStream.stream;

  void triggerQuizForTesting() {
    debugPrint('[MascotOverlayService] Quiz trigger (test).');
    _quizStream.add(null);
  }

  /// Subscribes [onQuiz] to the quiz-trigger stream.
  /// If a trigger fired before this call (cold-launch scenario), it is
  /// delivered immediately via a microtask.
  StreamSubscription<void> listenForQuiz(VoidCallback onQuiz) {
    if (_pendingQuizTrigger) {
      _pendingQuizTrigger = false;
      Future.microtask(onQuiz);
    }
    return quizRequested.listen((_) => onQuiz());
  }

  // ── Settings ───────────────────────────────────────────────────────────────

  SettingsService? _settingsService;

  Future<SettingsService> _getSettings() async {
    _settingsService ??= await SettingsService.create();
    return _settingsService!;
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

    _overlayChannel.setMethodCallHandler(_handleOverlayCallback);
    _timerServiceChannel.setMethodCallHandler(_handleTimerServiceCallback);

    await _accessibilityChannel.invokeMethod('setMonitoredApps', {
      'apps': _monitoredPackages.toList(),
    });

    // Permissions are handled exclusively by PermissionGateScreen before
    // this method is ever called. Do NOT request permissions here.

    await _syncStateFromNative();

    final settings = await _getSettings();
    await setTimerNotificationEnabled(settings.timerNotificationEnabled);
    await setCooldownNotificationEnabled(settings.cooldownNotificationEnabled);
  }

  void start() {
    if (_running) return;
    _running = true;
    _startNativeTimerService();
    debugPrint('[MascotOverlayService] Started (native timer service).');
  }

  Future<void> stop() async {
    _running = false;
    await _stopNativeTimerService();
    await _hideUsageNotification();
    await _hideCooldownNotification();
    await _hideOverlayNative();
    await _resetAccessibilityState();
    _isBlocked = false;
    _overlayVisible = false;
    _usageNotificationVisible = false;
    _cooldownNotificationVisible = false;
    _remainingCooldownSeconds = 0;
    _totalUsageSeconds = 0;
    // Close the existing controller so listeners are cleaned up, but do NOT
    // set _quizController to null — _quizStream will lazily create a new one
    // if needed (e.g. for a subsequent session).
    _quizController?.close();
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
        '[MascotOverlayService] updateMonitoredApps accessibility error: ${e.message}',
      );
    }

    if (_running) {
      await _updateNativeTimerConfig();
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
  bool get isCooldownNotificationVisible => _cooldownNotificationVisible;
  int get remainingSeconds => _remainingCooldownSeconds;
  int get totalUsageSeconds => _totalUsageSeconds;
  MascotState get currentState => _mascotState;
  StudentConfigModel get config => _config;

  // ── Native timer service helpers ───────────────────────────────────────────

  Future<void> _startNativeTimerService() async {
    try {
      await _timerServiceChannel.invokeMethod('startTimerService', {
        'monitoredApps': _monitoredPackages.toList(),
        'usageLimitSecs': _usageLimitSecondsFromConfig(),
        'cooldownLimitSecs': _cooldownLimitSecondsFromConfig(),
      });
    } on PlatformException catch (e) {
      debugPrint(
        '[MascotOverlayService] startTimerService error: ${e.message}',
      );
    }
  }

  Future<void> _stopNativeTimerService() async {
    try {
      await _timerServiceChannel.invokeMethod('stopTimerService');
    } on PlatformException catch (e) {
      debugPrint('[MascotOverlayService] stopTimerService error: ${e.message}');
    }
  }

  Future<void> _updateNativeTimerConfig() async {
    try {
      await _timerServiceChannel.invokeMethod('updateTimerConfig', {
        'monitoredApps': _monitoredPackages.toList(),
        'usageLimitSecs': _usageLimitSecondsFromConfig(),
        'cooldownLimitSecs': _cooldownLimitSecondsFromConfig(),
      });
    } on PlatformException catch (e) {
      debugPrint(
        '[MascotOverlayService] updateTimerConfig error: ${e.message}',
      );
    }
  }

  Future<void> _syncStateFromNative() async {
    try {
      final state = await _timerServiceChannel.invokeMapMethod<String, dynamic>(
        'getTimerState',
      );
      if (state == null) return;

      _totalUsageSeconds = (state['totalUsage'] as int?) ?? 0;
      _isBlocked = (state['isBlocked'] as bool?) ?? false;
      _remainingCooldownSeconds = (state['cooldownRemaining'] as int?) ?? 0;

      if (_isBlocked) {
        await _accessibilityChannel.invokeMethod('setBlocked', {
          'blocked': true,
        });

        // ── Cold-launch recovery ────────────────────────────────────────────
        // When the app is fully killed and the usage limit is hit,
        // UsageTimerService.block() starts MainActivity with
        // EXTRA_QUIZ_ON_LAUNCH. MainActivity.onFlutterUiDisplayed() fires
        // dispatchQuizOnLaunch() on the very first frame — which is the auth
        // loading spinner. At that point StudentScreen.initState() has not
        // run yet, so the timer-service MethodChannel handler is not
        // registered and the invokeMethod("onLimitReached") call is silently
        // dropped.
        //
        // By the time _syncStateFromNative() is awaited, listenForQuiz() has
        // already been called synchronously in StudentScreen.initState()
        // (it executes before init()'s first await suspends the isolate), so
        // the broadcast stream has at least one active listener. Firing the
        // quiz trigger here reliably covers the fully-killed-app case without
        // risk of double-firing on warm resume (where this path is never
        // reached because StudentScreen is never torn down).
        if (_quizStream.hasListener) {
          _quizStream.add(null);
        } else {
          // Listener hasn't subscribed yet (shouldn't happen in normal flow,
          // but guard with the pending-trigger mechanism just in case).
          _pendingQuizTrigger = true;
        }
      }

      debugPrint(
        '[MascotOverlayService] Restored state from native — '
        'usage: $_totalUsageSeconds s, blocked: $_isBlocked, '
        'cooldown remaining: $_remainingCooldownSeconds s.',
      );
    } on PlatformException catch (e) {
      debugPrint('[MascotOverlayService] getTimerState error: ${e.message}');
    }
  }

  Future<void> setTimerNotificationEnabled(bool enabled) async {
    try {
      await _timerServiceChannel.invokeMethod('setTimerNotificationEnabled', {
        'enabled': enabled,
      });
    } on PlatformException catch (e) {
      debugPrint(
        '[MascotOverlayService] setTimerNotificationEnabled error: ${e.message}',
      );
    }
  }

  Future<void> setCooldownNotificationEnabled(bool enabled) async {
    try {
      await _timerServiceChannel.invokeMethod(
        'setCooldownNotificationEnabled',
        {'enabled': enabled},
      );
    } on PlatformException catch (e) {
      debugPrint(
        '[MascotOverlayService] setCooldownNotificationEnabled error: ${e.message}',
      );
    }
  }

  int _usageLimitSecondsFromConfig() =>
      (_config.usageHours * 3600) + (_config.usageMinutes * 60);

  int _cooldownLimitSecondsFromConfig() =>
      (_config.cooldownHours * 3600) + (_config.cooldownMinutes * 60);

  // ── Native → Dart callback: timer service ─────────────────────────────────

  Future<dynamic> _handleTimerServiceCallback(MethodCall call) async {
    switch (call.method) {
      case 'onTimerTick':
        final args = call.arguments as Map<dynamic, dynamic>;
        _totalUsageSeconds = (args['totalUsage'] as int?) ?? 0;
        _isBlocked = (args['isBlocked'] as bool?) ?? false;
        _remainingCooldownSeconds = (args['cooldownRemaining'] as int?) ?? 0;
        break;

      case 'onLimitReached':
        // This may arrive from MainActivity.dispatchQuizOnLaunch() on a
        // cold-launch (app was fully closed when the limit was hit). We must
        // handle it regardless of whether start() has been called yet — the
        // native timer service is already running; we just need to update
        // Dart-side state and fire the quiz stream.
        await _onLimitReached();
        break;

      case 'onThresholdAlert':
        final args = call.arguments as Map<dynamic, dynamic>;
        final remaining = (args['remainingSeconds'] as int?) ?? 0;
        final isCooldown = (args['isCooldown'] as bool?) ?? false;
        await _fireThresholdNotification(remaining, isCooldown: isCooldown);
        break;

      case 'onUnblocked':
        await _onUnblocked();
        break;
    }
  }

  // ── Native → Dart callback: overlay ───────────────────────────────────────

  Future<dynamic> _handleOverlayCallback(MethodCall call) async {
    switch (call.method) {
      case 'onOverlayDismissed':
        if (_isBlocked) {
          _overlayVisible = false;
          debugPrint(
            '[MascotOverlayService] Overlay dismissed — '
            'countdown continues ($_remainingCooldownSeconds s remaining).',
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
        _quizStream.add(null);
        break;
    }
  }

  // ── Limit-reached handling ─────────────────────────────────────────────────

  Future<void> _onLimitReached() async {
    _isBlocked = true;
    _mascotState = MascotState.idle;
    debugPrint(
      '[MascotOverlayService] Limit reached — '
      'total usage: ${_totalUsageSeconds}s. Starting cooldown.',
    );

    await _hideUsageNotification();

    try {
      await _accessibilityChannel.invokeMethod('setBlocked', {'blocked': true});
    } catch (_) {}

    // bringAppToForeground is a no-op here because we ARE the foreground —
    // MainActivity already launched us. Keep the call for the warm-resume
    // path where the app was backgrounded but not swiped away.
    try {
      await _overlayChannel.invokeMethod('bringAppToForeground');
    } catch (_) {}

    // If nobody is listening yet, park the trigger for listenForQuiz to pick
    // up on the cold-launch path.
    if (!_quizStream.hasListener) {
      _pendingQuizTrigger = true;
    }
    _quizStream.add(null);
  }

  Future<void> _onUnblocked() async {
    _isBlocked = false;
    _remainingCooldownSeconds = 0;
    _totalUsageSeconds = 0;
    _mascotState = MascotState.idle;

    await _hideUsageNotification();
    await _hideCooldownNotification();
    await _hideOverlayNative();
    await _resetAccessibilityState();
    debugPrint('[MascotOverlayService] Cooldown ended — student is free.');
  }

  // ── Threshold alert firing ─────────────────────────────────────────────────

  Future<void> _fireThresholdNotification(
    int remainingSeconds, {
    required bool isCooldown,
  }) async {
    try {
      if (isCooldown) {
        await _overlayChannel.invokeMethod('showCooldownThresholdAlert', {
          'remainingSeconds': remainingSeconds,
        });
      } else {
        await _overlayChannel.invokeMethod('showThresholdAlert', {
          'remainingSeconds': remainingSeconds,
        });
      }
      debugPrint(
        '[MascotOverlayService] Threshold alert fired: '
        '${remainingSeconds}s remaining (cooldown: $isCooldown).',
      );
    } on PlatformException catch (e) {
      debugPrint('[MascotOverlayService] threshold alert error: ${e.message}');
    }
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

  Future<void> _hideUsageNotification() async {
    if (!_usageNotificationVisible) return;
    _usageNotificationVisible = false;
    try {
      await _overlayChannel.invokeMethod('hideUsageTimer');
    } on PlatformException catch (e) {
      debugPrint('[MascotOverlayService] hideUsageTimer error: ${e.message}');
    }
  }

  // ── Cooldown notification helpers ──────────────────────────────────────────

  Future<void> _hideCooldownNotification() async {
    if (!_cooldownNotificationVisible) return;
    _cooldownNotificationVisible = false;
    try {
      await _overlayChannel.invokeMethod('hideCooldownTimer');
    } on PlatformException catch (e) {
      debugPrint(
        '[MascotOverlayService] hideCooldownTimer error: ${e.message}',
      );
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
}
