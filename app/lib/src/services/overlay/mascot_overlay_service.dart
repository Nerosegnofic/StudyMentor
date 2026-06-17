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
  bool _isBlocked = false;
  bool _overlayVisible = false;
  bool _usageNotificationVisible = false;
  bool _cooldownNotificationVisible = false;
  MascotState _mascotState = MascotState.idle;

  int _remainingCooldownSeconds = 0;
  int _totalUsageSeconds = 0;

  // ── Cumulative daily free time (monitored-app usage across windows) ─────────
  //
  // [_totalUsageSeconds] is reset to 0 by the native service on every cooldown
  // window end, so it only reflects the current window. To show how much free
  // app-time the student has earned across the whole day, we accumulate the
  // per-window deltas here and persist them (date-keyed) so they survive
  // restarts and reset at local midnight.
  int _dailyFreeTimeSeconds = 0;
  int _lastWindowUsage = 0;
  bool _usageBaselineSet = false;
  String? _freeTimeDate;

  // ── Student UID ────────────────────────────────────────────────────────────

  /// The UID of the student whose timer is currently active.
  /// Passed to the native timer service so it can detect account switches
  /// and reset usage/cooldown state automatically.
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

  /// Initialises the overlay service for [studentUid].
  ///
  /// [studentUid] is forwarded to the native timer service on every
  /// [startTimerService] / [updateTimerConfig] call so that the service can
  /// detect when a different student logs in and reset usage/cooldown state
  /// automatically — preventing timer state from leaking across accounts.
  Future<void> init({
    required String studentUid,
    List<AppRuleModel> rules = const [],
    StudentConfigModel config = const StudentConfigModel(),
  }) async {
    _studentUid = studentUid;
    _monitoredPackages = {for (var r in rules) if (!r.isPaused) r.packageName};
    _config = config;

    // Save the paused packages to SharedPreferences so the native side can also see them independently
    if (_studentUid != null && _studentUid!.isNotEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final pausedPackages = rules.where((r) => r.isPaused).map((r) => r.packageName).toList();
        await prefs.setStringList('paused_packages_$_studentUid', pausedPackages);
      } catch (e) {
        debugPrint('[MascotOverlayService] Failed to save paused packages to prefs in init: $e');
      }
    }

    _overlayChannel.setMethodCallHandler(_handleOverlayCallback);
    _timerServiceChannel.setMethodCallHandler(_handleTimerServiceCallback);

    await _accessibilityChannel.invokeMethod('setMonitoredApps', {
      'apps': _monitoredPackages.toList(),
      'studentUid': _studentUid,
    });

    await _loadDailyFreeTime();
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

    // App restrictions must be tied to the active logged-in session: once
    // this student logs out, lift any cooldown blocking and clear the
    // monitored-app list so neither bleeds into whichever student (if any)
    // logs in next. The per-student cooldown progress itself is left intact
    // in native prefs so this student's cooldown resumes correctly if they
    // log back in.
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

    _isBlocked = false;
    _overlayVisible = false;
    _usageNotificationVisible = false;
    _cooldownNotificationVisible = false;
    _remainingCooldownSeconds = 0;
    _totalUsageSeconds = 0;
    // Reset the daily free-time tracker so the next student loads their own
    // (persisted) total rather than inheriting this session's in-memory state.
    _dailyFreeTimeSeconds = 0;
    _lastWindowUsage = 0;
    _usageBaselineSet = false;
    _freeTimeDate = null;
    _studentUid = null;
    _quizDismissedForThisCooldown = false;
    _quizShownForThisCooldown = false;
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

    // Save the paused packages to SharedPreferences so the native side can also see them independently
    if (_studentUid != null && _studentUid!.isNotEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final pausedPackages = rules.where((r) => r.isPaused).map((r) => r.packageName).toList();
        await prefs.setStringList('paused_packages_$_studentUid', pausedPackages);
      } catch (e) {
        debugPrint('[MascotOverlayService] Failed to save paused packages to prefs: $e');
      }
    }

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

  /// Cumulative monitored-app usage for today, summed across cooldown windows
  /// (unlike [totalUsageSeconds], which the native service resets each window).
  int get dailyFreeTimeSeconds => _dailyFreeTimeSeconds;
  MascotState get currentState => _mascotState;
  StudentConfigModel get config => _config;

  // ── Daily free-time accumulator ────────────────────────────────────────────

  String _todayKey() {
    final now = DateTime.now();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '${now.year}-$m-$d';
  }

  String get _freeTimeKey => 'free_time_${_studentUid ?? 'unknown'}';
  String get _freeTimeDateKey => 'free_time_date_${_studentUid ?? 'unknown'}';

  Future<void> _loadDailyFreeTime() async {
    final today = _todayKey();
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedDate = prefs.getString(_freeTimeDateKey);
      if (storedDate == today) {
        _dailyFreeTimeSeconds = prefs.getInt(_freeTimeKey) ?? 0;
      } else {
        _dailyFreeTimeSeconds = 0;
        await prefs.setString(_freeTimeDateKey, today);
        await prefs.setInt(_freeTimeKey, 0);
      }
    } catch (e) {
      debugPrint('[MascotOverlayService] load daily free time error: $e');
      _dailyFreeTimeSeconds = 0;
    }
    _freeTimeDate = today;
  }

  Future<void> _persistDailyFreeTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_freeTimeDateKey, _freeTimeDate ?? _todayKey());
      await prefs.setInt(_freeTimeKey, _dailyFreeTimeSeconds);
    } catch (_) {/* best-effort; recomputed from deltas next tick */}
  }

  /// Ingests a usage value reported by the native timer, accumulating the
  /// cumulative daily total across cooldown-window resets.
  void _applyUsage(int newUsage) {
    // Midnight rollover → start a fresh day.
    final today = _todayKey();
    if (_freeTimeDate != today) {
      _freeTimeDate = today;
      _dailyFreeTimeSeconds = 0;
      _persistDailyFreeTime();
    }

    // First reading after launch: align the tracker without accumulating, so a
    // restart mid-window doesn't double-count usage already in the daily total.
    if (!_usageBaselineSet) {
      _usageBaselineSet = true;
      _lastWindowUsage = newUsage;
      _totalUsageSeconds = newUsage;
      return;
    }

    if (newUsage > _lastWindowUsage) {
      _dailyFreeTimeSeconds += newUsage - _lastWindowUsage;
      _persistDailyFreeTime();
    }
    // A drop means the native window reset on cooldown end; those seconds were
    // already counted, so realign without subtracting.
    _lastWindowUsage = newUsage;
    _totalUsageSeconds = newUsage;
  }

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
        'studentUid': _studentUid ?? '',
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
        'studentUid': _studentUid ?? '',
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
      // Pass our own UID so the native side returns THIS student's saved
      // cooldown/usage state rather than whatever student was last active —
      // the native "active student" pointer is only updated once
      // startTimerService() runs (in start(), after this call).
      final state = await _timerServiceChannel.invokeMapMethod<String, dynamic>(
        'getTimerState',
        {'studentUid': _studentUid ?? ''},
      );
      if (state == null) return;

      _applyUsage((state['totalUsage'] as int?) ?? 0);
      _isBlocked = (state['isBlocked'] as bool?) ?? false;
      _remainingCooldownSeconds = (state['cooldownRemaining'] as int?) ?? 0;

      // ── Restore quiz state from native prefs ───────────────────────────────
      // These survive process death so we know exactly what state the quiz was
      // in when the app was last killed.
      _quizDismissedForThisCooldown =
          (state['quizDismissed'] as bool?) ?? false;
      _quizShownForThisCooldown = (state['quizShown'] as bool?) ?? false;

      // ── FIX: unconditionally sync the accessibility blocked state ──────────
      //
      // Previously this call was inside `if (_isBlocked)` and only ever sent
      // setBlocked(true). That meant switching to an account that is NOT in
      // cooldown left the accessibility service's isBlocked flag stale from
      // the previous account's session, causing all restricted apps to remain
      // blocked for the newly logged-in account.
      //
      // By moving the call outside the guard and passing _isBlocked directly,
      // we always clear the stale flag when the incoming account is free, and
      // still set it correctly when the incoming account is in cooldown.
      await _accessibilityChannel.invokeMethod('setBlocked', {
        'blocked': _isBlocked,
      });

      if (_isBlocked) {
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
        _applyUsage((args['totalUsage'] as int?) ?? 0);
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
