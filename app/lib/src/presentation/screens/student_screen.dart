import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';
import '../widgets/parent_verification_dialog.dart';
import '../../services/overlay/mascot_overlay_service.dart';
import '../../domain/models/app_config_model.dart';

class StudentScreen extends StatefulWidget {
  final String fullName;
  final String uid;
  const StudentScreen({super.key, required this.fullName, required this.uid});

  @override
  State<StudentScreen> createState() => _StudentScreenState();
}

class _StudentScreenState extends State<StudentScreen> {
  String? _parentFullName;
  List<AppRuleModel> _appRules = [];
  bool _rulesLoading = true;

  @override
  void initState() {
    super.initState();
    context.read<AuthBloc>().add(
      LoadParentNameRequested(studentUid: widget.uid),
    );
    context.read<AuthBloc>().add(
      LoadStudentAppConfigRequested(studentUid: widget.uid),
    );
    MascotOverlayService.instance
        .init(
          monitoredApps: MascotOverlayService.dummyMonitoredApps,
          usageThresholdSeconds: 20,
        )
        .then((_) => MascotOverlayService.instance.start());
  }

  @override
  void dispose() {
    MascotOverlayService.instance.stop();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _parentFullName = null;
      _rulesLoading = true;
    });
    context.read<AuthBloc>().add(
      LoadParentNameRequested(studentUid: widget.uid),
    );
    context.read<AuthBloc>().add(
      LoadStudentAppConfigRequested(studentUid: widget.uid),
    );
  }

  void _showVerificationDialog({String? errorMessage}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => ParentVerificationDialog(
        errorMessage: errorMessage,
        onSubmit: (email, password) {
          Navigator.of(dialogContext).pop();
          context.read<AuthBloc>().add(
            VerifyParentAndLogoutRequested(
              studentUid: widget.uid,
              parentEmail: email,
              parentPassword: password,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          context.read<AuthBloc>().add(
            StudentLogoutVerificationRequested(studentUid: widget.uid),
          );
        }
      },
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is ParentNameLoaded) {
            setState(() => _parentFullName = state.parentFullName);
          }
          if (state is StudentLogoutVerificationRequired) {
            _showVerificationDialog();
          }
          if (state is ParentVerificationFailed) {
            _showVerificationDialog(errorMessage: state.message);
          }
          if (state is AppRulesLoaded && state.studentUid == widget.uid) {
            setState(() {
              _appRules = state.rules;
              _rulesLoading = false;
            });
          }
          if (state is AppConfigError) {
            setState(() => _rulesLoading = false);
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text('Welcome, ${widget.fullName}'),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () {
                  context.read<AuthBloc>().add(
                    StudentLogoutVerificationRequested(studentUid: widget.uid),
                  );
                },
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildParentSection(),
                  const SizedBox(height: 28),
                  _buildAppRulesSection(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── parent info section ────────────────────────────────────────────────────

  Widget _buildParentSection() {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(
            color: Color(0xFFE8EDFF),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.school, color: Color(0xFF4A6CF7), size: 26),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your parent',
                style: TextStyle(fontSize: 12, color: Color(0xFF8B93A7))),
            const SizedBox(height: 2),
            _parentFullName == null
                ? const SizedBox(
                    width: 120,
                    height: 16,
                    child: LinearProgressIndicator(),
                  )
                : Text(
                    _parentFullName!,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
          ],
        ),
      ],
    );
  }

  // ── app rules section ──────────────────────────────────────────────────────

  Widget _buildAppRulesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'App Rules',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 8),
            if (_rulesLoading)
              const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Rules configured by your parent.',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 14),
        if (!_rulesLoading && _appRules.isEmpty)
          _buildNoRulesPlaceholder()
        else
          ..._appRules.map(_buildRuleRow),
      ],
    );
  }

  Widget _buildNoRulesPlaceholder() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.app_settings_alt_outlined,
                size: 36, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            Text(
              'No app rules set yet.',
              style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text(
              'Your parent hasn\'t configured any rules for your device yet.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleRow(AppRuleModel rule) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // App avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFFE8EDFF),
            child: Text(
              rule.appLabel[0].toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF4A6CF7),
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // App label + package
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rule.appLabel,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                Text(rule.packageName,
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade500),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Duration pills
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildPill(
                icon: Icons.timer_outlined,
                label: '${rule.usageDurationMinutes}m',
                color: const Color(0xFF34A853),
                bg: const Color(0xFFE6F4EA),
              ),
              const SizedBox(height: 4),
              _buildPill(
                icon: Icons.hourglass_bottom_outlined,
                label: '${rule.cooldownDurationMinutes}m',
                color: const Color(0xFFFF9800),
                bg: const Color(0xFFFFF8E1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPill({
    required IconData icon,
    required String label,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(label,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}
