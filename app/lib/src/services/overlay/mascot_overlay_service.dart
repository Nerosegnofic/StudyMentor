import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  // ── Ownership token ──────────────────────────────────────────────────────
  //
  // This service is a process-wide singleton, but StudentScreen (which drives
  // it) can be built more than once during the login/auth-settling render — the
  // old State is disposed AFTER the new one has already initialised the service.
  // That stale dispose used to call stop(), which pushes setBlocked(false) and
  // nulls _studentUid, clobbering the blocked state the live instance just set
  // (the "lock not active until I reopen the app" bug). Each StudentScreen
  // acquires a monotonically increasing token on init; dispose only tears the
  // service down if it is still the current owner, so a superseded instance can
  // never stop a session a newer instance owns.
  int _ownerToken = 0;

  /// Claims ownership of the singleton for the calling screen. Returns the token
  /// the caller must pass to [isOwner] before invoking [stop] on teardown.
  int acquireOwnership() {
    _ownerToken += 1;
    return _ownerToken;
  }

  /// True only if [token] is the most recently issued ownership token, i.e. no
  /// newer StudentScreen instance has taken over the singleton.
  bool isOwner(int token) => token == _ownerToken;

  // ── Mirrored state ─────────────────────────────────────────────────────────

  bool _running = false;
  // True while the native service is in cooldown countdown.
  bool _isInCooldown = false;
  bool _usageNotificationVisible = false;
  bool _cooldownNotificationVisible = false;

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

  // ── Cumulative daily reward total ──────────────────────────────────────────
  //
  // Sum of reward time granted by forced quizzes *today*, regardless of how much
  // was used or expired. Unlike _earnedRewardSeconds (the usable bank, capped at
  // one session) this accumulates across the whole day and resets at local
  // midnight. Drives the home banner headline ("You've earned X today").
  //
  // Keys: 'reward_today_<studentUid>' (int) and 'reward_today_date_<studentUid>'
  // (the 'yyyy-MM-dd' the total belongs to).
  int _dailyRewardSeconds = 0;
  String _dailyRewardDate = '';

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

  StreamSubscription<void> listenForQuiz(VoidCallback onQuiz) {
    if (_pendingQuizTrigger) {
      _pendingQuizTrigger = false;
      Future.microtask(onQuiz);
    }
    return _quizStream.stream.listen((_) => onQuiz());
  }

  // ── Quiz restore stream ────────────────────────────────────────────────────
  // Fired when the native side signals that a quiz session must be restored
  // (app was relaunched after task removal or device reboot while a quiz was
  // active). StudentScreen subscribes and re-opens QuizOverlayPage with the
  // saved session data from QuizLockService.

  bool _pendingQuizRestoreTrigger = false;
  StreamController<void>? _quizRestoreController;

  StreamController<void> get _quizRestoreStream {
    if (_quizRestoreController == null ||
        _quizRestoreController!.isClosed) {
      _quizRestoreController = StreamController<void>.broadcast();
    }
    return _quizRestoreController!;
  }

  StreamSubscription<void> listenForQuizRestore(VoidCallback onRestore) {
    if (_pendingQuizRestoreTrigger) {
      _pendingQuizRestoreTrigger = false;
      Future.microtask(onRestore);
    }
    return _quizRestoreStream.stream.listen((_) => onRestore());
  }

  // ── Settings ───────────────────────────────────────────────────────────────

  SettingsService? _settingsService;

  Future<SettingsService> _getSettings() async {
    _settingsService ??= await SettingsService.create(_studentUid!);
    return _settingsService!;
  }

  // ── Config ─────────────────────────────────────────────────────────────────

  Set<String> _monitoredPackages = {};
  // Tracked so updateMonitoredApps can no-op when the rule set is unchanged,
  // collapsing the redundant calls from the login/resume/AuthBloc paths.
  Set<String> _pausedPackages = {};
  StudentConfigModel _config = const StudentConfigModel();

  // ── Public API ─────────────────────────────────────────────────────────────

  Future<void> init({
    required String studentUid,
    List<AppRuleModel> rules = const [],
    StudentConfigModel config = const StudentConfigModel(),
  }) async {
    _studentUid = studentUid;
    _settingsService = null;
    _monitoredPackages = {for (var r in rules) if (!r.isPaused) r.packageName};
    _config = config;

    // When init is called without rules (the normal login path), seed the
    // monitored set from the locally-cached last-known config so app-blocking is
    // active IMMEDIATELY — before the network config fetch (which may fail/lag).
    // The fresh fetch (updateMonitoredApps) overwrites this when it lands. This is
    // what makes blocking resilient to a failed/slow getAppConfigForStudent.
    if (_monitoredPackages.isEmpty) {
      final cached = await _loadCachedMonitoredApps();
      if (cached.isNotEmpty) {
        _monitoredPackages = cached.toSet();
        debugPrint(
          '[MascotOverlayService] init: seeded ${_monitoredPackages.length} '
          'monitored apps from cache.',
        );
      }
    }

    // Only overwrite the persisted paused list when we actually have real rules;
    // never clobber the cache with the empty login-path rules.
    if (_studentUid != null && _studentUid!.isNotEmpty && rules.isNotEmpty) {
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
    debugPrint(
      '[MascotOverlayService] init: pushed ${_monitoredPackages.length} '
      'monitored apps to accessibility for $_studentUid.',
    );

    await _loadEarnedReward();
    await _loadDailyReward();

    // Fresh login: clear any stale "quiz dismissed" flag (it persists in native
    // prefs across sessions) so the forced quiz auto-shows when blocked instead of
    // staying suppressed from a previous session. Done BEFORE _syncStateFromNative
    // so its getTimerState read returns dismissed=false and fires the quiz.
    _quizDismissedForThisCooldown = false;
    try {
      await _timerServiceChannel
          .invokeMethod('setQuizDismissed', {'dismissed': false});
    } catch (_) {}

    await _syncStateFromNative();

    final settings = await _getSettings();
    await setTimerNotificationEnabled(settings.timerNotificationEnabled);
    await setCooldownNotificationEnabled(settings.cooldownNotificationEnabled);
  }

  /// Re-issues the native foreground-service start. Called on app resume to
  /// recover monitoring if an earlier start was refused by the OS (e.g. the app
  /// was briefly in the background during the login / permission flow, where a
  /// background foreground-service start is rejected on Android 12+). The native
  /// side treats a repeated ACTION_START for the same student as an idempotent
  /// config refresh, and now bails out cleanly instead of crashing if it still
  /// cannot enter the foreground.
  Future<void> ensureStarted() async {
    if (_studentUid == null || _studentUid!.isEmpty) return;
    _running = true;
    await _startNativeTimerService();
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
    _usageNotificationVisible = false;
    _cooldownNotificationVisible = false;
    _remainingCooldownSeconds = 0;
    _totalUsageSeconds = 0;
    // Reset in-memory only — persisted values stay for next login.
    _earnedRewardSeconds = 0;
    _dailyRewardSeconds = 0;
    _dailyRewardDate = '';
    _studentUid = null;
    _quizDismissedForThisCooldown = false;
    _quizController?.close();
    _quizRestoreController?.close();
    debugPrint('[MascotOverlayService] Stopped.');
  }

  Future<void> updateMonitoredApps(
    List<AppRuleModel> rules, {
    required String studentUid,
    StudentConfigModel config = const StudentConfigModel(),
  }) async {
    final newMonitored = {
      for (var r in rules)
        if (!r.isPaused) r.packageName,
    };
    final newPaused =
        rules.where((r) => r.isPaused).map((r) => r.packageName).toSet();

    // Idempotence: this is invoked from several sync paths (login refresh, resume
    // refresh, AuthBloc rule-load listeners), often with identical data. When the
    // rule set + student are unchanged, skip the channel pushes / native config /
    // persistence. The check is a cheap set comparison (~tens of short strings,
    // a few times per session) that AVOIDS the far costlier redundant
    // platform-channel round-trips + prefs write — a net performance win and the
    // thing that removes the resume-time churn.
    final unchanged = studentUid == _studentUid &&
        setEquals(newMonitored, _monitoredPackages) &&
        setEquals(newPaused, _pausedPackages);

    _studentUid = studentUid;
    _monitoredPackages = newMonitored;
    _pausedPackages = newPaused;
    _config = config;

    if (unchanged) {
      debugPrint(
        '[MascotOverlayService] updateMonitoredApps: unchanged '
        '(${newMonitored.length} apps) — skipping pushes.',
      );
      return;
    }

    if (_studentUid != null && _studentUid!.isNotEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(
            'paused_packages_$_studentUid', _pausedPackages.toList());
        // Cache the fresh monitored set so the next login can block immediately
        // and survive a failed/slow config fetch (overwrites the previous cache).
        await prefs.setStringList(_monitoredCacheKey, _monitoredPackages.toList());
      } catch (e) {
        debugPrint('[MascotOverlayService] Failed to save monitored/paused apps: $e');
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
      '[MascotOverlayService] updateMonitoredApps: ${_monitoredPackages.length} '
      'monitored apps (from network), cached: ${_monitoredPackages.toList()}',
    );
  }

  // ── Getters ────────────────────────────────────────────────────────────────

  /// True when apps should be blocked — either in cooldown OR no earned reward
  /// time remaining.
  bool get isBlocked => _isInCooldown || _earnedRewardSeconds <= 0;

  /// True specifically when the cooldown countdown is running.
  bool get isInCooldown => _isInCooldown;

  int get remainingSeconds => _remainingCooldownSeconds;

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

  /// Cumulative reward time earned from forced quizzes so far *today*. Resets at
  /// local midnight. Read every second by the home screen ticker, so the
  /// rollover check here keeps the displayed total correct even if the app stays
  /// open past midnight.
  int get dailyRewardSeconds {
    _rolloverDailyIfNeeded();
    return _dailyRewardSeconds;
  }

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

  // ── Daily reward total persistence ─────────────────────────────────────────

  String get _dailyRewardKey => 'reward_today_${_studentUid ?? 'unknown'}';
  String get _dailyRewardDateKey =>
      'reward_today_date_${_studentUid ?? 'unknown'}';

  /// Local calendar day as 'yyyy-MM-dd', used to detect a midnight rollover.
  String _todayKey() {
    final now = DateTime.now();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '${now.year}-$m-$d';
  }

  Future<void> _loadDailyReward() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _dailyRewardSeconds = prefs.getInt(_dailyRewardKey) ?? 0;
      _dailyRewardDate = prefs.getString(_dailyRewardDateKey) ?? '';
    } catch (e) {
      debugPrint('[MascotOverlayService] load daily reward error: $e');
      _dailyRewardSeconds = 0;
      _dailyRewardDate = '';
    }
    // Drop a stale total left over from a previous day.
    _rolloverDailyIfNeeded();
    debugPrint(
      '[MascotOverlayService] Loaded daily reward: ${_dailyRewardSeconds}s '
      '($_dailyRewardDate).',
    );
  }

  Future<void> _persistDailyReward() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_dailyRewardKey, _dailyRewardSeconds);
      await prefs.setString(_dailyRewardDateKey, _dailyRewardDate);
    } catch (_) {}
  }

  /// Resets the cumulative daily total to 0 when the local day has changed.
  /// In-memory update is synchronous (so getters see the reset immediately);
  /// the persisted value is updated fire-and-forget.
  void _rolloverDailyIfNeeded() {
    final today = _todayKey();
    if (_dailyRewardDate != today) {
      _dailyRewardSeconds = 0;
      _dailyRewardDate = today;
      unawaited(_persistDailyReward());
    }
  }

  // ── Monitored-apps cache (resilience) ───────────────────────────────────────
  // Locally-cached last-known monitored package set, keyed per student. Lets
  // app-blocking work the instant the student logs in and survive a failed/slow
  // config fetch. Overwritten on every successful updateMonitoredApps, so it is a
  // cache (never the permanent source of truth — the live fetch refreshes it).

  String get _monitoredCacheKey => 'monitored_apps_${_studentUid ?? 'unknown'}';

  Future<List<String>> _loadCachedMonitoredApps() async {
    if (_studentUid == null || _studentUid!.isEmpty) return const [];
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_monitoredCacheKey) ?? const [];
    } catch (_) {
      return const [];
    }
  }

  /// Re-pushes the current monitored apps + blocked state to the native side so a
  /// stale/empty accessibility static self-heals (e.g. after the service was
  /// reconnected in a fresh process, or init pushed an empty set before the cache
  /// existed). Reloads the cached apps if the in-memory set is empty. Safe to call
  /// on every app resume.
  Future<void> reassertBlockingState() async {
    if (_studentUid == null || _studentUid!.isEmpty) return;
    if (_monitoredPackages.isEmpty) {
      final cached = await _loadCachedMonitoredApps();
      if (cached.isNotEmpty) _monitoredPackages = cached.toSet();
    }
    try {
      await _accessibilityChannel.invokeMethod('setMonitoredApps', {
        'apps': _monitoredPackages.toList(),
        'studentUid': _studentUid,
      });
      await _accessibilityChannel
          .invokeMethod('setBlocked', {'blocked': isBlocked});
      debugPrint(
        '[MascotOverlayService] reassertBlockingState: '
        '${_monitoredPackages.length} apps, blocked=$isBlocked.',
      );
    } catch (_) {}
  }

  // ── Quiz completion: add reward time ───────────────────────────────────────

  /// Called when the student successfully completes a *forced* quiz. Grants
  /// [perQuizSeconds] of reward time. If not currently in cooldown, the native
  /// timer limit is updated so the new time is immediately available.
  ///
  /// Two quantities are updated, and they behave oppositely:
  ///   • the usable bank ([_earnedRewardSeconds]) is **capped at one session**
  ///     ([StudentConfigModel.rewardPerQuizSeconds]) — solving more quizzes never
  ///     grows it beyond a single session's worth;
  ///   • the daily total ([_dailyRewardSeconds]) is **cumulative** — it sums the
  ///     full per-quiz amount every time, across the whole day.
  Future<void> addRewardTime(int perQuizSeconds) async {
    if (perQuizSeconds <= 0) return;

    // Usable bank: cap at one session so reward time is non-cumulative. In the
    // normal flow the bank is already 0 when a forced quiz fires, so this just
    // sets it to one session; the cap only bites if a quiz is solved while time
    // is still banked.
    final sessionCap = _config.rewardPerQuizSeconds;
    _earnedRewardSeconds =
        (_earnedRewardSeconds + perQuizSeconds).clamp(0, sessionCap);
    await _persistEarnedReward();

    // Daily total: cumulative across the day (the banner headline).
    _rolloverDailyIfNeeded();
    _dailyRewardSeconds += perQuizSeconds;
    await _persistDailyReward();

    debugPrint(
      '[MascotOverlayService] addRewardTime(${perQuizSeconds}s) → '
      'usable bank: ${_earnedRewardSeconds}s (cap ${sessionCap}s), '
      'today total: ${_dailyRewardSeconds}s',
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
    // If in cooldown: the (capped) bank is just held. When cooldown ends,
    // _onUnblocked() starts the timer with the banked one-session reward.
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

  /// Brings StudyMentor to the foreground immediately using the overlay
  /// channel, which calls activity.startActivity() — exempt from Android 12+
  /// background-launch restrictions because of the SYSTEM_ALERT_WINDOW permission.
  Future<void> bringToForeground() async {
    try {
      await _overlayChannel.invokeMethod('bringAppToForeground');
    } catch (_) {}
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

      case 'onQuizRestore':
        debugPrint('[MascotOverlayService] onQuizRestore received from native.');
        if (_quizRestoreStream.hasListener) {
          _quizRestoreStream.add(null);
        } else {
          _pendingQuizRestoreTrigger = true;
        }
        break;

      case 'onShowQuiz':
        debugPrint('[MascotOverlayService] onShowQuiz received from native.');
        await _showUnmetGate();
        break;
    }
  }

  // ── Show the currently-unmet unlock gate ───────────────────────────────────
  //
  // Unblocking is a dual gate: apps unlock only when the cooldown has finished
  // AND the forced quiz has been solved this cycle. When the student is blocked
  // and reaches the app (opened a locked app, or it was brought forward), show
  // whichever gate is still unmet:
  //   • quiz unsolved (_earnedRewardSeconds <= 0) → bring app forward + show the
  //     start-quiz screen (clearing any prior "Not now" dismissal);
  //   • quiz already solved, only cooldown remaining (_earnedRewardSeconds > 0) →
  //     just bring the app forward (home shows the cooldown banner/ring), do NOT
  //     re-force a quiz they already completed.
  // This is side-effect-free — it never mutates timer/reward/cooldown state.
  Future<void> _showUnmetGate() async {
    if (!isBlocked) return;

    try {
      await _overlayChannel.invokeMethod('bringAppToForeground');
    } catch (_) {}

    // If init() has not yet run for this student, _earnedRewardSeconds is not
    // loaded — defer the quiz/cooldown decision to _syncStateFromNative (which
    // runs during init() and fires the quiz when appropriate).
    if (_studentUid == null) return;

    if (_earnedRewardSeconds <= 0) {
      _quizDismissedForThisCooldown = false;
      _timerServiceChannel
          .invokeMethod('setQuizDismissed', {'dismissed': false})
          .catchError((_) {});
      if (_quizStream.hasListener) {
        _quizStream.add(null);
      } else {
        _pendingQuizTrigger = true;
      }
    }
  }

  // ── Native → Dart callback: overlay ───────────────────────────────────────

  Future<dynamic> _handleOverlayCallback(MethodCall call) async {
    switch (call.method) {
      case 'onOverlayDismissed':
        if (isBlocked) {
          debugPrint(
            '[MascotOverlayService] Overlay dismissed — '
            'countdown continues ($_remainingCooldownSeconds s remaining).',
          );
        }
        break;

      case 'onMonitoredAppIntercepted':
        debugPrint(
          '[MascotOverlayService] Monitored app intercepted — '
          'showing the unmet unlock gate.',
        );
        await _showUnmetGate();
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
