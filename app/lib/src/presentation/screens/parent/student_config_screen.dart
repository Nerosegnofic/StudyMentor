// lib/src/presentation/screens/parent/student_config_screen.dart
//
// Opened when a parent taps a verified student card.
// Flow:
//   1. Screen loads — fetches any previously saved rules.
//   2. If no rules exist, a prominent "Add Configuration" button is shown.
//   3. Parent taps "Add Configuration" → app-selection sheet appears showing
//      a mock list of installed apps (real device list requires a platform
//      channel; the mock list is clearly labelled and easy to swap out).
//   4. Parent selects app(s), configures usage + cooldown, taps Save.
//   5. Rules are saved to DataConnect; screen shows a success snackbar.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/auth/auth_bloc.dart';
import '../../../bloc/auth/auth_event.dart';
import '../../../bloc/auth/auth_state.dart';
import '../../../domain/models/app_config_model.dart';
import '../../../domain/models/student_model.dart';

// ── Mock installed-apps data ───────────────────────────────────────────────
// Replace with a real MethodChannel call when the platform layer is ready.
const List<Map<String, String>> _mockInstalledApps = [
  {'package': 'com.google.android.youtube', 'label': 'YouTube'},
  {'package': 'com.zhiliaoapp.musically', 'label': 'TikTok'},
  {'package': 'com.instagram.android', 'label': 'Instagram'},
  {'package': 'com.facebook.katana', 'label': 'Facebook'},
  {'package': 'com.snapchat.android', 'label': 'Snapchat'},
  {'package': 'com.twitter.android', 'label': 'X (Twitter)'},
  {'package': 'com.whatsapp', 'label': 'WhatsApp'},
  {'package': 'com.google.android.apps.maps', 'label': 'Google Maps'},
  {'package': 'com.netflix.mediaclient', 'label': 'Netflix'},
  {'package': 'com.spotify.music', 'label': 'Spotify'},
  {'package': 'com.roblox.client', 'label': 'Roblox'},
  {'package': 'com.mojang.minecraftpe', 'label': 'Minecraft'},
];

// ─────────────────────────────────────────────────────────────────────────────

class StudentConfigScreen extends StatefulWidget {
  final StudentModel student;

  const StudentConfigScreen({super.key, required this.student});

  @override
  State<StudentConfigScreen> createState() => _StudentConfigScreenState();
}

class _StudentConfigScreenState extends State<StudentConfigScreen> {
  // Rules currently shown in the UI (loaded from DB or newly added).
  final List<PendingAppRule> _rules = [];

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
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  void _loadRulesFromSaved(List<AppRuleModel> saved) {
    _rules.clear();
    for (final r in saved) {
      _rules.add(PendingAppRule(
        packageName: r.packageName,
        appLabel: r.appLabel,
        usageDurationMinutes: r.usageDurationMinutes,
        cooldownDurationMinutes: r.cooldownDurationMinutes,
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
    final available = _mockInstalledApps
        .where((a) => !_configuredPackages.contains(a['package']))
        .toList();

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
            for (final app in selected) {
              _rules.add(PendingAppRule(
                packageName: app['package']!,
                appLabel: app['label']!,
              ));
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
              icon: const Icon(Icons.add),
              label: const Text(
                'Add Configuration',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF4A6CF7),
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 16),
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
    return Column(
      children: [
        // Mock-data disclaimer banner
        _buildMockDisclaimer(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            itemCount: _rules.length,
            itemBuilder: (ctx, i) => _AppRuleCard(
              rule: _rules[i],
              onRemove: () => _removeRule(i),
              onChanged: () => _markDirty(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMockDisclaimer() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFB74D)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline,
              size: 16, color: Color(0xFFF57C00)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'App list is simulated. Real installed-app fetching requires a platform channel (Android).',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
            ),
          ),
        ],
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
  final List<Map<String, String>> availableApps;
  final void Function(List<Map<String, String>> selected) onAppsSelected;

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

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  List<Map<String, String>> get _filtered {
    if (_query.isEmpty) return widget.availableApps;
    final q = _query.toLowerCase();
    return widget.availableApps
        .where((a) =>
            a['label']!.toLowerCase().contains(q) ||
            a['package']!.toLowerCase().contains(q))
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
                    onPressed: () {
                      final selected = widget.availableApps
                          .where((a) =>
                              _selectedPackages.contains(a['package']))
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
                final pkg = app['package']!;
                final selected = _selectedPackages.contains(pkg);
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFE8EDFF),
                    child: Text(
                      app['label']![0].toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFF4A6CF7),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  title: Text(app['label']!,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(pkg,
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade500)),
                  trailing: Checkbox(
                    value: selected,
                    activeColor: const Color(0xFF4A6CF7),
                    onChanged: (_) => setState(() {
                      if (selected) {
                        _selectedPackages.remove(pkg);
                      } else {
                        _selectedPackages.add(pkg);
                      }
                    }),
                  ),
                  onTap: () => setState(() {
                    if (selected) {
                      _selectedPackages.remove(pkg);
                    } else {
                      _selectedPackages.add(pkg);
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
  late TextEditingController _usageCtl;
  late TextEditingController _cooldownCtl;

  @override
  void initState() {
    super.initState();
    _usageCtl = TextEditingController(
        text: widget.rule.usageDurationMinutes.toString());
    _cooldownCtl = TextEditingController(
        text: widget.rule.cooldownDurationMinutes.toString());
  }

  @override
  void dispose() {
    _usageCtl.dispose();
    _cooldownCtl.dispose();
    super.dispose();
  }

  void _onUsageChanged(String v) {
    final parsed = int.tryParse(v);
    if (parsed != null && parsed > 0) {
      widget.rule.usageDurationMinutes = parsed;
      widget.onChanged();
    }
  }

  void _onCooldownChanged(String v) {
    final parsed = int.tryParse(v);
    if (parsed != null && parsed >= 0) {
      widget.rule.cooldownDurationMinutes = parsed;
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
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFFE8EDFF),
                  child: Text(
                    widget.rule.appLabel[0].toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFF4A6CF7),
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
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
            // Duration fields
            Row(
              children: [
                Expanded(
                  child: _DurationField(
                    controller: _usageCtl,
                    label: 'Usage (min)',
                    icon: Icons.timer_outlined,
                    iconColor: const Color(0xFF34A853),
                    tooltip:
                        'How many minutes the student can use this app before being locked out.',
                    onChanged: _onUsageChanged,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DurationField(
                    controller: _cooldownCtl,
                    label: 'Cooldown (min)',
                    icon: Icons.hourglass_bottom_outlined,
                    iconColor: const Color(0xFFFF9800),
                    tooltip:
                        'How many minutes the student must wait before using the app again.',
                    onChanged: _onCooldownChanged,
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

// ── _DurationField ────────────────────────────────────────────────────────────

class _DurationField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final Color iconColor;
  final String tooltip;
  final ValueChanged<String> onChanged;

  const _DurationField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.tooltip,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700)),
            const SizedBox(width: 4),
            Tooltip(
              message: tooltip,
              child: Icon(Icons.help_outline,
                  size: 13, color: Colors.grey.shade400),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: onChanged,
          decoration: InputDecoration(
            isDense: true,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: Color(0xFF4A6CF7), width: 1.5)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            suffixText: 'min',
            suffixStyle:
                TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ),
      ],
    );
  }
}
