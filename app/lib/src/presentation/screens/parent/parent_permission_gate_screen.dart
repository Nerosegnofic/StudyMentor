// lib/src/presentation/screens/parent/parent_permission_gate_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../services/permission_service.dart';

/// Shown immediately after parent login when the battery-optimisation
/// permission has not yet been granted.
///
/// Parents only need one permission:
///
///   1. Battery Optimization  ← must be granted to proceed
///
/// Unlike the student gate, this screen does NOT call [DeviceAdminService]
/// (that guard is student-only). When the permission is granted,
/// [onAllGranted] is called to continue into the parent dashboard.
class ParentPermissionGateScreen extends StatefulWidget {
  /// Called when the battery-optimisation step is granted.
  final VoidCallback onAllGranted;

  /// Called when the user taps "Log out" in the header.
  final VoidCallback onSignOut;

  const ParentPermissionGateScreen({
    super.key,
    required this.onAllGranted,
    required this.onSignOut,
  });

  @override
  State<ParentPermissionGateScreen> createState() =>
      _ParentPermissionGateScreenState();
}

class _ParentPermissionGateScreenState extends State<ParentPermissionGateScreen>
    with WidgetsBindingObserver {
  // True while performing the initial or post-resume permission check.
  bool _checking = true;

  // True once the user returns from Settings with the permission granted —
  // the button switches to "Continue".
  bool _currentGranted = false;

  // Prevent multiple simultaneous checks triggered by rapid lifecycle events.
  bool _checkInProgress = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _runCheck();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Re-check when the user returns from the Settings app.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _runCheck();
    }
  }

  /// Checks whether battery optimisation has been disabled for the app.
  /// If it has already been granted, skips straight to [onAllGranted].
  Future<void> _runCheck() async {
    if (_checkInProgress) return;
    _checkInProgress = true;

    final granted = await PermissionService.isGranted(
      RequiredPermission.batteryOptimization,
    );

    if (!mounted) {
      _checkInProgress = false;
      return;
    }

    if (granted) {
      _checkInProgress = false;
      widget.onAllGranted();
      return;
    }

    // Determine if the user just came back from Settings with it enabled.
    final justGranted = !_checking && granted;

    setState(() {
      _checking = false;
      _currentGranted = justGranted;
    });

    _checkInProgress = false;
  }

  /// Primary action button handler.
  ///
  ///   • Not yet granted → open battery-optimisation Settings.
  ///   • Already granted → call [onAllGranted].
  Future<void> _onActionTap() async {
    if (_currentGranted) {
      widget.onAllGranted();
    } else {
      await PermissionService.openSettings(
        RequiredPermission.batteryOptimization,
      );
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: _checking
            ? const Center(child: CircularProgressIndicator())
            : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // ── Header ────────────────────────────────────────────────────────
        _buildHeader(),

        // ── Body ──────────────────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildPermissionIcon(),
                const SizedBox(height: 28),
                const Text(
                  'Disable Battery Optimization',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F2937),
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Keep StudyMentor running in the background so you never '
                  'miss a notification from your students. Without this, '
                  'Android may silently put the app to sleep and delay — or '
                  'drop — important alerts.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade600,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 40),
                _buildStatusCard(),
                const SizedBox(height: 32),
                _buildActionButton(),
                if (!_currentGranted) ...[
                  const SizedBox(height: 16),
                  _buildSettingsHint(),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(color: Color(0xFF1F2937)),
      padding: EdgeInsets.fromLTRB(
        24,
        MediaQuery.of(context).padding.top + 20,
        24,
        24,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Setup Required',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4CAF50),
              ),
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: widget.onSignOut,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white.withValues(alpha: 0.55),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: const Icon(Icons.logout_rounded, size: 14),
            label: const Text(
              'Log out',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  // ── Icon ───────────────────────────────────────────────────────────────────

  Widget _buildPermissionIcon() {
    const color = Color(0xFF16A34A);
    return Center(
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
        ),
        child: const Icon(Icons.battery_saver_outlined, size: 44, color: color),
      ),
    );
  }

  // ── Status card ────────────────────────────────────────────────────────────

  Widget _buildStatusCard() {
    if (_currentGranted) {
      return _statusRow(
        icon: Icons.check_circle_rounded,
        iconColor: const Color(0xFF10B981),
        backgroundColor: const Color(0xFFECFDF5),
        borderColor: const Color(0xFF10B981),
        text: 'Battery optimization has been disabled.',
        textColor: const Color(0xFF065F46),
      );
    }

    return _statusRow(
      icon: Icons.lock_outline_rounded,
      iconColor: const Color(0xFFF59E0B),
      backgroundColor: const Color(0xFFFFFBEB),
      borderColor: const Color(0xFFF59E0B),
      text:
          'Permission not granted yet. Tap the button below to open Settings.',
      textColor: const Color(0xFF92400E),
    );
  }

  Widget _statusRow({
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required Color borderColor,
    required String text,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: textColor, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  // ── Action button ──────────────────────────────────────────────────────────

  Widget _buildActionButton() {
    final label = _currentGranted ? 'Continue' : 'Open Settings';
    final color = _currentGranted
        ? const Color(0xFF10B981)
        : const Color(0xFF1F2937);

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _onActionTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 8),
            Icon(
              _currentGranted
                  ? Icons.arrow_forward_rounded
                  : Icons.settings_outlined,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  // ── Hint text ──────────────────────────────────────────────────────────────

  Widget _buildSettingsHint() {
    return Text(
      'Find "StudyMentor", select "Don\'t optimize" or "Unrestricted", '
      'then confirm.',
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 12, color: Colors.grey.shade500, height: 1.5),
    );
  }
}
