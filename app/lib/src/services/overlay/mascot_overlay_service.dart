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

  String? _studentUid;
  Set<String> _monitoredPackages = {};
  StudentConfigModel _config = const StudentConfigModel();

  // ── Public API ─────────────────────────────────────────────────────────────

  Future<void> init({
    String? studentUid,
    List<AppRuleModel> rules = const [],
    StudentConfigModel config = const StudentConfigModel(),
  }) async {
    _studentUid = studentUid;
    _monitoredPackages = {for (var r in rules) r.packageName};
    _config = config;

    _overlayChannel.setMethodCallHandler(_handleOverlayCallback);
    _timerServiceChannel.setMethodCallHandler(_handleTimerServiceCallback);

    await _accessibilityChannel.invokeMethod('setMonitoredApps', {
      'apps': _monitoredPackages.toList(),
      'studentUid': _studentUid,
    });

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
    // NOTE: _resetAccessibilityState() is intentionally NOT called here.
    //
    // stop() is invoked when the parent logs in (student session ends), not
    // when the cooldown genuinely ends. Calling setBlocked(false) here would
    // write AppPrefs.KEY_IS_BLOCKED=false even while a cooldown is still
    // active, causing the accessibility service to stop blocking apps the next
    // time it reconnects (e.g. after an OEM process kill).
    //
    // The accessibility blocked state is only cleared by _onUnblocked(), which
    // fires when UsageTimerService confirms the cooldown has actually expired.
    _isBlocked = false;
    _overlayVisible = false;
    _usageNotificationVisible = false;
    _cooldownNotificationVisible = false;
    _remainingCooldownSeconds = 0;
    _totalUsageSeconds = 0;
    _quizDismissedForThisCooldown = false;
    _quizShownForThisCooldown = false;
    _quizController?.close();
    debugPrint('[MascotOverlayService] Stopped.');
  }

  Future<void> updateMonitoredApps(
    List<AppRuleModel> rules, {
    String? studentUid,
    StudentConfigModel config = const StudentConfigModel(),
  }) async {
    if (studentUid != null) {
      _studentUid = studentUid;
    }
    _monitoredPackages = {for (var r in rules) r.packageName};
    _config = config;

    try {
      await _accessibilityChannel.invokeMethod('setMonitoredApps', {
        'apps': _monitoredPackages.toList(),
        'studentUid': _studentUid,
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

  // ── Quiz state ─────────────────────────────────────────────────────────────

  /// True when the student explicitly dismissed the quiz (tapped away without
  /// finishing). Persisted to native SharedPreferences so it survives process
  /// death. Cleared when the cooldown ends or a fresh cooldown starts.
  bool _quizDismissedForThisCooldown = false;

  /// True once the quiz overlay has been pushed onto the navigator at least
  /// once during this cooldown. Persisted to native SharedPreferences.
  ///
  /// On cold relaunch we use this together with [_quizDismissedForThisCooldown]
  /// to decide what to do:
  ///   • dismissed=true              → suppress (student already said no)
  ///   • dismissed=false, shown=true → quiz was visible when the app was
  ///                                   killed — show it again
  ///   • dismissed=false, shown=false → normal first trigger this cooldown
  bool _quizShownForThisCooldown = false;

  /// Called by [StudentScreen] immediately after pushing the QuizOverlayPage.
  /// Records that the quiz was shown so a cold relaunch can re-show it if the
  /// student had not yet dismissed it.
  void markQuizShown() {
    _quizShownForThisCooldown = true;
    // Fire-and-forget — failure here is non-critical.
    _timerServiceChannel.invokeMethod('markQuizShown').catchError((_) {});
    debugPrint('[MascotOverlayService] Quiz marked as shown.');
  }

  /// Called by [StudentScreen] when the QuizOverlayPage pops without the
  /// student completing it. Suppresses re-triggers for this cooldown cycle.
  void markQuizDismissed() {
    _quizDismissedForThisCooldown = true;
    _quizShownForThisCooldown =
        true; // implied — can only dismiss after showing
    _timerServiceChannel
        .invokeMethod('setQuizDismissed', {'dismissed': true})
        .catchError((_) {});
    debugPrint(
      '[MascotOverlayService] Quiz dismissed — suppressing re-triggers '
      'until cooldown ends.',
    );
  }

  /// Called by [StudentScreen] when the QuizOverlayPage pops after the student
  /// successfully completes the quiz. Clears both flags.
  void markQuizCompleted() {
    _quizDismissedForThisCooldown = false;
    _quizShownForThisCooldown = false;
    _timerServiceChannel
        .invokeMethod('setQuizDismissed', {'dismissed': false})
        .catchError((_) {});
    debugPrint('[MascotOverlayService] Quiz completed.');
  }

  /// True when the quiz should be shown:
  ///   • The student is in a cooldown AND
  ///   • The student has NOT explicitly dismissed the quiz this cooldown.
  ///
  /// Note: [_quizShownForThisCooldown] alone does NOT suppress the quiz —
  /// only an explicit dismissal does. This ensures that if the app is killed
  /// while the quiz is open (without the student tapping dismiss), the quiz
  /// reappears on the next launch.
  bool get shouldShowQuiz => _isBlocked && !_quizDismissedForThisCooldown;

  // ── Native timer service helpers ───────────────────────────────────────────

  Future<void> _startNativeTimerService() async {
    try {
      await _timerServiceChannel.invokeMethod('startTimerService', {
        'studentUid': _studentUid,
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
        'studentUid': _studentUid,
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

      // ── Restore quiz state from native prefs ───────────────────────────────
      // These survive process death so we know exactly what state the quiz was
      // in when the app was last killed.
      _quizDismissedForThisCooldown =
          (state['quizDismissed'] as bool?) ?? false;
      _quizShownForThisCooldown = (state['quizShown'] as bool?) ?? false;

      if (_isBlocked) {
        // Tell the accessibility service the student is still blocked.
        // This is safe here because _syncStateFromNative reads the ground-truth
        // from native SharedPreferences (written by UsageTimerService.block()),
        // so we are confirming a block that native already persisted — not
        // introducing a new one.
        await _accessibilityChannel.invokeMethod('setBlocked', {
          'blocked': true,
        });

        // ── Cold-launch quiz recovery ──────────────────────────────────────
        //
        // Decision table:
        //   dismissed=true              → do NOT show (student said no)
        //   dismissed=false, shown=true → SHOW (quiz was open when app died)
        //   dismissed=false, shown=false → SHOW (normal first trigger)
        //
        // In all "SHOW" cases we fire the quiz trigger as normal.
        if (!_quizDismissedForThisCooldown) {
          debugPrint(
            '[MascotOverlayService] Cold-launch recovery: blocked=true, '
            'dismissed=false (shown=$_quizShownForThisCooldown) — '
            'firing quiz trigger.',
          );
          if (_quizStream.hasListener) {
            _quizStream.add(null);
          } else {
            _pendingQuizTrigger = true;
          }
        } else {
          debugPrint(
            '[MascotOverlayService] Cold-launch recovery: quiz already '
            'dismissed for this cooldown — skipping trigger.',
          );
        }
      }

      debugPrint(
        '[MascotOverlayService] Restored state from native — '
        'usage: $_totalUsageSeconds s, blocked: $_isBlocked, '
        'cooldown remaining: $_remainingCooldownSeconds s, '
        'quizDismissed: $_quizDismissedForThisCooldown, '
        'quizShown: $_quizShownForThisCooldown.',
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
        if (!_quizDismissedForThisCooldown) {
          _quizStream.add(null);
        }
        break;
    }
  }

  // ── Limit-reached handling ─────────────────────────────────────────────────

  Future<void> _onLimitReached() async {
    if (_isBlocked) {
      debugPrint(
        '[MascotOverlayService] _onLimitReached called while already blocked — ignoring duplicate.',
      );
      return;
    }

    _isBlocked = true;
    _quizDismissedForThisCooldown =
        false; // fresh cooldown — reset dismiss flag
    _quizShownForThisCooldown = false; // fresh cooldown — quiz not yet shown
    _mascotState = MascotState.idle;
    debugPrint(
      '[MascotOverlayService] Limit reached — '
      'total usage: ${_totalUsageSeconds}s. Starting cooldown.',
    );

    await _hideUsageNotification();

    try {
      await _accessibilityChannel.invokeMethod('setBlocked', {'blocked': true});
    } catch (_) {}

    try {
      await _overlayChannel.invokeMethod('bringAppToForeground');
    } catch (_) {}

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
    _quizDismissedForThisCooldown = false; // cooldown over — always reset
    _quizShownForThisCooldown = false; // cooldown over — always reset

    await _hideUsageNotification();
    await _hideCooldownNotification();
    await _hideOverlayNative();
    // _resetAccessibilityState() is safe here and only here: the cooldown has
    // genuinely ended (confirmed by UsageTimerService), so clearing the blocked
    // flag in both memory and AppPrefs is correct.
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
