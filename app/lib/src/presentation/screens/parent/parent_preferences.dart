// lib/src/presentation/screens/parent/parent_preferences.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../bloc/auth/auth_bloc.dart';
import '../../../bloc/auth/auth_state.dart';
import '../../../data/providers/dataconnect_provider.dart';
import '../../../services/notification_preferences_cache.dart';
import '../../widgets/language_picker_dialog.dart';
import '../../../../l10n/app_localizations.dart';

class ParentPreferencesScreen extends StatefulWidget {
  const ParentPreferencesScreen({super.key});

  @override
  State<ParentPreferencesScreen> createState() =>
      _ParentPreferencesScreenState();
}

class _ParentPreferencesScreenState extends State<ParentPreferencesScreen> {
  // ── Category toggles ───────────────────────────────────────────────────────
  bool _progressAlertsEnabled = true;
  bool _streakAlertsEnabled = true;
  bool _inactivityAlertsEnabled = true;

  // ── Per-student toggles ────────────────────────────────────────────────────
  // Ordered list of {uid, full_name} so the UI preserves load order.
  List<Map<String, dynamic>> _students = [];
  // studentUid → enabled
  Map<String, bool> _studentNotifEnabled = {};

  bool _loading = true;
  String? _parentUid;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      setState(() => _loading = false);
      return;
    }
    _parentUid = authState.user.uid;

    final results = await Future.wait([
      SharedPreferences.getInstance(),
      DataConnectProvider().getStudentsByParent(_parentUid!),
    ]);

    if (!mounted) return;

    final prefs = results[0] as SharedPreferences;
    final students = results[1] as List<Map<String, dynamic>>;

    final studentToggles = <String, bool>{};
    for (final student in students) {
      final uid = student['uid'] as String;
      studentToggles[uid] =
          prefs.getBool('pref_${_parentUid}_notif_student_$uid') ?? true;
    }

    setState(() {
      _progressAlertsEnabled =
          prefs.getBool('pref_${_parentUid}_PARENT_CHILD_PROGRESS') ?? true;
      _streakAlertsEnabled =
          prefs.getBool('pref_${_parentUid}_PARENT_STREAK_ALERTS') ?? true;
      _inactivityAlertsEnabled =
          prefs.getBool('pref_${_parentUid}_PARENT_INACTIVITY') ?? true;
      _students = students;
      _studentNotifEnabled = studentToggles;
      _loading = false;
    });
  }

  // ── Category setters ───────────────────────────────────────────────────────

  Future<void> _setProgressAlerts(bool value) async {
    if (_parentUid == null) return;
    setState(() => _progressAlertsEnabled = value);
    try {
      await NotificationPreferencesCache.updatePreference(
        userUid: _parentUid!,
        category: 'PARENT_CHILD_PROGRESS',
        enabled: value,
      );
    } catch (_) {
      if (mounted) setState(() => _progressAlertsEnabled = !value);
    }
  }

  Future<void> _setStreakAlerts(bool value) async {
    if (_parentUid == null) return;
    setState(() => _streakAlertsEnabled = value);
    try {
      await NotificationPreferencesCache.updatePreference(
        userUid: _parentUid!,
        category: 'PARENT_STREAK_ALERTS',
        enabled: value,
      );
    } catch (_) {
      if (mounted) setState(() => _streakAlertsEnabled = !value);
    }
  }

  Future<void> _setInactivityAlerts(bool value) async {
    if (_parentUid == null) return;
    setState(() => _inactivityAlertsEnabled = value);
    try {
      await NotificationPreferencesCache.updatePreference(
        userUid: _parentUid!,
        category: 'PARENT_INACTIVITY',
        enabled: value,
      );
    } catch (_) {
      if (mounted) setState(() => _inactivityAlertsEnabled = !value);
    }
  }

  // ── Per-student setter ─────────────────────────────────────────────────────

  Future<void> _setStudentNotif(String studentUid, bool value) async {
    if (_parentUid == null) return;
    setState(() => _studentNotifEnabled[studentUid] = value);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(
        'pref_${_parentUid}_notif_student_$studentUid',
        value,
      );
    } catch (_) {
      if (mounted) setState(() => _studentNotifEnabled[studentUid] = !value);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2196F3),
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.15),
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          loc.parentPreferencesTitle,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildCard(
                    title: loc.languageSettingTitle,
                    child: _buildLanguageRow(loc),
                  ),
                  const SizedBox(height: 16),
                  _buildCard(
                    title: loc.parentNotificationsSection,
                    child: Column(
                      children: [
                        _buildToggleRow(
                          label: loc.parentNotifProgressLabel,
                          subtitle: loc.parentNotifProgressSubtitle,
                          icon: Icons.trending_up_rounded,
                          value: _progressAlertsEnabled,
                          onChanged: _setProgressAlerts,
                        ),
                        const Divider(height: 1, indent: 46),
                        _buildToggleRow(
                          label: loc.parentNotifStreakLabel,
                          subtitle: loc.parentNotifStreakSubtitle,
                          icon: Icons.local_fire_department_rounded,
                          value: _streakAlertsEnabled,
                          onChanged: _setStreakAlerts,
                        ),
                        const Divider(height: 1, indent: 46),
                        _buildToggleRow(
                          label: loc.parentNotifInactivityLabel,
                          subtitle: loc.parentNotifInactivitySubtitle,
                          icon: Icons.notifications_off_outlined,
                          value: _inactivityAlertsEnabled,
                          onChanged: _setInactivityAlerts,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildCard(
                    title: loc.parentNotifPerStudentSection,
                    child: _buildStudentSection(loc),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildStudentSection(AppLocalizations loc) {
    if (_students.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          loc.parentNotifNoStudentsLinked,
          style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
        ),
      );
    }

    return Column(
      children: [
        for (int i = 0; i < _students.length; i++) ...[
          if (i > 0) const Divider(height: 1, indent: 46),
          _buildToggleRow(
            label: _students[i]['full_name'] as String,
            subtitle: loc.parentStudentNotifAllLabel,
            icon: Icons.person_outline_rounded,
            value: _studentNotifEnabled[_students[i]['uid'] as String] ?? true,
            onChanged: (v) =>
                _setStudentNotif(_students[i]['uid'] as String, v),
          ),
        ],
      ],
    );
  }

  // ── Shared widgets ─────────────────────────────────────────────────────────

  Widget _buildCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildLanguageRow(AppLocalizations loc) {
    return InkWell(
      onTap: () => showLanguagePickerDialog(context),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.language_rounded,
                color: Color(0xFF2196F3),
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.languageSettingTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    loc.languageSettingSubtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF94A3B8),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleRow({
    required String label,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF2196F3), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFF2196F3),
            activeTrackColor: const Color(0xFFBBDEFB),
          ),
        ],
      ),
    );
  }
}
