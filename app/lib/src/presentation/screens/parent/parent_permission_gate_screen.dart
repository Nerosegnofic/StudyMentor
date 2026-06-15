// lib/src/presentation/screens/parent/parent_permission_gate_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../services/permission_service.dart';
import '../../../../l10n/app_localizations.dart';

/// Shown immediately after parent login when one or more required permissions
/// are missing. Displays permissions one at a time in order:
///
///   1. POST_NOTIFICATIONS  ← must be granted to proceed
///   2. Battery Optimization ← must be granted to proceed
///
/// The screen re-checks the current permission every time the app is resumed
/// from Settings. If it was granted it either advances to the next permission
/// or calls [onAllGranted] when both are confirmed.
class ParentPermissionGateScreen extends StatefulWidget {
  /// Called when every required parent permission has been confirmed as granted.
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
  // The permission currently being shown to the user.
  RequiredPermission? _current;

  // True while performing the initial or post-resume permission check.
  bool _checking = true;

  // True when the user returned from Settings and the current permission is
  // now granted — button changes to "Continue".
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

  // Re-check whenever the user returns from the Settings app.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _runCheck();
    }
  }

  /// Finds the first missing parent permission and updates state accordingly.
  /// If none are missing, calls [onAllGranted].
  Future<void> _runCheck() async {
    if (_checkInProgress) return;
    _checkInProgress = true;

    final missing = await PermissionService.firstMissingParentPermission();

    if (!mounted) {
      _checkInProgress = false;
      return;
    }

    if (missing == null) {
      _checkInProgress = false;
      widget.onAllGranted();
      return;
    }

    // Determine whether the permission we are currently showing was just
    // granted (user came back from Settings with it enabled).
    final justGranted = _current != null && missing != _current;

    setState(() {
      _checking = false;
      if (justGranted) {
        _currentGranted = true;
      } else {
        _current = missing;
        _currentGranted = false;
      }
    });

    _checkInProgress = false;
  }

  /// Called when the user taps the primary action button.
  ///
  ///   • Not yet granted → open Settings for the current permission.
  ///   • Already granted → advance to the next missing permission (or finish).
  Future<void> _onActionTap() async {
    if (_currentGranted) {
      setState(() {
        _checking = true;
        _currentGranted = false;
      });
      await _advanceToNext();
    } else {
      if (_current != null) {
        await PermissionService.openSettings(_current!);
      }
    }
  }

  /// After a permission was granted, finds the next missing permission and
  /// either updates [_current] or finishes the setup flow.
  Future<void> _advanceToNext() async {
    final missing = await PermissionService.firstMissingParentPermission();

    if (!mounted) return;

    if (missing == null) {
      widget.onAllGranted();
      return;
    }

    setState(() {
      _checking = false;
      _current = missing;
      _currentGranted = false;
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: _checking || _current == null
            ? const Center(child: CircularProgressIndicator())
            : _buildContent(_current!),
      ),
    );
  }

  Widget _buildContent(RequiredPermission permission) {
    final loc = AppLocalizations.of(context);
    final stepNumber = parentPermissions.indexOf(permission) + 1;
    const totalSteps = 2;

    return Column(
      children: [
        // ── Header ────────────────────────────────────────────────────────
        _buildHeader(stepNumber, totalSteps),

        // ── Body ──────────────────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildPermissionIcon(permission),
                const SizedBox(height: 28),
                Text(
                  permission.displayName(loc),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F2937),
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  permission.parentRationale(loc),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade600,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 40),
                _buildStatusCard(permission),
                const SizedBox(height: 32),
                _buildActionButton(),
                if (!_currentGranted) ...[
                  const SizedBox(height: 16),
                  _buildSettingsHint(permission),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Header with progress indicator ────────────────────────────────────────

  Widget _buildHeader(int step, int total) {
    final loc = AppLocalizations.of(context);
    return Container(
      decoration: const BoxDecoration(color: Color(0xFF1F2937)),
      padding: EdgeInsets.fromLTRB(
        24,
        MediaQuery.of(context).padding.top + 20,
        24,
        24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  loc.stepOfTotalLabel(step, total),
                  style: const TextStyle(
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.logout_rounded, size: 14),
                label: Text(
                  loc.logOutButton,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: step / total,
              minHeight: 5,
              backgroundColor: Colors.white.withValues(alpha: 0.12),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF4CAF50),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Permission icon ────────────────────────────────────────────────────────

  Widget _buildPermissionIcon(RequiredPermission permission) {
    final (IconData icon, Color color) = switch (permission) {
      RequiredPermission.postNotifications => (
        Icons.notifications_active_outlined,
        const Color(0xFFF59E0B),
      ),
      RequiredPermission.batteryOptimization => (
        Icons.battery_saver_outlined,
        const Color(0xFF16A34A),
      ),
      // Not reachable in the parent flow — safe fallback.
      _ => (Icons.lock_outline_rounded, const Color(0xFF6B7280)),
    };

    return Center(
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
        ),
        child: Icon(icon, size: 44, color: color),
      ),
    );
  }

  // ── Status card ────────────────────────────────────────────────────────────

  Widget _buildStatusCard(RequiredPermission permission) {
    final loc = AppLocalizations.of(context);
    if (_currentGranted) {
      return _statusRow(
        icon: Icons.check_circle_rounded,
        iconColor: const Color(0xFF10B981),
        backgroundColor: const Color(0xFFECFDF5),
        borderColor: const Color(0xFF10B981),
        text: loc.permissionEnabledMessage(permission.displayName(loc)),
        textColor: const Color(0xFF065F46),
      );
    }

    return _statusRow(
      icon: Icons.lock_outline_rounded,
      iconColor: const Color(0xFFF59E0B),
      backgroundColor: const Color(0xFFFFFBEB),
      borderColor: const Color(0xFFF59E0B),
      text: loc.permissionNotGrantedMessage,
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
    final loc = AppLocalizations.of(context);
    final label = _currentGranted ? loc.continueButton : loc.openSettingsButton;
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

  Widget _buildSettingsHint(RequiredPermission permission) {
    final loc = AppLocalizations.of(context);
    final hint = switch (permission) {
      RequiredPermission.postNotifications => loc.postNotificationsHint,
      RequiredPermission.batteryOptimization => loc.batteryOptimizationHint,
      _ => '',
    };

    if (hint.isEmpty) return const SizedBox.shrink();

    return Text(
      hint,
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 12, color: Colors.grey.shade500, height: 1.5),
    );
  }
}
