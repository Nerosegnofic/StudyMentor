import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  // True while the native service is in cooldown countdown.
  bool _isInCooldown = false;
  bool _overlayVisible = false;
  bool _usageNotificationVisible = false;
  bool _cooldownNotificationVisible = false;
  MascotState _mascotState = MascotState.idle;

  int _remainingCooldownSeconds = 0;
  // Usage within the current reward window (counts up from 0, reported by native).
  int _totalUsageSeconds = 0;

  // ── Earned reward time ─────────────────────────────────────────────────────
  //
  // Accumulated seconds earned from quiz completions. Apps are accessible only
  // when this is > 0 AND not in cooldown. Each quiz adds the configured
  // per-quiz reward amount. Persisted per-student so it survives restarts.
  //
  // Key: 'reward_earned_<studentUid>'
  int _earnedRewardSeconds = 0;

  // ── Student UID ────────────────────────────────────────────────────────────

  String? _studentUid;

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
    required String studentUid,
    List<AppRuleModel> rules = const [],
    StudentConfigModel config = const StudentConfigModel(),
  }) async {
    _studentUid = studentUid;
    _monitoredPackages = {for (var r in rules) if (!r.isPaused) r.packageName};
    _config = config;

    if (_studentUid != null && _studentUid!.isNotEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final pausedPackages =
            rules.where((r) => r.isPaused).map((r) => r.packageName).toList();
        await prefs.setStringList('paused_packages_$_studentUid', pausedPackages);
      } catch (e) {
        debugPrint('[MascotOverlayService] Failed to save paused packages: $e');
      }
    }

    _overlayChannel.setMethodCallHandler(_handleOverlayCallback);
    _timerServiceChannel.setMethodCallHandler(_handleTimerServiceCallback);

    await _accessibilityChannel.invokeMethod('setMonitoredApps', {
      'apps': _monitoredPackages.toList(),
      'studentUid': _studentUid,
    });

    await _loadEarnedReward();
    await _syncStateFromNative();

    final settings = await _getSettings();
    await setTimerNotificationEnabled(settings.timerNotificationEnabled);
    await setCooldownNotificationEnabled(settings.cooldownNotificationEnabled);
  }

  void start() {
    if (_running) return;
    _running = true;
    // Always start the native timer service so it monitors foreground apps
    // throughout the entire student session, not only when reward time is
    // available. When _earnedRewardSeconds == 0 the tick loop runs but the
    // usageLimitSecs=0 condition prevents counting; the accessibility service
    // handles blocking independently. When _isInCooldown the service resumes
    // the countdown from persisted prefs.
    _startNativeTimerService();
    debugPrint('[MascotOverlayService] Started.');
  }

  Future<void> stop() async {
    _running = false;
    await _stopNativeTimerService();
    await _hideUsageNotification();
    await _hideCooldownNotification();
    await _hideOverlayNative();

    await _resetAccessibilityState();
    try {
      await _accessibilityChannel.invokeMethod('setMonitoredApps', {
        'apps': <String>[],
        'studentUid': '',
      });
    } on PlatformException catch (e) {
      debugPrint(
        '[MascotOverlayService] setMonitoredApps (clear on logout) error: ${e.message}',
      );
    }

    _isInCooldown = false;
    _overlayVisible = false;
    _usageNotificationVisible = false;
    _cooldownNotificationVisible = false;
    _remainingCooldownSeconds = 0;
    _totalUsageSeconds = 0;
    // Reset in-memory only — persisted value stays for next login.
    _earnedRewardSeconds = 0;
    _studentUid = null;
    _quizDismissedForThisCooldown = false;
    _quizController?.close();
    debugPrint('[MascotOverlayService] Stopped.');
  }

  Future<void> updateMonitoredApps(
    List<AppRuleModel> rules, {
    required String studentUid,
    StudentConfigModel config = const StudentConfigModel(),
  }) async {
    _studentUid = studentUid;
    _monitoredPackages = {for (var r in rules) if (!r.isPaused) r.packageName};
    _config = config;

    if (_studentUid != null && _studentUid!.isNotEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final pausedPackages =
            rules.where((r) => r.isPaused).map((r) => r.packageName).toList();
        await prefs.setStringList('paused_packages_$_studentUid', pausedPackages);
      } catch (e) {
        debugPrint('[MascotOverlayService] Failed to save paused packages: $e');
      }
    }

    try {
      await _accessibilityChannel.invokeMethod('setMonitoredApps', {
        'apps': _monitoredPackages.toList(),
        'studentUid': _studentUid,
      });
    } on PlatformException catch (e) {
      debugPrint(
        '[MascotOverlayService] updateMonitoredApps error: ${e.message}',
      );
    }

    if (_running && _earnedRewardSeconds > 0 && !_isInCooldown) {
      await _updateNativeTimerConfig();
    }

    debugPrint(
      '[MascotOverlayService] Monitored apps updated: '
      '${_monitoredPackages.toList()}',
    );
  }

  // ── Getters ────────────────────────────────────────────────────────────────

  bool get isRunning => _running;

  /// True when apps should be blocked — either in cooldown OR no earned reward
  /// time remaining.
  bool get isBlocked => _isInCooldown || _earnedRewardSeconds <= 0;

  /// True specifically when the cooldown countdown is running.
  bool get isInCooldown => _isInCooldown;

  bool get isOverlayVisible => _overlayVisible;
  bool get isUsageNotificationVisible => _usageNotificationVisible;
  bool get isCooldownNotificationVisible => _cooldownNotificationVisible;
  int get remainingSeconds => _remainingCooldownSeconds;
  int get totalUsageSeconds => _totalUsageSeconds;

  /// Total reward seconds currently in the student's bank (earned but not yet
  /// used up). Decreases as restricted apps are used; increases on quiz
  /// completion.
  int get earnedRewardSeconds => _earnedRewardSeconds;

  /// Remaining reward time = what was banked minus what has been used so far
  /// in the current window. During cooldown, apps are blocked so no usage
  /// can occur — return the full earned amount so the UI reflects accumulated
  /// quiz rewards correctly even while the cooldown timer is running.
  int get remainingRewardSeconds => _isInCooldown
      ? _earnedRewardSeconds.clamp(0, 1 << 31)
      : (_earnedRewardSeconds - _totalUsageSeconds).clamp(0, 1 << 31);

  MascotState get currentState => _mascotState;
  StudentConfigModel get config => _config;

  // ── Earned reward persistence ──────────────────────────────────────────────

  String get _earnedRewardKey => 'reward_earned_${_studentUid ?? 'unknown'}';

  Future<void> _loadEarnedReward() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _earnedRewardSeconds = prefs.getInt(_earnedRewardKey) ?? 0;
    } catch (e) {
      debugPrint('[MascotOverlayService] load earned reward error: $e');
      _earnedRewardSeconds = 0;
    }
    debugPrint(
      '[MascotOverlayService] Loaded earned reward: ${_earnedRewardSeconds}s',
    );
  }

  Future<void> _persistEarnedReward() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_earnedRewardKey, _earnedRewardSeconds);
    } catch (_) {}
  }

  // ── Quiz completion: add reward time ───────────────────────────────────────

  /// Called when the student successfully completes a quiz. Adds [perQuizSeconds]
  /// to their earned reward pool. If not currently in cooldown, the native timer
  /// limit is updated so the new time is immediately available.
  Future<void> addRewardTime(int perQuizSeconds) async {
    if (perQuizSeconds <= 0) return;

    _earnedRewardSeconds += perQuizSeconds;
    await _persistEarnedReward();

    debugPrint(
      '[MascotOverlayService] addRewardTime(${perQuizSeconds}s) → '
      'total earned: ${_earnedRewardSeconds}s',
    );

    if (!_isInCooldown) {
      // Unblock accessibility so apps become accessible.
      try {
        await _accessibilityChannel.invokeMethod('setBlocked', {'blocked': false});
      } catch (_) {}

      // Update the native timer so it uses the new earned total as the limit.
      if (_running) {
        await _updateNativeTimerConfig();
      } else {
        // Timer wasn't started yet (0 earned at login) — start it now.
        _running = true;
        _startNativeTimerService();
      }
    }
    // If in cooldown: just accumulate. When cooldown ends, _onUnblocked() will
    // start the timer with the earned total.
  }

  // ── Quiz state ─────────────────────────────────────────────────────────────

  bool _quizDismissedForThisCooldown = false;

  void markQuizShown() {
    _timerServiceChannel.invokeMethod('markQuizShown').catchError((_) {});
    debugPrint('[MascotOverlayService] Quiz marked as shown.');
  }

  void markQuizDismissed() {
    _quizDismissedForThisCooldown = true;
    _timerServiceChannel
        .invokeMethod('setQuizDismissed', {'dismissed': true})
        .catchError((_) {});
    debugPrint(
      '[MascotOverlayService] Quiz dismissed — suppressing re-triggers '
      'until next event.',
    );
  }

  void markQuizCompleted() {
    _quizDismissedForThisCooldown = false;
    _timerServiceChannel
        .invokeMethod('setQuizDismissed', {'dismissed': false})
        .catchError((_) {});
    debugPrint('[MascotOverlayService] Quiz completed.');
  }

  /// True when the quiz overlay should be shown: apps are blocked AND the
  /// student has not explicitly dismissed the quiz overlay this cycle.
  bool get shouldShowQuiz => isBlocked && !_quizDismissedForThisCooldown;

  // ── Native timer service helpers ───────────────────────────────────────────

  Future<void> _startNativeTimerService() async {
    try {
      await _timerServiceChannel.invokeMethod('startTimerService', {
        'studentUid': _studentUid ?? '',
        'monitoredApps': _monitoredPackages.toList(),
        'usageLimitSecs': _earnedRewardSeconds,
        'cooldownLimitSecs': _config.cooldownSeconds,
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
        'studentUid': _studentUid ?? '',
        'monitoredApps': _monitoredPackages.toList(),
        'usageLimitSecs': _earnedRewardSeconds,
        'cooldownLimitSecs': _config.cooldownSeconds,
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
        {'studentUid': _studentUid ?? ''},
      );
      if (state == null) return;

      _totalUsageSeconds = (state['totalUsage'] as int?) ?? 0;
      _isInCooldown = (state['isBlocked'] as bool?) ?? false;
      _remainingCooldownSeconds = (state['cooldownRemaining'] as int?) ?? 0;

      _quizDismissedForThisCooldown =
          (state['quizDismissed'] as bool?) ?? false;

      // Determine effective blocked state: in cooldown OR no earned reward.
      final effectivelyBlocked = isBlocked;
      await _accessibilityChannel.invokeMethod('setBlocked', {
        'blocked': effectivelyBlocked,
      });

      if (effectivelyBlocked && !_quizDismissedForThisCooldown) {
        debugPrint(
          '[MascotOverlayService] Cold-launch recovery: blocked=true, '
          'dismissed=false — firing quiz trigger.',
        );
        if (_quizStream.hasListener) {
          _quizStream.add(null);
        } else {
          _pendingQuizTrigger = true;
        }
      }

      debugPrint(
        '[MascotOverlayService] Restored state — '
        'usage: ${_totalUsageSeconds}s, earnedReward: ${_earnedRewardSeconds}s, '
        'inCooldown: $_isInCooldown, cooldownRem: ${_remainingCooldownSeconds}s, '
        'quizDismissed: $_quizDismissedForThisCooldown.',
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

  // ── Native → Dart callback: timer service ─────────────────────────────────

  Future<dynamic> _handleTimerServiceCallback(MethodCall call) async {
    switch (call.method) {
      case 'onTimerTick':
        final args = call.arguments as Map<dynamic, dynamic>;
        _totalUsageSeconds = (args['totalUsage'] as int?) ?? 0;
        _isInCooldown = (args['isBlocked'] as bool?) ?? false;
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
        if (isBlocked) {
          _overlayVisible = false;
          debugPrint(
            '[MascotOverlayService] Overlay dismissed — '
            'countdown continues ($_remainingCooldownSeconds s remaining).',
          );
        }
        break;

      case 'onMonitoredAppIntercepted':
        if (isBlocked) {
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

  // ── Reward time depleted ───────────────────────────────────────────────────

  Future<void> _onLimitReached() async {
    if (_isInCooldown) {
      debugPrint(
        '[MascotOverlayService] _onLimitReached called while already in cooldown — ignoring.',
      );
      return;
    }

    // Earned time is depleted; reset it.
    _earnedRewardSeconds = 0;
    _totalUsageSeconds = 0;
    await _persistEarnedReward();

    _isInCooldown = true;
    _quizDismissedForThisCooldown = false;
    _mascotState = MascotState.idle;
    debugPrint(
      '[MascotOverlayService] Reward time depleted — entering cooldown '
      '(${_config.cooldownSeconds}s).',
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

  // ── Cooldown ended ─────────────────────────────────────────────────────────

  Future<void> _onUnblocked() async {
    _isInCooldown = false;
    _remainingCooldownSeconds = 0;
    _totalUsageSeconds = 0;
    _mascotState = MascotState.idle;
    _quizDismissedForThisCooldown = false;

    await _hideCooldownNotification();
    await _hideOverlayNative();

    if (_earnedRewardSeconds > 0) {
      // Student earned time during cooldown → unblock and start timer.
      await _resetAccessibilityState();
      if (_running) {
        await _updateNativeTimerConfig();
      }
      debugPrint(
        '[MascotOverlayService] Cooldown ended — student has '
        '${_earnedRewardSeconds}s earned, unlocking.',
      );
    } else {
      // No earned time → stay blocked, show quiz.
      // unblock() on the native side wrote AppPrefs.KEY_IS_BLOCKED=false;
      // re-assert true so that the correct state survives a service restart.
      try {
        await _accessibilityChannel.invokeMethod('setBlocked', {'blocked': true});
      } catch (_) {}
      // Fire quiz so student can earn time.
      if (!_quizStream.hasListener) {
        _pendingQuizTrigger = true;
      }
      _quizStream.add(null);
      debugPrint(
        '[MascotOverlayService] Cooldown ended — no earned reward time. '
        'Staying blocked; showing quiz.',
      );
    }
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

  Future<void> _hideUsageNotification() async {
    if (!_usageNotificationVisible) return;
    _usageNotificationVisible = false;
    try {
      await _overlayChannel.invokeMethod('hideUsageTimer');
    } on PlatformException catch (e) {
      debugPrint('[MascotOverlayService] hideUsageTimer error: ${e.message}');
    }
  }

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
