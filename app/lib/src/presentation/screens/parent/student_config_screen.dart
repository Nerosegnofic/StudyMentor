// lib/src/presentation/screens/parent/student_config_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/auth/auth_bloc.dart';
import '../../../bloc/auth/auth_event.dart';
import '../../../bloc/auth/auth_state.dart';
import '../../../domain/models/app_config_model.dart';
import '../../../domain/models/student_model.dart';
import '../../../domain/models/installed_app_model.dart';
import '../../../bloc/document/document_upload_bloc.dart';
import '../../../data/repositories/ai_engine_repository.dart';
import '../student/student_documents.dart';
import 'parent_student_settings_screen.dart';

class StudentConfigScreen extends StatefulWidget {
  final StudentModel student;

  const StudentConfigScreen({super.key, required this.student});

  @override
  State<StudentConfigScreen> createState() => _StudentConfigScreenState();
}

class _StudentConfigScreenState extends State<StudentConfigScreen> {
  final List<PendingAppRule> _rules = [];
  StudentConfigModel _config = const StudentConfigModel();

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
    context.read<AuthBloc>().add(
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
        PendingAppRule(packageName: r.packageName, appLabel: r.appLabel),
      );
    }
  }

  void _markDirty() {
    if (!_isDirty) setState(() => _isDirty = true);
  }

  void _save() {
    context.read<AuthBloc>().add(
      SaveAppRulesRequested(
        studentUid: widget.student.uid,
        rules: List.of(_rules),
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
        builder: (ctx) => AlertDialog(
          title: const Text('Unsaved Changes'),
          content: const Text(
            'Refreshing will discard your unsaved changes. Continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade600,
              ),
              child: const Text('Discard & Refresh'),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }

    context.read<AuthBloc>().add(
      RefreshStudentDataRequested(studentUid: widget.student.uid),
    );
  }

  // ── app picker sheet ───────────────────────────────────────────────────────

  Future<void> _showAppPicker() async {
    if (_appsLoading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Still loading app list — please wait.')),
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
            '${widget.student.fullName.split(' ').first}\'s device hasn\'t synced yet. '
            'Ask them to open the app once.',
          ),
        ),
      );
      return;
    }

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All installed apps have already been configured.'),
        ),
      );
      return;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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

  // ── remove a rule ──────────────────────────────────────────────────────────

  void _removeRule(int index) {
    setState(() => _rules.removeAt(index));
    _markDirty();
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
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

        // ── Installed apps loaded (initial load OR after refresh) ──────────
        if (state is InstalledAppsLoaded &&
            state.studentUid == widget.student.uid) {
          setState(() {
            _installedApps = state.apps;
            _appsLoading = false;
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
            const SnackBar(
              content: Text('Configuration saved successfully.'),
              backgroundColor: Color(0xFF34A853),
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

        // The dialog handles StudentDeleteLoading and StudentDeleteError
        // internally. The screen only needs to react to StudentDeleted so it
        // can pop back to the parent students list.
        if (state is StudentDeleted && state.studentUid == widget.student.uid) {
          if (mounted) Navigator.of(context).pop();
        }
      },
      child: PopScope(
        canPop: !_isDirty,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          final leave = await _showUnsavedChangesDialog();
          if (leave && context.mounted) Navigator.of(context).pop();
        },
        child: Scaffold(
          backgroundColor: const Color(0xFFF5F7FF),
          appBar: _buildAppBar(),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildBody(),
          floatingActionButton: (!_isLoading && _rules.isNotEmpty)
              ? FloatingActionButton.extended(
                  onPressed: _showAppPicker,
                  icon: const Icon(Icons.add),
                  label: const Text('Add App'),
                  backgroundColor: const Color(0xFF4A6CF7),
                  foregroundColor: Colors.white,
                )
              : null,
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    final canSave = _isDirty && !_isSaving && !_hasTimingErrors;

    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'App Configuration',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          Text(
            widget.student.fullName,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ],
      ),
      actions: [
        // ── Refresh button ─────────────────────────────────────────────────
        Tooltip(
          message: 'Refresh apps & rules',
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _isRefreshing
                ? const Padding(
                    key: ValueKey('spinner'),
                    padding: EdgeInsets.symmetric(horizontal: 14),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF4A6CF7),
                      ),
                    ),
                  )
                : IconButton(
                    key: const ValueKey('refresh'),
                    icon: const Icon(Icons.refresh_rounded),
                    color: _isSaving
                        ? Colors.grey.shade400
                        : const Color(0xFF4A6CF7),
                    onPressed: _isSaving ? null : _refresh,
                  ),
          ),
        ),
        // ── Save button ────────────────────────────────────────────────────
        AnimatedOpacity(
          opacity: canSave ? 1.0 : 0.3,
          duration: const Duration(milliseconds: 200),
          child: TextButton.icon(
            onPressed: canSave ? _save : null,
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF4A6CF7),
                    ),
                  )
                : const Icon(Icons.save_outlined, color: Color(0xFF4A6CF7)),
            label: const Text(
              'Save',
              style: TextStyle(
                color: Color(0xFF4A6CF7),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        // ── Global timing card — always visible when not loading ───────────
        _GlobalTimingCard(
          config: _config,
          onChanged: (updated) {
            setState(() => _config = updated);
            _markDirty();
          },
          onErrorsChanged: (hasErrors) {
            setState(() => _hasTimingErrors = hasErrors);
          },
        ),
        // ── Quick-action row: Settings ────────────────────────────────────
        _buildQuickActions(),
        // ── App rules list or empty state ──────────────────────────────────
        Expanded(
          child: _rules.isEmpty ? _buildEmptyState() : _buildRulesList(),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Column(
        children: [
          // ── Row 1: profile actions ─────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.manage_accounts_outlined,
                  label: 'Edit Profile',
                  color: const Color(0xFF1E88E5),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BlocProvider.value(
                        value: context.read<AuthBloc>(),
                        child: ParentStudentSettingsScreen(
                          student: widget.student,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.delete_outline_rounded,
                  label: 'Delete Account',
                  color: Colors.red.shade600,
                  isDestructive: true,
                  onTap: _confirmDeleteStudent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // ── Row 2: document upload ─────────────────────────────────────
          _QuickActionButton(
            icon: Icons.upload_file_outlined,
            label: 'Upload Curriculum Docs',
            color: const Color(0xFF43A047),
            onTap: _openDocumentUpload,
          ),
        ],
      ),
    );
  }

  // ── empty state ────────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8EDFF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.app_settings_alt_outlined,
                  size: 40,
                  color: Color(0xFF4A6CF7),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'No App Rules Yet',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add apps below to restrict which apps '
                '${widget.student.fullName.split(' ').first} can use. '
                'The time limits above apply to all restricted apps.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _showAppPicker,
                icon: _appsLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.add),
                label: const Text(
                  'Add Apps',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF4A6CF7),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── rules list ─────────────────────────────────────────────────────────────

  Widget _buildRulesList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: _rules.length,
      itemBuilder: (ctx, i) =>
          _AppRuleCard(rule: _rules[i], onRemove: () => _removeRule(i)),
    );
  }

  // ── document upload ────────────────────────────────────────────────────────

  static const _kAiEngineBaseUrl = 'http://192.168.100.18:8000';

  void _openDocumentUpload() {
    final repo = AiEngineRepository(baseUrl: _kAiEngineBaseUrl);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => DocumentUploadBloc(repository: repo),
          child: Scaffold(
            backgroundColor: const Color(0xFFF5F7FF),
            appBar: AppBar(
              title: const Text(
                'Upload Curriculum',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            body: StudentDocumentUploadScreen(studentUid: widget.student.uid),
          ),
        ),
      ),
    );
  }

  // ── delete student ─────────────────────────────────────────────────────────

  Future<void> _confirmDeleteStudent() async {
    final authState = context.read<AuthBloc>().state;
    final parentUid = authState is AuthAuthenticated ? authState.user.uid : '';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<AuthBloc>(),
        child: _DeleteStudentDialog(
          student: widget.student,
          parentUid: parentUid,
        ),
      ),
    );
  }

  // ── unsaved changes dialog ─────────────────────────────────────────────────

  Future<bool> _showUnsavedChangesDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Unsaved Changes'),
            content: const Text(
              'You have unsaved changes. Leave without saving?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Stay'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                ),
                child: const Text('Leave'),
              ),
            ],
          ),
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
      return 'Password is required to delete the account.';
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
    return PopScope(
      canPop: !_isLoading,
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is StudentDeleteLoading) {
            setState(() => _isLoading = true);
          } else if (state is StudentDeleted &&
              state.studentUid == widget.student.uid) {
            Navigator.of(context).pop();
          } else if (state is StudentDeleteError) {
            final isWrongPassword = state.message.contains(
              'Invalid credentials',
            );
            setState(() {
              _isLoading = false;
              _serverError = isWrongPassword
                  ? 'Incorrect password. Please try again.'
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
              const Text(
                'Delete Student',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
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
                      const TextSpan(text: 'This will permanently delete '),
                      TextSpan(
                        text: widget.student.fullName,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const TextSpan(
                        text:
                            '\'s account — progress, items, friends, and settings. '
                            'This cannot be undone.',
                      ),
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
                    labelText: 'Student\'s Password',
                    hintText:
                        'Password you created for '
                        '${widget.student.fullName.split(' ').first}',
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
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFF666666)),
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
                  : const Text('Delete Permanently'),
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
              label: 'Installed Apps',
              subtitle: 'Apps downloaded by the student',
              isSelected: !_showSystemApps,
            ),
            _filterMenuItem(
              value: true,
              icon: Icons.phone_android_rounded,
              label: 'All Apps',
              subtitle: 'Includes system & pre-installed apps',
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
        width: double.infinity,
        padding: _buttonPadding,
        decoration: BoxDecoration(
          color: const Color(0xFFE8EDFF),
          borderRadius: _buttonRadius,
          border: Border.all(color: const Color.fromRGBO(74, 108, 247, 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _showSystemApps
                  ? Icons.phone_android_rounded
                  : Icons.apps_rounded,
              size: 14,
              color: const Color(0xFF4A6CF7),
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                _showSystemApps ? 'All Apps' : 'Installed Apps',
                overflow: TextOverflow.ellipsis,
                style: _buttonTextStyle.copyWith(
                  color: const Color(0xFF4A6CF7),
                ),
              ),
            ),
            const SizedBox(width: 3),
            const Icon(
              Icons.arrow_drop_down_rounded,
              size: 16,
              color: Color(0xFF4A6CF7),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return FilledButton(
      onPressed: _submitted
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
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF4A6CF7),
        foregroundColor: Colors.white,
        fixedSize: const Size.fromHeight(_buttonHeight),
        minimumSize: const Size(0, _buttonHeight),
        padding: _buttonPadding,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        shape: const RoundedRectangleBorder(borderRadius: _buttonRadius),
      ),
      child: Text(
        'Add (${_selectedPackages.length})',
        style: _buttonTextStyle,
        overflow: TextOverflow.ellipsis,
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
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (ctx, scrollCtl) => Column(
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text(
                  'Select Apps',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(child: _buildFilterButton()),
                      if (_selectedPackages.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Expanded(child: _buildAddButton()),
                      ],
                    ],
                  ),
                ),
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
                hintText: 'Search apps…',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
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
                      return ListTile(
                        leading: _AppLetterAvatar(label: app.appLabel),
                        title: Text(
                          app.appLabel,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          app.packageName,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        trailing: Checkbox(
                          value: selected,
                          activeColor: const Color(0xFF4A6CF7),
                          onChanged: (_) => setState(() {
                            if (selected) {
                              _selectedPackages.remove(app.packageName);
                            } else {
                              _selectedPackages.add(app.packageName);
                            }
                          }),
                        ),
                        onTap: () => setState(() {
                          if (selected) {
                            _selectedPackages.remove(app.packageName);
                          } else {
                            _selectedPackages.add(app.packageName);
                          }
                        }),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFilterState() {
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
                  ? 'No apps match "$_query"'
                  : 'No user-installed apps found',
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
                child: const Text(
                  'Switch to All Apps to see system apps',
                  textAlign: TextAlign.center,
                  style: TextStyle(
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
    return CircleAvatar(
      backgroundColor: const Color(0xFFE8EDFF),
      radius: 20,
      child: Text(
        label.isNotEmpty ? label[0].toUpperCase() : '?',
        style: const TextStyle(
          color: Color(0xFF4A6CF7),
          fontWeight: FontWeight.w700,
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
