import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'mascot_state.dart';

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
  int    _monitoredUsageCount = 0;

  // ── Config ─────────────────────────────────────────────────────────────────
  List<String> _monitoredApps         = dummyMonitoredApps;
  int          _usageThresholdSeconds = 20;
  int          _blockDurationSeconds  = 30;

  static const List<String> dummyMonitoredApps = [
    'com.google.android.youtube',
    'com.zhiliaoapp.musically',
    'com.instagram.android',
    'com.facebook.katana',
    'com.snapchat.android',
  ];

  // ── Public API ─────────────────────────────────────────────────────────────

  Future<void> init({
    List<String> monitoredApps       = dummyMonitoredApps,
    int usageThresholdSeconds        = 20,
    int blockDurationSeconds         = 30,
  }) async {
    _monitoredApps         = monitoredApps;
    _usageThresholdSeconds = usageThresholdSeconds;
    _blockDurationSeconds  = blockDurationSeconds;

    _overlayChannel.setMethodCallHandler(_handleNativeCallback);

    await _accessibilityChannel.invokeMethod(
      'setMonitoredApps',
      {'apps': _monitoredApps},
    );

    await _requestOverlayPermission();
    await _requestUsageStatsPermission();
    await _requestAccessibilityPermissionIfNeeded();
  }

  void start() {
    if (_running) return;
    _running  = true;
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _poll());
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
    _monitoredUsageCount = 0;
    debugPrint('[MascotOverlayService] Stopped.');
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
    _isBlocked        = true;
    _remainingSeconds = _blockDurationSeconds;
    _mascotState      = MascotState.idle;
    debugPrint(
      '[MascotOverlayService] Warning overlay — '
      '$_blockDurationSeconds s countdown.',
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
    _isBlocked           = false;
    _remainingSeconds    = 0;
    _monitoredUsageCount = 0;
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
        if (_monitoredApps.contains(foreground) && !_overlayVisible) {
          debugPrint(
            '[MascotOverlayService] Poll fallback: monitored app in foreground '
            '— re-showing overlay.',
          );
          await _showOverlayNative(remainingSeconds: _remainingSeconds);
        }
        return;
      }

      if (!_monitoredApps.contains(foreground)) {
        _monitoredUsageCount = 0;
        return;
      }

      _monitoredUsageCount++;
      final accumulatedSeconds = _monitoredUsageCount * 5;
      debugPrint(
        '[MascotOverlayService] ${foreground.split('.').last} '
        'usage: ${accumulatedSeconds}s / ${_usageThresholdSeconds}s',
      );

      if (accumulatedSeconds >= _usageThresholdSeconds) {
        _monitoredUsageCount = 0;
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
