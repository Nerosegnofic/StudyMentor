import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'mascot_state.dart';
import '../../domain/models/app_config_model.dart';

class MascotOverlayService {
  MascotOverlayService._();
  static final MascotOverlayService instance = MascotOverlayService._();

  static const _overlayChannel =
      MethodChannel('com.example.studymentor/overlay');
  static const _usageChannel =
      MethodChannel('com.example.studymentor/usage_stats');
  static const _accessibilityChannel =
      MethodChannel('com.example.studymentor/accessibility');

  // ── State ──────────────────────────────────────────────────────────────────
  bool _running        = false;
  bool _isBlocked      = false;
  bool _overlayVisible = false;
  MascotState _mascotState = MascotState.idle;

  // ── Countdown ──────────────────────────────────────────────────────────────
  Timer? _countdownTimer;
  int    _remainingSeconds = 0;

  // ── Polling ────────────────────────────────────────────────────────────────
  Timer? _pollTimer;
  Map<String, int> _usageCounts = {};

  // ── Config ─────────────────────────────────────────────────────────────────
  Map<String, AppRuleModel> _monitoredRules = {};
  String? _currentMonitoredPackage;

  // ── Public API ─────────────────────────────────────────────────────────────

  Future<void> init({
    List<AppRuleModel> rules = const [],
  }) async {
    _monitoredRules = {for (var r in rules) r.packageName: r};
    _currentMonitoredPackage = null;

    _overlayChannel.setMethodCallHandler(_handleNativeCallback);

    await _accessibilityChannel.invokeMethod(
      'setMonitoredApps',
      {'apps': _monitoredRules.keys.toList()},
    );

    await _requestOverlayPermission();
    await _requestUsageStatsPermission();
    await _requestAccessibilityPermissionIfNeeded();
  }

  void start() {
    if (_running) return;
    _running  = true;
    _pollTimer = Timer.periodic(const Duration(seconds: 1), (_) => _poll());
    debugPrint('[MascotOverlayService] Started.');
  }

  Future<void> stop() async {
    _running = false;
    _pollTimer?.cancel();
    _countdownTimer?.cancel();
    await _hideOverlayNative();
    await _resetAccessibilityState();
    _isBlocked           = false;
    _overlayVisible      = false;
    _remainingSeconds    = 0;
    _usageCounts.clear();
    debugPrint('[MascotOverlayService] Stopped.');
  }

  /// Updates the monitored-app list at runtime without restarting the service.
  /// Called by [StudentScreen] whenever a fresh [AppRulesLoaded] state arrives.
  Future<void> updateMonitoredApps(List<AppRuleModel> rules) async {
    _monitoredRules = {for (var r in rules) r.packageName: r};
    try {
      await _accessibilityChannel.invokeMethod(
        'setMonitoredApps',
        {'apps': _monitoredRules.keys.toList()},
      );
    } on PlatformException catch (e) {
      debugPrint('[MascotOverlayService] updateMonitoredApps error: ${e.message}');
    }
    debugPrint('[MascotOverlayService] Monitored apps updated: ${_monitoredRules.keys.toList()}');
  }

  // ── Getters ────────────────────────────────────────────────────────────────
  bool        get isRunning       => _running;
  bool        get isBlocked       => _isBlocked;
  bool        get isOverlayVisible => _overlayVisible;
  int         get remainingSeconds => _remainingSeconds;
  MascotState get currentState     => _mascotState;

  // ── Native → Dart callback handler ─────────────────────────────────────────

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
        // Accessibility service blocked a monitored app during the warning period.
        // Re-show the overlay with the remaining countdown time.
        if (_isBlocked && !_overlayVisible) {
          debugPrint('[MascotOverlayService] Monitored app intercepted — re-showing overlay.');
          await _showOverlayNative(remainingSeconds: _remainingSeconds);
        }
    }
  }

  // ── Warning phase ───────────────────────────────────────────────────────────

  Future<void> _startWarning() async {
    final rule = _monitoredRules[_currentMonitoredPackage];
    if (rule == null) {
      await _unblock();
      return;
    }

    _isBlocked = true;
    _remainingSeconds = (rule.cooldownHours * 3600) + (rule.cooldownMinutes * 60);
    _mascotState = MascotState.idle;
    debugPrint(
      '[MascotOverlayService] Warning overlay — '
      '$_remainingSeconds s countdown.',
    );

    await _accessibilityChannel.invokeMethod('setBlocked', {'blocked': true});
    await _showOverlayNative(remainingSeconds: _remainingSeconds);

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      _remainingSeconds--;
      debugPrint('[MascotOverlayService] Countdown: $_remainingSeconds s');

      if (_overlayVisible) {
        try {
          await _overlayChannel.invokeMethod(
            'updateCountdown',
            {'remainingSeconds': _remainingSeconds},
          );
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
    _usageCounts.clear();
    _currentMonitoredPackage = null;
    _mascotState         = MascotState.idle;

    await _hideOverlayNative();
    await _resetAccessibilityState();
    debugPrint('[MascotOverlayService] Unblocked — student is free.');
  }

  // ── Native overlay helpers ──────────────────────────────────────────────────

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

  // ── Polling ─────────────────────────────────────────────────────────────────

  Future<void> _poll() async {
    if (!_running) return;
    try {
      final foreground =
          await _usageChannel.invokeMethod<String>('getForegroundApp');
      if (foreground == null) return;

      if (_isBlocked) {
        // Fallback: if poll still sees a monitored app while overlay is hidden,
        // re-show it (primary path is via AccessibilityService).
        if (_monitoredRules.containsKey(foreground) && !_overlayVisible) {
          debugPrint(
            '[MascotOverlayService] Poll fallback: monitored app in foreground '
            '— re-showing overlay.',
          );
          await _showOverlayNative(remainingSeconds: _remainingSeconds);
        }
        return;
      }

      if (!_monitoredRules.containsKey(foreground)) {
        // Not a monitored app — just stop here, but keep previous counts.
        _currentMonitoredPackage = null;
        return;
      }

      final rule = _monitoredRules[foreground]!;
      _currentMonitoredPackage = foreground;
      // Increment count for this specific app (now 1s per increment)
      _usageCounts[foreground] = (_usageCounts[foreground] ?? 0) + 1;
      
      final accumulatedSeconds = _usageCounts[foreground]!;
      final thresholdSeconds = (rule.usageHours * 3600) + (rule.usageMinutes * 60);
      
      debugPrint(
        '[MascotOverlayService] ${rule.appLabel} '
        'cumulative usage: ${accumulatedSeconds}s / ${thresholdSeconds}s',
      );

      if (accumulatedSeconds >= thresholdSeconds) {
        await _startWarning();
      }
    } on PlatformException catch (e) {
      debugPrint('[MascotOverlayService] poll error: ${e.message}');
    }
  }

  // ── Accessibility helpers ───────────────────────────────────────────────────

  Future<void> _resetAccessibilityState() async {
    try {
      await _accessibilityChannel.invokeMethod('setBlocked', {'blocked': false});
    } on PlatformException catch (e) {
      debugPrint('[MascotOverlayService] resetAccessibilityState error: ${e.message}');
    }
  }

  // ── Permissions ─────────────────────────────────────────────────────────────

  Future<void> _requestOverlayPermission() async {
    try {
      await _overlayChannel.invokeMethod('requestOverlayPermission');
    } on PlatformException catch (e) {
      debugPrint('[MascotOverlayService] overlay permission error: ${e.message}');
    }
  }

  Future<void> _requestUsageStatsPermission() async {
    try {
      await _usageChannel.invokeMethod('requestUsageStatsPermission');
    } on PlatformException catch (e) {
      debugPrint('[MascotOverlayService] usage stats permission error: ${e.message}');
    }
  }

  Future<void> _requestAccessibilityPermissionIfNeeded() async {
    try {
      final isEnabled =
          await _accessibilityChannel.invokeMethod<bool>('isAccessibilityEnabled');
      if (isEnabled != true) {
        await _accessibilityChannel.invokeMethod('requestAccessibilityPermission');
      } else {
        debugPrint('[MascotOverlayService] Accessibility already enabled.');
      }
    } on PlatformException catch (e) {
      debugPrint('[MascotOverlayService] accessibility permission error: ${e.message}');
    }
  }
}
