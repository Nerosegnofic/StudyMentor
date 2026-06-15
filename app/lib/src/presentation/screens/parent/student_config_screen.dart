// lib/src/presentation/screens/parent/student_config_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart' show CupertinoTimerPicker, CupertinoTheme, CupertinoThemeData, CupertinoTextThemeData, CupertinoTimerPickerMode;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../bloc/auth/auth_bloc.dart';
import '../../../bloc/auth/auth_event.dart';
import '../../../bloc/students/students_bloc.dart';
import '../../../bloc/students/students_event.dart' hide DeleteStudentRequested;

import '../../../bloc/auth/auth_state.dart';
import '../../../bloc/app_config/app_config_bloc.dart';
import '../../../bloc/app_config/app_config_event.dart';
import '../../../bloc/app_config/app_config_state.dart';
import '../../../domain/models/app_config_model.dart';
import '../../../domain/models/quiz_count.dart';
import '../../../domain/models/student_model.dart';
import '../../../domain/models/installed_app_model.dart';
import 'parent_student_settings_screen.dart';
import '../../../../l10n/app_localizations.dart';

class StudentConfigScreen extends StatefulWidget {
  final StudentModel student;

  const StudentConfigScreen({super.key, required this.student});

  @override
  State<StudentConfigScreen> createState() => _StudentConfigScreenState();
}

class _StudentConfigScreenState extends State<StudentConfigScreen> {
  final List<PendingAppRule> _rules = [];
  StudentConfigModel _config = const StudentConfigModel();
  late StudentModel _student;

  List<InstalledAppModel> _installedApps = [];
  bool _appsLoading = true;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isDirty = false;
  bool _hasTimingErrors = false;

  /// True while a parent-triggered refresh is in flight.
  bool _isRefreshing = false;

  Set<String> get _configuredPackages =>
      _rules.map((r) => r.packageName).toSet();

  @override
  void initState() {
    super.initState();
    _student = widget.student;
    context.read<AppConfigBloc>().add(
      LoadAppRulesRequested(studentUid: widget.student.uid),
    );
    context.read<AuthBloc>().add(
      LoadInstalledAppsForStudentRequested(studentUid: widget.student.uid),
    );
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  void _loadRulesFromSaved(List<AppRuleModel> saved) {
    _rules.clear();
    for (final r in saved) {
      _rules.add(
        PendingAppRule(
          packageName: r.packageName, 
          appLabel: r.appLabel,
          isPaused: r.isPaused,
        ),
      );
    }
  }

  void _markDirty() {
    if (!_isDirty) setState(() => _isDirty = true);
  }

  Future<void> _save() async {
    final rulesToSave = _rules.map((r) => PendingAppRule(
      packageName: r.packageName,
      appLabel: r.appLabel,
      isPaused: r.isPaused,
    )).toList();

    context.read<AppConfigBloc>().add(
      SaveAppRulesRequested(
        studentUid: widget.student.uid,
        rules: rulesToSave,
        config: _config,
      ),
    );
  }

  /// Triggered by the refresh button.
  /// If the parent has unsaved changes, shows a confirmation dialog first
  /// so they don't accidentally lose their edits.
  Future<void> _refresh() async {
    if (_isRefreshing || _isSaving) return;

    if (_isDirty) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          final loc = AppLocalizations.of(ctx);
          return AlertDialog(
            title: Text(loc.unsavedChangesDialogTitle),
            content: Text(loc.discardChangesDialogContent),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(loc.commonCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                ),
                child: Text(loc.discardAndRefreshButton),
              ),
            ],
          );
        },
      );
      if (proceed != true) return;
    }

    context.read<AppConfigBloc>().add(
      RefreshStudentDataRequested(studentUid: widget.student.uid),
    );
  }

  // ── app picker sheet ───────────────────────────────────────────────────────

  Future<void> _showAppPicker() async {
    final loc = AppLocalizations.of(context);
    if (_appsLoading) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.stillLoadingAppListMessage)),
      );
      return;
    }

    final seen = <String>{};
    final available = _installedApps
        .where(
          (a) =>
              !_configuredPackages.contains(a.packageName) &&
              seen.add(a.packageName),
        )
        .toList();

    if (_installedApps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            loc.deviceNotSyncedMessage(_student.fullName.split(' ').first),
          ),
        ),
      );
      return;
    }

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.allAppsAlreadyConfiguredMessage),
        ),
      );
      return;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _AppPickerSheet(
        availableApps: available,
        onAppsSelected: (selected) {
          setState(() {
            final alreadyConfigured = _configuredPackages;
            for (final app in selected) {
              if (alreadyConfigured.add(app.packageName)) {
                _rules.add(
                  PendingAppRule(
                    packageName: app.packageName,
                    appLabel: app.appLabel,
                    isPaused: false,
                  ),
                );
              }
            }
          });
          _markDirty();
        },
      ),
    );
  }

  Future<void> _showRewardTimePicker() async {
    final result = await showModalBottomSheet<Map<String, int>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _SetRewardTimeSheet(
          initialHours: _config.usageHours,
          initialMinutes: _config.usageMinutes,
        );
      },
    );
    if (result != null && mounted) {
      setState(() {
        _config = _config.copyWith(
          usageHours: result['hours']!,
          usageMinutes: result['minutes']!,
        );
      });
      _markDirty();
    }
  }

  Future<void> _showCooldownTimePicker() async {
    final result = await showModalBottomSheet<Map<String, int>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SetRewardTimeSheet(
        initialHours: _config.cooldownHours,
        initialMinutes: _config.cooldownMinutes,
        title: AppLocalizations.of(context).setCooldownTimeTitle,
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _config = _config.copyWith(
          cooldownHours: result['hours']!,
          cooldownMinutes: result['minutes']!,
        );
      });
      _markDirty();
    }
  }

  // ── remove a rule ──────────────────────────────────────────────────────────

  void _removeRule(int index) {
    setState(() => _rules.removeAt(index));
    _markDirty();
  }

  Future<void> _confirmRemoveRule(PendingAppRule rule, int index) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final loc = AppLocalizations.of(dialogContext);
        return Dialog(
          backgroundColor: const Color(0xFFFFFFFF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  loc.removeAppConfirmTitle(rule.appLabel),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  loc.removeAppConfirmMessage,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    color: const Color(0xFF64748B),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.of(dialogContext).pop(),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            loc.commonCancel,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          _removeRule(index);
                          Navigator.of(dialogContext).pop();
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFE53935),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            loc.removeButton,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AppConfigBloc, AppConfigState>(
          listener: (context, state) {
            // ── Refresh started ────────────────────────────────────────────────
            if (state is StudentDataRefreshing) {
              setState(() => _isRefreshing = true);
            }

            // ── Rules + config loaded (initial load OR after refresh) ──────────
            if (state is AppRulesLoaded && state.studentUid == widget.student.uid) {
              setState(() {
                _config = state.config;
                _loadRulesFromSaved(state.rules);
                _isLoading = false;
                _isDirty = false;
                _isRefreshing = false;
              });
            }

            if (state is AppConfigSaving) {
              setState(() => _isSaving = true);
            }

            if (state is AppConfigSaved) {
              setState(() {
                _isSaving = false;
                _isDirty = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context).configSavedSuccessMessage),
                  backgroundColor: const Color(0xFF34A853),
                ),
              );
            }

            if (state is AppConfigError) {
              setState(() {
                _isLoading = false;
                _isSaving = false;
                _isRefreshing = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red.shade700,
                ),
              );
            }
          },
        ),
        BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            // ── Installed apps loaded (initial load OR after refresh) ──────────
            if (state is InstalledAppsLoaded &&
                state.studentUid == widget.student.uid) {
              setState(() {
                _installedApps = state.apps;
                _appsLoading = false;
                _isRefreshing = false;
              });
            }
          },
        ),
      ],
      child: PopScope(
        canPop: !_isDirty,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          final leave = await _showUnsavedChangesDialog();
          if (leave && context.mounted) Navigator.of(context).pop();
        },
        child: Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    _buildStickyHeader(),
                    Expanded(child: _buildNewBody()),
                    _buildStickySaveButton(),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildStickyHeader() {
    final loc = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF2196F3),
        boxShadow: [
          BoxShadow(color: Color(0x1A2196F3), blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                onPressed: () {
                  if (_isDirty) {
                    _showUnsavedChangesDialog().then((leave) {
                      if (leave && context.mounted) Navigator.of(context).pop();
                    });
                  } else {
                    Navigator.of(context).pop();
                  }
                },
              ),
              Expanded(
                child: Text(
                  loc.configurationsTitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _isRefreshing
                    ? const Padding(
                        key: ValueKey('spinner'), padding: EdgeInsets.all(12),
                        child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                      )
                    : IconButton(
                        key: const ValueKey('refresh'),
                        icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                        onPressed: _isSaving ? null : _refresh,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStickySaveButton() {
    final canSave = _isDirty && !_isSaving && !_hasTimingErrors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, -3)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: ElevatedButton(
          onPressed: canSave ? _save : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2196F3),
            disabledBackgroundColor: const Color(0xFFBDBDBD),
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            elevation: 0,
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(
                  AppLocalizations.of(context).saveChangesButton,
                  style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold),
                ),
        ),
      ),
    );
  }

  Widget _buildNewBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildRewardCard(),
          const SizedBox(height: 12),
          _buildCooldownCard(),
          const SizedBox(height: 16),
          _buildAppRulesCard(),
          const SizedBox(height: 16),
          _buildQuizSettingsCard(),
          const SizedBox(height: 24),
          _buildActionButtons(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Card 1: Screen Time Reward ────────────────────────────────────────────

  Widget _buildRewardCard() {
    final loc = AppLocalizations.of(context);
    final hrs = _config.usageHours.toString().padLeft(2, '0');
    final mins = _config.usageMinutes.toString().padLeft(2, '0');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          Text(loc.screenTimeRewardTitle,
              style: GoogleFonts.cairo(color: const Color(0xFF1E293B), fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _showRewardTimePicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$hrs : $mins',
                      style: GoogleFonts.cairo(color: const Color(0xFF2196F3), fontSize: 32, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  const Icon(Icons.edit, color: Color(0xFF2196F3), size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(loc.screenTimeRewardDescription,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(color: const Color(0xFF64748B), fontSize: 12)),
        ],
      ),
    );
  }

  // ── Card 1b: Cooldown Period ──────────────────────────────────────────────

  Widget _buildCooldownCard() {
    final loc = AppLocalizations.of(context);
    final hrs = _config.cooldownHours.toString().padLeft(2, '0');
    final mins = _config.cooldownMinutes.toString().padLeft(2, '0');
    return GestureDetector(
      onTap: _showCooldownTimePicker,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFFCC02).withOpacity(0.5)),
          boxShadow: const [
            BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 3)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFFF9800).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.hourglass_bottom_rounded,
                color: Color(0xFFFF9800),
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.cooldownPeriodTitle,
                    style: GoogleFonts.cairo(
                      color: const Color(0xFF1E293B),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    loc.cooldownPeriodDescription,
                    style: GoogleFonts.cairo(
                      color: const Color(0xFF92400E),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$hrs : $mins',
                  style: GoogleFonts.cairo(
                    color: const Color(0xFFFF9800),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.edit, color: Color(0xFFFF9800), size: 15),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Card 2: App Rules ────────────────────────────────────────────────────

  Widget _buildAppRulesCard() {
    final loc = AppLocalizations.of(context);
    final monitored = _rules.where((r) => !r.isPaused).length;
    final paused = _rules.where((r) => r.isPaused).length;
    final total = _rules.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(loc.appRulesTitle,
                  style: GoogleFonts.cairo(color: const Color(0xFF1E293B), fontSize: 16, fontWeight: FontWeight.bold)),
              GestureDetector(
                onTap: _showAppPicker,
                child: Container(
                  width: 32, height: 32,
                  decoration: const BoxDecoration(color: Color(0xFFE3F2FD), shape: BoxShape.circle),
                  child: const Icon(Icons.add, color: Color(0xFF2196F3), size: 18),
                ),
              ),
            ],
          ),
          if (_rules.isEmpty) ...[
            const SizedBox(height: 16),
            Center(
              child: Text(loc.noAppsConfiguredHint,
                  style: GoogleFonts.cairo(color: const Color(0xFF64748B), fontSize: 13)),
            ),
          ] else ...[
            const SizedBox(height: 16),
            Row(
              children: [
                _buildRuleStatChip(Icons.visibility_rounded, loc.monitoredCountLabel(monitored),
                    const Color(0xFF2196F3), const Color(0xFFE3F2FD)),
                if (paused > 0) ...[
                  const SizedBox(width: 8),
                  _buildRuleStatChip(Icons.pause_circle_outline_rounded, loc.pausedCountLabel(paused),
                      const Color(0xFF94A3B8), const Color(0xFFF1F5F9)),
                ],
              ],
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _showAppRulesSheet,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.apps_rounded, color: Color(0xFF2196F3), size: 16),
                    const SizedBox(width: 8),
                    Text(loc.manageAllAppsLabel(total),
                        style: GoogleFonts.cairo(
                            color: const Color(0xFF2196F3), fontWeight: FontWeight.w600, fontSize: 13)),
                    const Spacer(),
                    const Icon(Icons.chevron_right_rounded, color: Color(0xFF2196F3), size: 18),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRuleStatChip(IconData icon, String label, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Future<void> _showAppRulesSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _AppRulesSheet(
        rules: List.from(_rules),
        onChanged: (updated) {
          setState(() {
            _rules
              ..clear()
              ..addAll(updated);
          });
          _markDirty();
        },
        onAddApp: () {
          Navigator.of(ctx).pop();
          _showAppPicker();
        },
      ),
    );
  }

  // ── Card 3: Quiz Settings ─────────────────────────────────────────────────

  Widget _buildQuizSettingsCard() {
    final loc = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(loc.quizSettingsTitle,
              style: GoogleFonts.cairo(color: const Color(0xFF1E293B), fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text(loc.questionsPerQuizLabel,
              style: GoogleFonts.cairo(color: const Color(0xFF1E293B), fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                _buildQuizCountSegment('Auto', loc.quizCountAutoLabel),
                _buildQuizCountSegment('3', '3'),
                _buildQuizCountSegment('5', '5'),
                _buildQuizCountSegment('10', '10'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _config.quizCount is Auto
                ? loc.quizCountAutoDescription
                : loc.quizCountFixedDescription((_config.quizCount as Fixed).count),
            style: GoogleFonts.cairo(color: const Color(0xFF64748B), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizCountSegment(String value, String displayLabel) {
    final isActive = value == 'Auto'
        ? _config.quizCount is Auto
        : _config.quizCount is Fixed && (_config.quizCount as Fixed).count == int.parse(value);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (!isActive) {
            setState(() {
              if (value == 'Auto') {
                _config = _config.copyWith(quizCount: const Auto());
              } else {
                _config = _config.copyWith(quizCount: Fixed(int.parse(value)));
              }
            });
            _markDirty();
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF2196F3) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            boxShadow: isActive
                ? [const BoxShadow(color: Color(0x1A2196F3), blurRadius: 4, offset: Offset(0, 2))]
                : null,
          ),
          child: Text(displayLabel,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                  color: isActive ? Colors.white : const Color(0xFF64748B),
                  fontWeight: FontWeight.w600, fontSize: 14)),
        ),
      ),
    );
  }

  // ── Bottom Action Buttons ─────────────────────────────────────────────────

  Widget _buildActionButtons() {
    final loc = AppLocalizations.of(context);
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () async {
              final updated = await Navigator.push<StudentModel>(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: context.read<AuthBloc>(),
                    child: ParentStudentSettingsScreen(student: _student),
                  ),
                ),
              );
              if (updated != null && mounted) {
                Navigator.of(context).pop(updated);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3), foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), elevation: 0,
            ),
            child: Text(loc.editProfileButton, style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _confirmDeleteStudent,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFE53935),
              side: const BorderSide(color: Color(0xFFE53935)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            child: Text(loc.deleteAccountTitle, style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  // ── delete student ─────────────────────────────────────────────────────────

  Future<void> _confirmDeleteStudent() async {
    final authState = context.read<AuthBloc>().state;
    final parentUid = authState is AuthAuthenticated ? authState.user.uid : '';

    final deleted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<AuthBloc>(),
        child: _DeleteStudentDialog(
          student: _student,
          parentUid: parentUid,
        ),
      ),
    );

    if (deleted == true && mounted) {
      context.read<StudentsBloc>().add(
        LoadStudentsRequested(parentUid: parentUid),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  // ── unsaved changes dialog ─────────────────────────────────────────────────

  Future<bool> _showUnsavedChangesDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) {
            final loc = AppLocalizations.of(ctx);
            return AlertDialog(
              title: Text(loc.unsavedChangesDialogTitle),
              content: Text(loc.unsavedChangesDialogContent),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: Text(loc.stayButton),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                  ),
                  child: Text(loc.leaveButton),
                ),
              ],
            );
          },
        ) ??
        false;
  }
}

// ── _DeleteStudentDialog ──────────────────────────────────────────────────────

class _DeleteStudentDialog extends StatefulWidget {
  final StudentModel student;
  final String parentUid;

  const _DeleteStudentDialog({required this.student, required this.parentUid});

  @override
  State<_DeleteStudentDialog> createState() => _DeleteStudentDialogState();
}

class _DeleteStudentDialogState extends State<_DeleteStudentDialog> {
  final _passwordCtl = TextEditingController();
  bool _obscurePassword = true;
  bool _submitted = false;
  bool _isLoading = false;
  String? _serverError;

  @override
  void dispose() {
    _passwordCtl.dispose();
    super.dispose();
  }

  String? get _passwordError {
    if (_serverError != null) return _serverError;
    if (!_submitted) return null;
    if (_passwordCtl.text.trim().isEmpty) {
      return AppLocalizations.of(context).passwordRequiredToDeleteAccountMessage;
    }
    return null;
  }

  void _submit() {
    setState(() {
      _submitted = true;
      _serverError = null;
    });
    final password = _passwordCtl.text.trim();
    if (password.isEmpty) return;

    context.read<AuthBloc>().add(
      DeleteStudentRequested(
        studentUid: widget.student.uid,
        studentEmail: widget.student.email,
        studentPassword: password,
        parentUid: widget.parentUid,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return PopScope(
      canPop: !_isLoading,
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is StudentDeleteLoading) {
            setState(() => _isLoading = true);
          } else if (state is StudentDeleted &&
              state.studentUid == widget.student.uid) {
            // Allow the dialog's PopScope to release before popping, then
            // close the dialog. The config screen awaits this result and
            // handles reloading the students list + navigating back.
            setState(() => _isLoading = false);
            Navigator.of(context).pop(true);
          } else if (state is StudentDeleteError) {
            final isWrongPassword = state.message.contains(
              'Invalid credentials',
            );
            setState(() {
              _isLoading = false;
              _serverError = isWrongPassword
                  ? loc.incorrectPasswordRetryMessage
                  : state.message;
            });
          }
        },
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.delete_forever_outlined,
                  color: Color(0xFFD32F2F),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                loc.deleteStudentDialogTitle,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF333333),
                      height: 1.5,
                    ),
                    children: [
                      TextSpan(text: loc.deleteStudentWarningPrefix),
                      TextSpan(
                        text: widget.student.fullName,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(text: loc.deleteStudentWarningSuffix),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordCtl,
                  obscureText: _obscurePassword,
                  enabled: !_isLoading,
                  onChanged: (_) {
                    if (_submitted) setState(() => _serverError = null);
                  },
                  onSubmitted: (_) {
                    if (!_isLoading) _submit();
                  },
                  decoration: InputDecoration(
                    labelText: loc.fieldStudentPassword,
                    hintText: loc.passwordYouCreatedForHint(
                      widget.student.fullName.split(' ').first,
                    ),
                    hintStyle: const TextStyle(fontSize: 12),
                    errorText: _passwordError,
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Color(0xFFD32F2F),
                        width: 1.5,
                      ),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        size: 18,
                        color: Colors.grey,
                      ),
                      onPressed: _isLoading
                          ? null
                          : () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
              child: Text(
                loc.commonCancel,
                style: const TextStyle(color: Color(0xFF666666)),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: _isLoading ? null : _submit,
              child: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(loc.deletePermanentlyButton),
            ),
          ],
        ),
      ),
    );
  }
}

// ── _GlobalTimingCard ─────────────────────────────────────────────────────────

class _GlobalTimingCard extends StatefulWidget {
  final StudentConfigModel config;
  final void Function(StudentConfigModel updated) onChanged;
  final void Function(bool hasErrors) onErrorsChanged;

  const _GlobalTimingCard({
    required this.config,
    required this.onChanged,
    required this.onErrorsChanged,
  });

  @override
  State<_GlobalTimingCard> createState() => _GlobalTimingCardState();
}

class _GlobalTimingCardState extends State<_GlobalTimingCard> {
  late TextEditingController _usageHoursCtl;
  late TextEditingController _usageMinutesCtl;
  late TextEditingController _cooldownHoursCtl;
  late TextEditingController _cooldownMinutesCtl;

  // Tracks which fields currently hold an out-of-range value so the
  // _TimeInput widget can show an inline error.
  final Map<String, String?> _errors = {
    'usageHours': null,
    'usageMinutes': null,
    'cooldownHours': null,
    'cooldownMinutes': null,
  };

  @override
  void initState() {
    super.initState();
    _usageHoursCtl = TextEditingController(
      text: widget.config.usageHours.toString(),
    );
    _usageMinutesCtl = TextEditingController(
      text: widget.config.usageMinutes.toString(),
    );
    _cooldownHoursCtl = TextEditingController(
      text: widget.config.cooldownHours.toString(),
    );
    _cooldownMinutesCtl = TextEditingController(
      text: widget.config.cooldownMinutes.toString(),
    );
  }

  @override
  void didUpdateWidget(_GlobalTimingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config != widget.config) {
      _usageHoursCtl.text = widget.config.usageHours.toString();
      _usageMinutesCtl.text = widget.config.usageMinutes.toString();
      _cooldownHoursCtl.text = widget.config.cooldownHours.toString();
      _cooldownMinutesCtl.text = widget.config.cooldownMinutes.toString();
      setState(() => _errors.updateAll((_, __) => null));
      // Defer the parent setState — calling onErrorsChanged directly here
      // triggers setState on the parent mid-build, causing the crash.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _notifyErrors();
      });
    }
  }

  @override
  void dispose() {
    _usageHoursCtl.dispose();
    _usageMinutesCtl.dispose();
    _cooldownHoursCtl.dispose();
    _cooldownMinutesCtl.dispose();
    super.dispose();
  }

  // ── validation helpers ─────────────────────────────────────────────────────

  /// Notifies the parent whether any field currently has a validation error.
  void _notifyErrors() {
    widget.onErrorsChanged(_errors.values.any((e) => e != null));
  }

  /// Returns an error string when [value] is outside [min]..[max], else null.
  String? _validateRange(String value, int min, int max) {
    final parsed = int.tryParse(value);
    if (parsed == null) return 'Must be a number';
    if (parsed < min || parsed > max) return '$min – $max';
    return null;
  }

  void _onUsageHoursChanged(String v) {
    final error = _validateRange(v, 0, 24);
    setState(() => _errors['usageHours'] = error);
    if (error == null) {
      widget.onChanged(widget.config.copyWith(usageHours: int.parse(v)));
    }
    _notifyErrors();
  }

  void _onUsageMinutesChanged(String v) {
    final error = _validateRange(v, 0, 59);
    setState(() => _errors['usageMinutes'] = error);
    if (error == null) {
      widget.onChanged(widget.config.copyWith(usageMinutes: int.parse(v)));
    }
    _notifyErrors();
  }

  void _onCooldownHoursChanged(String v) {
    final error = _validateRange(v, 0, 24);
    setState(() => _errors['cooldownHours'] = error);
    if (error == null) {
      widget.onChanged(widget.config.copyWith(cooldownHours: int.parse(v)));
    }
    _notifyErrors();
  }

  void _onCooldownMinutesChanged(String v) {
    final error = _validateRange(v, 0, 59);
    setState(() => _errors['cooldownMinutes'] = error);
    if (error == null) {
      widget.onChanged(widget.config.copyWith(cooldownMinutes: int.parse(v)));
    }
    _notifyErrors();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: const Color(0xFF4A6CF7).withOpacity(0.25)),
      ),
      color: const Color(0xFFEEF1FF),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Row(
              children: [
                const Icon(
                  Icons.tune_rounded,
                  size: 16,
                  color: Color(0xFF4A6CF7),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Global Time Limits',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4A6CF7),
                  ),
                ),
                const SizedBox(width: 4),
                Tooltip(
                  message:
                      'These limits apply to all restricted apps. '
                      'When a student reaches the usage limit on any restricted app, '
                      'they must wait the cooldown period before using it again.',
                  child: Icon(
                    Icons.help_outline,
                    size: 13,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 14),
            // ── Usage Allowance ──────────────────────────────────────────────
            Row(
              children: [
                const Icon(
                  Icons.timer_outlined,
                  size: 14,
                  color: Color(0xFF34A853),
                ),
                const SizedBox(width: 6),
                Text(
                  'Usage Allowance',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _TimeInput(
                    controller: _usageHoursCtl,
                    suffix: 'hrs',
                    hint: '0 – 24',
                    errorText: _errors['usageHours'],
                    onChanged: _onUsageHoursChanged,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TimeInput(
                    controller: _usageMinutesCtl,
                    suffix: 'min',
                    hint: '0 – 59',
                    errorText: _errors['usageMinutes'],
                    onChanged: _onUsageMinutesChanged,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            // ── Cooldown Period ──────────────────────────────────────────────
            Row(
              children: [
                const Icon(
                  Icons.hourglass_bottom_outlined,
                  size: 14,
                  color: Color(0xFFFF9800),
                ),
                const SizedBox(width: 6),
                Text(
                  'Cooldown Period',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _TimeInput(
                    controller: _cooldownHoursCtl,
                    suffix: 'hrs',
                    hint: '0 – 24',
                    errorText: _errors['cooldownHours'],
                    onChanged: _onCooldownHoursChanged,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TimeInput(
                    controller: _cooldownMinutesCtl,
                    suffix: 'min',
                    hint: '0 – 59',
                    errorText: _errors['cooldownMinutes'],
                    onChanged: _onCooldownMinutesChanged,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── _AppRulesSheet ────────────────────────────────────────────────────────────

class _AppRulesSheet extends StatefulWidget {
  final List<PendingAppRule> rules;
  final void Function(List<PendingAppRule> updated) onChanged;
  final VoidCallback onAddApp;

  const _AppRulesSheet({
    required this.rules,
    required this.onChanged,
    required this.onAddApp,
  });

  @override
  State<_AppRulesSheet> createState() => _AppRulesSheetState();
}

class _AppRulesSheetState extends State<_AppRulesSheet> {
  late List<PendingAppRule> _rules;

  @override
  void initState() {
    super.initState();
    _rules = List.from(widget.rules);
  }

  void _toggle(int index, bool isMonitored) {
    setState(() => _rules[index] = _rules[index].copyWith(isPaused: !isMonitored));
    widget.onChanged(_rules);
  }

  Future<void> _confirmRemove(int index) async {
    final rule = _rules[index];
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final loc = AppLocalizations.of(dialogContext);
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  loc.removeAppConfirmTitle(rule.appLabel),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold, color: const Color(0xFF1E293B), fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  loc.removeAppConfirmMessage,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(color: const Color(0xFF64748B), fontSize: 14),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.of(dialogContext).pop(false),
                        child: Container(
                          decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(24)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(loc.commonCancel,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.bold, color: const Color(0xFF64748B))),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.of(dialogContext).pop(true),
                        child: Container(
                          decoration: BoxDecoration(
                              color: const Color(0xFFE53935),
                              borderRadius: BorderRadius.circular(24)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(loc.removeButton,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    if (confirm == true) {
      setState(() => _rules.removeAt(index));
      widget.onChanged(_rules);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final monitored = _rules.where((r) => !r.isPaused).length;
    final paused = _rules.where((r) => r.isPaused).length;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (ctx, scrollCtl) => Column(
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 8, bottom: 8),
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(4)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(loc.appRulesTitle,
                        style: GoogleFonts.cairo(
                            color: const Color(0xFF1E293B),
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                    Text(loc.monitoredAndPausedLabel(monitored, paused),
                        style: GoogleFonts.cairo(
                            color: const Color(0xFF64748B), fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _rules.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.apps_outlined, size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(loc.noAppsConfiguredTitle,
                            style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Text(loc.tapAddAppHint,
                            style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                      ],
                    ),
                  )
                : ListView.separated(
                    controller: scrollCtl,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _rules.length,
                    separatorBuilder: (_, __) => const Divider(
                        height: 1, color: Color(0xFFF1F5F9), indent: 16, endIndent: 16),
                    itemBuilder: (_, i) {
                      final rule = _rules[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(10)),
                              child: Center(
                                child: Text(
                                  rule.appLabel.isNotEmpty
                                      ? rule.appLabel[0].toUpperCase()
                                      : '?',
                                  style: GoogleFonts.cairo(
                                      color: const Color(0xFF2196F3),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(rule.appLabel,
                                      style: GoogleFonts.cairo(
                                          color: const Color(0xFF1E293B),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14)),
                                  Text(
                                    rule.isPaused ? loc.appStatusPaused : loc.appStatusMonitored,
                                    style: GoogleFonts.cairo(
                                      color: rule.isPaused
                                          ? const Color(0xFF94A3B8)
                                          : const Color(0xFF34A853),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              height: 24,
                              child: Switch(
                                value: !rule.isPaused,
                                onChanged: (isOn) => _toggle(i, isOn),
                                activeColor: const Color(0xFF2196F3),
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () => _confirmRemove(i),
                              child: const Icon(Icons.delete_outline,
                                  color: Color(0xFFE53935), size: 20),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Color(0x0D000000), blurRadius: 12, offset: Offset(0, -4))
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: widget.onAddApp,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(loc.addAppButton,
                  style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── _AppPickerSheet ───────────────────────────────────────────────────────────

class _AppPickerSheet extends StatefulWidget {
  final List<InstalledAppModel> availableApps;
  final void Function(List<InstalledAppModel> selected) onAppsSelected;

  const _AppPickerSheet({
    required this.availableApps,
    required this.onAppsSelected,
  });

  @override
  State<_AppPickerSheet> createState() => _AppPickerSheetState();
}

class _AppPickerSheetState extends State<_AppPickerSheet> {
  final Set<String> _selectedPackages = {};
  final TextEditingController _searchCtl = TextEditingController();
  String _query = '';
  bool _submitted = false;

  /// false = "Installed Apps" (user-installed only)
  /// true  = "All Apps"       (user-installed + system)
  bool _showSystemApps = false;

  static const double _buttonHeight = 32;
  static const EdgeInsets _buttonPadding = EdgeInsets.symmetric(horizontal: 10);
  static const BorderRadius _buttonRadius = BorderRadius.all(
    Radius.circular(8),
  );
  static const TextStyle _buttonTextStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  List<InstalledAppModel> get _filtered {
    final afterFilter = _showSystemApps
        ? widget.availableApps
        : widget.availableApps.where((a) => !a.isSystemApp).toList();

    if (_query.isEmpty) return afterFilter;
    final q = _query.toLowerCase();
    return afterFilter
        .where(
          (a) =>
              a.appLabel.toLowerCase().contains(q) ||
              a.packageName.toLowerCase().contains(q),
        )
        .toList();
  }

  Widget _buildFilterButton() {
    final loc = AppLocalizations.of(context);
    return GestureDetector(
      onTapDown: (details) async {
        final origin = details.globalPosition;
        final selected = await showMenu<bool>(
          context: context,
          position: RelativeRect.fromLTRB(
            origin.dx,
            origin.dy,
            origin.dx + 1,
            origin.dy + 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          items: [
            _filterMenuItem(
              value: false,
              icon: Icons.apps_rounded,
              label: loc.installedAppsFilterLabel,
              subtitle: loc.installedAppsFilterSubtitle,
              isSelected: !_showSystemApps,
            ),
            _filterMenuItem(
              value: true,
              icon: Icons.phone_android_rounded,
              label: loc.allAppsFilterLabel,
              subtitle: loc.allAppsFilterSubtitle,
              isSelected: _showSystemApps,
            ),
          ],
        );
        if (selected != null && selected != _showSystemApps) {
          setState(() {
            _showSystemApps = selected;
            _selectedPackages.removeWhere(
              (pkg) => !_filtered.any((a) => a.packageName == pkg),
            );
          });
        }
      },
      child: Container(
        height: _buttonHeight,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFE3F2FD),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _showSystemApps
                  ? Icons.phone_android_rounded
                  : Icons.apps_rounded,
              size: 14,
              color: const Color(0xFF2196F3),
            ),
            const SizedBox(width: 5),
            Text(
              _showSystemApps ? loc.allAppsFilterLabel : loc.installedAppsFilterLabel,
              overflow: TextOverflow.ellipsis,
              style: _buttonTextStyle.copyWith(
                color: const Color(0xFF2196F3),
              ),
            ),
            const SizedBox(width: 3),
            const Icon(
              Icons.arrow_drop_down_rounded,
              size: 16,
              color: Color(0xFF2196F3),
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<bool> _filterMenuItem({
    required bool value,
    required IconData icon,
    required String label,
    required String subtitle,
    required bool isSelected,
  }) {
    return PopupMenuItem<bool>(
      value: value,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF4A6CF7)
                  : const Color(0xFFE8EDFF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : const Color(0xFF4A6CF7),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? const Color(0xFF4A6CF7)
                        : const Color(0xFF1A1A2E),
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          if (isSelected)
            const Icon(Icons.check_rounded, size: 16, color: Color(0xFF4A6CF7)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (ctx, scrollCtl) => Column(
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 8, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  loc.selectAppsTitle,
                  style: GoogleFonts.cairo(
                    color: const Color(0xFF1E293B),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildFilterButton(),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchCtl,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: loc.searchAppsHint,
                hintStyle: const TextStyle(color: Color(0xFF64748B)),
                prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF64748B)),
                isDense: true,
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _filtered.isEmpty
                ? _buildEmptyFilterState()
                : ListView.builder(
                    controller: scrollCtl,
                    itemCount: _filtered.length,
                    itemBuilder: (ctx, i) {
                      final app = _filtered[i];
                      final selected = _selectedPackages.contains(
                        app.packageName,
                      );
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => setState(() {
                          if (selected) {
                            _selectedPackages.remove(app.packageName);
                          } else {
                            _selectedPackages.add(app.packageName);
                          }
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1),
                            ),
                          ),
                          child: Row(
                            children: [
                              _AppLetterAvatar(label: app.appLabel),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      app.appLabel,
                                      style: const TextStyle(
                                        color: Color(0xFF1E293B),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      app.packageName,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: selected ? const Color(0xFF2196F3) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                  border: selected ? null : Border.all(color: const Color(0xFFCBD5E1), width: 2),
                                ),
                                child: selected
                                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color(0x0D000000),
                  blurRadius: 12,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_submitted || _selectedPackages.isEmpty)
                    ? null
                    : () {
                        if (_submitted) return;
                        setState(() => _submitted = true);
                        final selected = widget.availableApps
                            .where((a) => _selectedPackages.contains(a.packageName))
                            .toList();
                        Navigator.of(context).pop();
                        widget.onAppsSelected(selected);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFF2196F3).withOpacity(0.5),
                  disabledForegroundColor: Colors.white.withOpacity(0.8),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  loc.addSelectedButton,
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFilterState() {
    final loc = AppLocalizations.of(context);
    final isSearchActive = _query.isNotEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSearchActive ? Icons.search_off_rounded : Icons.apps_outlined,
              size: 48,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 12),
            Text(
              isSearchActive
                  ? loc.noAppsMatchQuery(_query)
                  : loc.noUserInstalledAppsFound,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 6),
            if (!isSearchActive)
              GestureDetector(
                onTap: () => setState(() => _showSystemApps = true),
                child: Text(
                  loc.switchToAllAppsHint,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF4A6CF7),
                    decoration: TextDecoration.underline,
                    decorationColor: Color(0xFF4A6CF7),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── _AppLetterAvatar ──────────────────────────────────────────────────────────

class _AppLetterAvatar extends StatelessWidget {
  final String label;
  const _AppLetterAvatar({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          label.isNotEmpty ? label[0].toUpperCase() : '?',
          style: GoogleFonts.cairo(
            color: const Color(0xFF2196F3),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

// ── _AppRuleCard ──────────────────────────────────────────────────────────────

class _AppRuleCard extends StatelessWidget {
  final PendingAppRule rule;
  final VoidCallback onRemove;

  const _AppRuleCard({required this.rule, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        child: Row(
          children: [
            _AppLetterAvatar(label: rule.appLabel),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rule.appLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    rule.packageName,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                color: Colors.red.shade400,
                size: 20,
              ),
              tooltip: 'Remove',
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}

// ── _TimeInput ────────────────────────────────────────────────────────────────

class _TimeInput extends StatelessWidget {
  final TextEditingController controller;
  final String suffix;

  /// Placeholder shown inside the field (e.g. "0 – 24").
  final String hint;

  /// Non-null when the current value is out of range.
  final String? errorText;

  final ValueChanged<String> onChanged;

  const _TimeInput({
    required this.controller,
    required this.suffix,
    required this.hint,
    required this.onChanged,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;

    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: onChanged,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        isDense: true,
        hintText: hint,
        hintStyle: TextStyle(fontSize: 11, color: Colors.grey.shade400),
        errorText: errorText,
        errorStyle: const TextStyle(fontSize: 10, height: 1.2),
        errorMaxLines: 1,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: hasError ? Colors.red.shade400 : Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: hasError ? Colors.red.shade600 : const Color(0xFF4A6CF7),
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.red.shade400),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.red.shade600, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 10,
        ),
        suffixText: suffix,
        suffixStyle: TextStyle(
          fontSize: 11,
          color: hasError ? Colors.red.shade400 : Colors.grey.shade500,
        ),
      ),
    );
  }
}

// ── _QuickActionButton ────────────────────────────────────────────────────────

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDestructive;
  final bool isLoading;
  final VoidCallback? onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.isDestructive = false,
    this.isLoading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isDestructive
        ? Colors.red.shade50
        : const Color(0xFFE8EDFF);

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              isLoading
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: color,
                      ),
                    )
                  : Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SetRewardTimeSheet extends StatefulWidget {
  final int initialHours;
  final int initialMinutes;
  final String? title;

  const _SetRewardTimeSheet({
    required this.initialHours,
    required this.initialMinutes,
    this.title,
  });

  @override
  State<_SetRewardTimeSheet> createState() => _SetRewardTimeSheetState();
}

class _SetRewardTimeSheetState extends State<_SetRewardTimeSheet> {
  late int _hours;
  late int _minutes;
  int _pickerKeyIndex = 0;

  @override
  void initState() {
    super.initState();
    _hours = widget.initialHours;
    _minutes = widget.initialMinutes;
  }

  void _selectPreset(int h, int m) {
    setState(() {
      _hours = h;
      _minutes = m;
      _pickerKeyIndex++;
    });
  }

  bool _isPresetSelected(int h, int m) {
    return _hours == h && _minutes == m;
  }

  Widget _buildPresetChip(String label, int h, int m) {
    final bool isSelected = _isPresetSelected(h, m);
    return InkWell(
      onTap: () => _selectPreset(h, m),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE3F2FD) : const Color(0xFFF8FAFC),
          border: Border.all(
            color: isSelected ? const Color(0xFF2196F3) : const Color(0xFFE2E8F0),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.cairo(
            color: isSelected ? const Color(0xFF2196F3) : const Color(0xFF64748B),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Text(
                widget.title ?? loc.setRewardTimeTitle,
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildPresetChip(loc.presetMinutesLabel(10), 0, 10),
                      _buildPresetChip(loc.presetMinutesLabel(15), 0, 15),
                      _buildPresetChip(loc.presetMinutesLabel(30), 0, 30),
                      _buildPresetChip(loc.preset1HourLabel, 1, 0),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 180,
                    child: CupertinoTheme(
                      data: CupertinoThemeData(
                        textTheme: CupertinoTextThemeData(
                          pickerTextStyle: GoogleFonts.cairo(
                            fontSize: 20,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                      ),
                      child: CupertinoTimerPicker(
                        key: ValueKey(_pickerKeyIndex),
                        mode: CupertinoTimerPickerMode.hm,
                        initialTimerDuration: Duration(hours: _hours, minutes: _minutes),
                        onTimerDurationChanged: (duration) {
                          setState(() {
                            _hours = duration.inHours;
                            _minutes = duration.inMinutes % 60;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop({'hours': _hours, 'minutes': _minutes});
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                  ),
                  child: Text(
                    loc.saveTimeButton,
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
