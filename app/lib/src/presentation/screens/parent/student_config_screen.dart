// lib/src/presentation/screens/parent/student_config_screen.dart
//
// Opened when a parent taps a verified student card.
// Flow:
//   1. Screen loads — fetches saved rules AND the student's installed-app
//      inventory from DataConnect in parallel.
//   2. If no rules exist yet, a prominent "Add Configuration" button is shown.
//   3. Parent taps "Add App" → bottom sheet shows the student's real installed
//      apps (populated from their device, not a mock list).
//   4. Parent selects app(s), configures usage + cooldown, taps Save.
//   5. Rules are saved to DataConnect; screen shows a success snackbar.

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/auth/auth_bloc.dart';
import '../../../bloc/auth/auth_event.dart';
import '../../../bloc/auth/auth_state.dart';
import '../../../domain/models/app_config_model.dart';
import '../../../domain/models/student_model.dart';
import '../../../domain/models/installed_app_model.dart';

class StudentConfigScreen extends StatefulWidget {
  final StudentModel student;

  const StudentConfigScreen({super.key, required this.student});

  @override
  State<StudentConfigScreen> createState() => _StudentConfigScreenState();
}

class _StudentConfigScreenState extends State<StudentConfigScreen> {
  // Rules currently shown in the UI (loaded from DB or newly added).
  final List<PendingAppRule> _rules = [];

  // Installed apps for the picker — loaded from DataConnect.
  List<InstalledAppModel> _installedApps = [];
  bool _appsLoading = true;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isDirty = false;

  // Packages already in _rules, used to filter the app-picker.
  Set<String> get _configuredPackages =>
      _rules.map((r) => r.packageName).toSet();

  @override
  void initState() {
    super.initState();
    context
        .read<AuthBloc>()
        .add(LoadAppRulesRequested(studentUid: widget.student.uid));
    context
        .read<AuthBloc>()
        .add(LoadInstalledAppsForStudentRequested(studentUid: widget.student.uid));
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  void _loadRulesFromSaved(List<AppRuleModel> saved) {
    _rules.clear();
    for (final r in saved) {
      // Try to find the icon from the already-loaded installed apps list.
      final icon = _installedApps
          .where((a) => a.packageName == r.packageName)
          .firstOrNull
          ?.iconBase64;

      _rules.add(PendingAppRule(
        packageName: r.packageName,
        appLabel: r.appLabel,
        iconBase64: icon,
        usageHours: r.usageHours,
        usageMinutes: r.usageMinutes,
        cooldownHours: r.cooldownHours,
        cooldownMinutes: r.cooldownMinutes,
      ));
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
          ),
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

    // Deduplicate by package name — the DB can have multiple rows for the
    // same package if two syncs ran concurrently.
    final seen = <String>{};
    final available = _installedApps
        .where((a) =>
            !_configuredPackages.contains(a.packageName) &&
            seen.add(a.packageName))
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
            content: Text('All installed apps have already been configured.')),
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
            // Use a growing set to catch both DB duplicates and rapid
            // double-taps — only the first occurrence of each package is added.
            final alreadyConfigured = _configuredPackages;
            for (final app in selected) {
              if (alreadyConfigured.add(app.packageName)) {
                _rules.add(PendingAppRule(
                  packageName: app.packageName,
                  appLabel: app.appLabel,
                  iconBase64: app.iconBase64,
                ));
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
        if (state is AppRulesLoaded &&
            state.studentUid == widget.student.uid) {
          setState(() {
            _loadRulesFromSaved(state.rules);
            _isLoading = false;
            _isDirty = false;
          });
        }

        if (state is InstalledAppsLoaded &&
            state.studentUid == widget.student.uid) {
          setState(() {
            _installedApps = state.apps;
            _appsLoading = false;
            // If rules were already loaded, re-map them to get icons.
            if (!_isLoading) {
              for (var i = 0; i < _rules.length; i++) {
                final r = _rules[i];
                if (r.iconBase64 == null) {
                  final icon = state.apps
                      .where((a) => a.packageName == r.packageName)
                      .firstOrNull
                      ?.iconBase64;
                  if (icon != null) {
                    _rules[i] = PendingAppRule(
                      packageName: r.packageName,
                      appLabel: r.appLabel,
                      iconBase64: icon,
                      usageHours: r.usageHours,
                      usageMinutes: r.usageMinutes,
                      cooldownHours: r.cooldownHours,
                      cooldownMinutes: r.cooldownMinutes,
                    );
                  }
                }
              }
            }
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
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red.shade700,
            ),
          );
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
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('App Configuration',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          Text(
            widget.student.fullName,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ],
      ),
      actions: [
        AnimatedOpacity(
          opacity: (_isDirty && !_isSaving) ? 1.0 : 0.3,
          duration: const Duration(milliseconds: 200),
          child: TextButton.icon(
            onPressed: (_isDirty && !_isSaving) ? _save : null,
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Color(0xFF4A6CF7)),
                  )
                : const Icon(Icons.save_outlined, color: Color(0xFF4A6CF7)),
            label: const Text('Save',
                style: TextStyle(
                    color: Color(0xFF4A6CF7), fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_rules.isEmpty) {
      return _buildEmptyState();
    }
    return _buildRulesList();
  }

  // ── empty state ────────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFE8EDFF),
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
              'Add app rules to control how long ${widget.student.fullName.split(' ').first} can use each app and how long they must wait before using it again.',
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
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.add),
              label: const Text(
                'Add Configuration',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF4A6CF7),
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── rules list ─────────────────────────────────────────────────────────────

  Widget _buildRulesList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: _rules.length,
      itemBuilder: (ctx, i) => _AppRuleCard(
        rule: _rules[i],
        onRemove: () => _removeRule(i),
        onChanged: () => _markDirty(),
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
                'You have unsaved changes. Leave without saving?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Stay')),
              FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  style: FilledButton.styleFrom(
                      backgroundColor: Colors.red.shade600),
                  child: const Text('Leave')),
            ],
          ),
        ) ??
        false;
  }
}

// ── _AppPickerSheet ────────────────────────────────────────────────────────

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
  bool _submitted = false; // prevents double-tap on "Add"

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  List<InstalledAppModel> get _filtered {
    if (_query.isEmpty) return widget.availableApps;
    final q = _query.toLowerCase();
    return widget.availableApps
        .where((a) =>
            a.appLabel.toLowerCase().contains(q) ||
            a.packageName.toLowerCase().contains(q))
        .toList();
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
          // Handle
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
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Text('Select Apps',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700)),
                const Spacer(),
                if (_selectedPackages.isNotEmpty)
                  FilledButton(
                    onPressed: _submitted
                        ? null
                        : () {
                            if (_submitted) return;
                            setState(() => _submitted = true);
                            final selected = widget.availableApps
                                .where((a) =>
                                    _selectedPackages.contains(a.packageName))
                                .toList();
                            Navigator.of(context).pop();
                            widget.onAppsSelected(selected);
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF4A6CF7),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text('Add (${_selectedPackages.length})'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Search
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
                    borderRadius: BorderRadius.circular(10)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // List
          Expanded(
            child: ListView.builder(
              controller: scrollCtl,
              itemCount: _filtered.length,
              itemBuilder: (ctx, i) {
                final app = _filtered[i];
                final selected = _selectedPackages.contains(app.packageName);
                return ListTile(
                  leading: _AppIcon(iconBase64: app.iconBase64, label: app.appLabel),
                  title: Text(app.appLabel,
                      style:
                          const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(app.packageName,
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade500)),
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
}

// ── _AppIcon ──────────────────────────────────────────────────────────────────
// Shows the real launcher icon if iconBase64 is available, otherwise falls
// back to a letter-avatar. Keeps the picker fast — no network calls needed.

class _AppIcon extends StatelessWidget {
  final String? iconBase64;
  final String label;
  const _AppIcon({required this.iconBase64, required this.label});

  @override
  Widget build(BuildContext context) {
    if (iconBase64 != null && iconBase64!.isNotEmpty) {
      try {
        return CircleAvatar(
          backgroundImage: MemoryImage(base64Decode(iconBase64!)),
          backgroundColor: const Color(0xFFE8EDFF),
          radius: 20,
        );
      } catch (_) {
        // Fall through to letter avatar if decoding fails.
      }
    }
    return CircleAvatar(
      backgroundColor: const Color(0xFFE8EDFF),
      radius: 20,
      child: Text(
        label[0].toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF4A6CF7),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ── _AppRuleCard ─────────────────────────────────────────────────────────────

class _AppRuleCard extends StatefulWidget {
  final PendingAppRule rule;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const _AppRuleCard({
    required this.rule,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  State<_AppRuleCard> createState() => _AppRuleCardState();
}

class _AppRuleCardState extends State<_AppRuleCard> {
  late TextEditingController _usageHoursCtl;
  late TextEditingController _usageMinutesCtl;
  late TextEditingController _cooldownHoursCtl;
  late TextEditingController _cooldownMinutesCtl;

  @override
  void initState() {
    super.initState();
    _usageHoursCtl = TextEditingController(text: widget.rule.usageHours.toString());
    _usageMinutesCtl = TextEditingController(text: widget.rule.usageMinutes.toString());
    _cooldownHoursCtl = TextEditingController(text: widget.rule.cooldownHours.toString());
    _cooldownMinutesCtl = TextEditingController(text: widget.rule.cooldownMinutes.toString());
  }

  @override
  void dispose() {
    _usageHoursCtl.dispose();
    _usageMinutesCtl.dispose();
    _cooldownHoursCtl.dispose();
    _cooldownMinutesCtl.dispose();
    super.dispose();
  }

  void _onUsageHoursChanged(String v) {
    final parsed = int.tryParse(v);
    if (parsed != null && parsed >= 0) {
      widget.rule.usageHours = parsed;
      widget.onChanged();
    }
  }

  void _onUsageMinutesChanged(String v) {
    final parsed = int.tryParse(v);
    if (parsed != null && parsed >= 0) {
      widget.rule.usageMinutes = parsed;
      widget.onChanged();
    }
  }

  void _onCooldownHoursChanged(String v) {
    final parsed = int.tryParse(v);
    if (parsed != null && parsed >= 0) {
      widget.rule.cooldownHours = parsed;
      widget.onChanged();
    }
  }

  void _onCooldownMinutesChanged(String v) {
    final parsed = int.tryParse(v);
    if (parsed != null && parsed >= 0) {
      widget.rule.cooldownMinutes = parsed;
      widget.onChanged();
    }
  }

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App name row
            Row(
              children: [
                _AppIcon(
                    iconBase64: widget.rule.iconBase64,
                    label: widget.rule.appLabel),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.rule.appLabel,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15)),
                      Text(widget.rule.packageName,
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade500),
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline,
                      color: Colors.red.shade400, size: 20),
                  tooltip: 'Remove',
                  onPressed: widget.onRemove,
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 14),
            // Usage allowance
            Row(
              children: [
                const Icon(Icons.timer_outlined, size: 14, color: Color(0xFF34A853)),
                const SizedBox(width: 6),
                Text('Usage Allowance',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700)),
                const SizedBox(width: 4),
                Tooltip(
                  message: 'Total time the student can use this app cumulatively before being locked out.',
                  child: Icon(Icons.help_outline, size: 13, color: Colors.grey.shade400),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _TimeInput(
                    controller: _usageHoursCtl,
                    suffix: 'hrs',
                    onChanged: _onUsageHoursChanged,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TimeInput(
                    controller: _usageMinutesCtl,
                    suffix: 'min',
                    onChanged: _onUsageMinutesChanged,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            // Cooldown period
            Row(
              children: [
                const Icon(Icons.hourglass_bottom_outlined, size: 14, color: Color(0xFFFF9800)),
                const SizedBox(width: 6),
                Text('Cooldown Period',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700)),
                const SizedBox(width: 4),
                Tooltip(
                  message: 'How long the student must wait before using the app again after reaching the limit.',
                  child: Icon(Icons.help_outline, size: 13, color: Colors.grey.shade400),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _TimeInput(
                    controller: _cooldownHoursCtl,
                    suffix: 'hrs',
                    onChanged: _onCooldownHoursChanged,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TimeInput(
                    controller: _cooldownMinutesCtl,
                    suffix: 'min',
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

// ── _TimeInput ───────────────────────────────────────────────────────────────

class _TimeInput extends StatelessWidget {
  final TextEditingController controller;
  final String suffix;
  final ValueChanged<String> onChanged;

  const _TimeInput({
    required this.controller,
    required this.suffix,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: onChanged,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF4A6CF7), width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        suffixText: suffix,
        suffixStyle: TextStyle(fontSize: 11, color: Colors.grey.shade500),
      ),
    );
  }
}
