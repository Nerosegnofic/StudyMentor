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

  // ── Config ─────────────────────────────────────────────────────────────────
  Set<String> _monitoredPackages = {};
  StudentConfigModel _config = const StudentConfigModel();
  String? _currentMonitoredPackage;

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
    await _hideOverlayNative();
    await _resetAccessibilityState();
    _isBlocked = false;
    _overlayVisible = false;
    _remainingSeconds = 0;
    _totalUsageSeconds = 0;
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
    _mascotState = MascotState.idle;

    await _hideOverlayNative();
    await _resetAccessibilityState();
    debugPrint('[MascotOverlayService] Cooldown ended — student is free.');
  }

  // ── Native overlay helpers ─────────────────────────────────────────────────

  Future<void> _showOverlayNative({required int remainingSeconds}) async {
    _overlayVisible = true;
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

  // ── Polling ────────────────────────────────────────────────────────────────

  Future<void> _poll() async {
    if (!_running) return;
    try {
      final foreground = await _usageChannel.invokeMethod<String>(
        'getForegroundApp',
      );
      if (foreground == null) return;

      if (_isBlocked) {
        // Fallback: if poll still sees a monitored app while overlay is hidden,
        // re-show it (primary path is via AccessibilityService).
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
        // Not a restricted app — stop tracking but keep the shared counter.
        _currentMonitoredPackage = null;
        return;
      }

      // ── Accumulate into the shared counter ─────────────────────────────
      // Every second spent in ANY restricted app adds to the same total.
      _currentMonitoredPackage = foreground;
      _totalUsageSeconds++;

      final thresholdSeconds =
          (_config.usageHours * 3600) + (_config.usageMinutes * 60);

      debugPrint(
        '[MascotOverlayService] Restricted app in foreground: $foreground — '
        'shared usage: ${_totalUsageSeconds}s / ${thresholdSeconds}s',
      );

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
