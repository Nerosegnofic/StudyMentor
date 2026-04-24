import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'mascot_state.dart';

class MascotOverlayService {
  MascotOverlayService._();
  static final MascotOverlayService instance = MascotOverlayService._();

  static const _overlayChannel =
      MethodChannel('com.example.studymentor/overlay');
  static const _usageChannel =
      MethodChannel('com.example.studymentor/usage_stats');

  bool _running = false;
  bool _overlayVisible = false;
  MascotState _mascotState = MascotState.idle;
  Timer? _pollTimer;
  Timer? _inactivityTimer;

  List<String> _monitoredApps = [];
  int _usageThresholdMinutes = 1;

  final Map<String, Duration> _usageAccumulator = {};
  DateTime? _lastActiveTime;
  String? _currentForegroundApp;

  static const List<String> dummyMonitoredApps = [
    'com.google.android.youtube',
    'com.zhiliaoapp.musically',
    'com.instagram.android',
    'com.facebook.katana',
    'com.snapchat.android',
  ];

  // ── Public API ─────────────────────────────────────────────────────────────

  Future<void> init({
    List<String> monitoredApps = dummyMonitoredApps,
    int usageThresholdMinutes = 1,
  }) async {
    _monitoredApps = monitoredApps;
    _usageThresholdMinutes = usageThresholdMinutes;

    // Listen for native callback when countdown finishes
    // This resets _overlayVisible so the next threshold can trigger again
    _overlayChannel.setMethodCallHandler((call) async {
      if (call.method == 'onOverlayDismissed') {
        _overlayVisible = false;
        _usageAccumulator.clear();
        _lastActiveTime = DateTime.now();
        _currentForegroundApp = null;
        debugPrint('[MascotOverlayService] Overlay dismissed — ready for next trigger.');
      }
    });

    final hasOverlay = await _requestOverlayPermission();
    final hasUsage = await _requestUsageStatsPermission();

    if (!hasOverlay || !hasUsage) {
      debugPrint('[MascotOverlayService] Missing permissions — overlay will not start.');
    }
  }

  void start() {
    if (_running) return;
    _running = true;
    _lastActiveTime = DateTime.now();
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) => _poll());
    debugPrint('[MascotOverlayService] Started.');
  }

  Future<void> stop() async {
    _running = false;
    _pollTimer?.cancel();
    _inactivityTimer?.cancel();
    await hideOverlay();
    debugPrint('[MascotOverlayService] Stopped.');
  }

  Future<void> showOverlay({MascotState state = MascotState.idle}) async {
    _mascotState = state;
    _overlayVisible = true;
    try {
      await _overlayChannel.invokeMethod('showOverlay', {
        'state': state.name,
      });
    } on PlatformException catch (e) {
      debugPrint('[MascotOverlayService] showOverlay error: ${e.message}');
    }
  }

  Future<void> hideOverlay() async {
    _overlayVisible = false;
    try {
      await _overlayChannel.invokeMethod('hideOverlay');
    } on PlatformException catch (e) {
      debugPrint('[MascotOverlayService] hideOverlay error: ${e.message}');
    }
  }

  Future<void> updateState(MascotState state) async {
    _mascotState = state;
    try {
      await _overlayChannel.invokeMethod('updateState', {'state': state.name});
    } on PlatformException catch (e) {
      debugPrint('[MascotOverlayService] updateState error: ${e.message}');
    }
  }

  Future<void> showQuizZone() async {
    try {
      await _overlayChannel.invokeMethod('showQuizZone');
    } on PlatformException catch (e) {
      debugPrint('[MascotOverlayService] showQuizZone error: ${e.message}');
    }
  }

  Future<void> hideQuizZone() async {
    try {
      await _overlayChannel.invokeMethod('hideQuizZone');
    } on PlatformException catch (e) {
      debugPrint('[MascotOverlayService] hideQuizZone error: ${e.message}');
    }
  }

  Future<void> onQuizResult({required bool correct}) async {
    await updateState(correct ? MascotState.wave : MascotState.encourage);
    Future.delayed(const Duration(seconds: 4), () => updateState(MascotState.idle));
  }

  // ── Internal polling ───────────────────────────────────────────────────────

  Future<void> _poll() async {
    if (!_running) return;
    if (_overlayVisible) return;


    try {
      final foreground = await _usageChannel.invokeMethod<String>('getForegroundApp');
      if (foreground == null) return;

      // Inactivity detection
      if (foreground == _currentForegroundApp &&
          !_monitoredApps.contains(foreground)) {
        _inactivityTimer ??= Timer(const Duration(minutes: 5), () {
          if (!_overlayVisible) showOverlay(state: MascotState.sleep);
        });
      } else {
        _inactivityTimer?.cancel();
        _inactivityTimer = null;
      }

      _currentForegroundApp = foreground;

      if (!_monitoredApps.contains(foreground)) {
        _lastActiveTime = DateTime.now();
        return;
      }

      // Accumulate usage
      final elapsed = DateTime.now().difference(_lastActiveTime!);
      _lastActiveTime = DateTime.now();
      _usageAccumulator[foreground] =
          (_usageAccumulator[foreground] ?? Duration.zero) + elapsed;

      final accumulated = _usageAccumulator[foreground]!;
      final threshold = Duration(minutes: _usageThresholdMinutes);

      if (accumulated >= threshold && !_overlayVisible) {
        await showOverlay(state: MascotState.idle);
        // Reset ALL apps accumulator so no app triggers immediately after
        _usageAccumulator.clear();
        _lastActiveTime = DateTime.now();
      }
    } on PlatformException catch (e) {
      debugPrint('[MascotOverlayService] poll error: ${e.message}');
    }
  }

  // ── Permissions ────────────────────────────────────────────────────────────

  Future<bool> _requestOverlayPermission() async {
    try {
      final granted = await _overlayChannel.invokeMethod<bool>('requestOverlayPermission');
      return granted ?? false;
    } on PlatformException catch (e) {
      debugPrint('[MascotOverlayService] overlay permission error: ${e.message}');
      return false;
    }
  }

  Future<bool> _requestUsageStatsPermission() async {
    try {
      final granted = await _usageChannel.invokeMethod<bool>('requestUsageStatsPermission');
      return granted ?? false;
    } on PlatformException catch (e) {
      debugPrint('[MascotOverlayService] usage stats permission error: ${e.message}');
      return false;
    }
  }

  bool get isRunning => _running;
  bool get isOverlayVisible => _overlayVisible;
  MascotState get currentState => _mascotState;
}
