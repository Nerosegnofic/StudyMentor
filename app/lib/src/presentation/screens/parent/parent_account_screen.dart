// lib/src/presentation/screens/parent/parent_account_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../bloc/auth/auth_bloc.dart';
import '../../../bloc/auth/auth_event.dart' show LogoutRequested;
import '../../../bloc/auth/auth_state.dart';
import '../../../bloc/students/students_bloc.dart';
import '../../../bloc/students/students_event.dart';
import '../../../bloc/students/students_state.dart';
import '../../../bloc/parent_profile/parent_profile_bloc.dart';
import '../../../bloc/parent_profile/parent_profile_event.dart';
import '../../../bloc/parent_profile/parent_profile_state.dart';
import '../../../domain/models/user_model.dart';

class ParentAccountScreen extends StatefulWidget {
  const ParentAccountScreen({super.key});

  @override
  State<ParentAccountScreen> createState() => _ParentAccountScreenState();
}

class _ParentAccountScreenState extends State<ParentAccountScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _fullNameCtl;
  late TextEditingController _emailCtl;
  final _currentPassCtl = TextEditingController();
  final _newPassCtl = TextEditingController();
  final _confirmPassCtl = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  bool _isSaving = false;
  bool _isDirty = false;

  String _originalFullName = '';
  String _originalEmail = '';

  String? _pendingEmailNotice;

  int? _linkedChildCount;
  bool _childLoadError = false;

  @override
  void initState() {
    super.initState();

    final authState = context.read<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;

    _originalFullName = user?.fullName ?? '';
    _originalEmail = user?.email ?? '';

    _fullNameCtl = TextEditingController(text: _originalFullName);
    _emailCtl = TextEditingController(text: _originalEmail);

    _fullNameCtl.addListener(_onFieldChanged);
    _emailCtl.addListener(_onFieldChanged);
    _currentPassCtl.addListener(_onFieldChanged);
    _newPassCtl.addListener(_onFieldChanged);
    _confirmPassCtl.addListener(_onFieldChanged);

    if (user != null) {
      context.read<StudentsBloc>().add(LoadStudentsRequested(parentUid: user.uid));
    }
  }

  @override
  void dispose() {
    _fullNameCtl.dispose();
    _emailCtl.dispose();
    _currentPassCtl.dispose();
    _newPassCtl.dispose();
    _confirmPassCtl.dispose();
    super.dispose();
  }

  // ── dirty tracking ──────────────────────────────────────────────────────────

  void _onFieldChanged() {
    final nameChanged = _fullNameCtl.text.trim() != _originalFullName;
    final emailChanged = _emailCtl.text.trim() != _originalEmail;
    final passwordSectionTouched =
        _currentPassCtl.text.isNotEmpty ||
        _newPassCtl.text.isNotEmpty ||
        _confirmPassCtl.text.isNotEmpty;

    final dirty = nameChanged || emailChanged || passwordSectionTouched;
    if (dirty != _isDirty) setState(() => _isDirty = dirty);
  }

  // ── save ────────────────────────────────────────────────────────────────────

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final newName = _fullNameCtl.text.trim();
    final newEmail = _emailCtl.text.trim();
    final isChangingPassword = _newPassCtl.text.isNotEmpty;
    final emailChanged = newEmail != _originalEmail && newEmail.isNotEmpty;

    context.read<ParentProfileBloc>().add(
      UpdateParentProfileRequested(
        parentUid: context.read<AuthBloc>().state is AuthAuthenticated
            ? (context.read<AuthBloc>().state as AuthAuthenticated).user.uid
            : '',
        newFullName: newName != _originalFullName && newName.isNotEmpty ? newName : null,
        newEmail: emailChanged ? newEmail : null,
        currentPassword: (isChangingPassword || emailChanged) ? _currentPassCtl.text : null,
        newPassword: isChangingPassword ? _newPassCtl.text : null,
      ),
    );
  }

  void _onSaveSuccess(UserModel updatedUser) {
    _originalFullName = updatedUser.fullName;
    _originalEmail = updatedUser.email;
    _fullNameCtl.text = updatedUser.fullName;
    _currentPassCtl.clear();
    _newPassCtl.clear();
    _confirmPassCtl.clear();
    setState(() => _isDirty = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile updated successfully.'),
        backgroundColor: Color(0xFF34A853),
      ),
    );
  }

  // ── child-list retry ────────────────────────────────────────────────────────

  void _retryLoadChildren() {
    final authState = context.read<AuthBloc>().state;
    final uid = authState is AuthAuthenticated ? authState.user.uid : null;
    if (uid == null) return;
    setState(() {
      _childLoadError = false;
      _linkedChildCount = null;
    });
    context.read<StudentsBloc>().add(LoadStudentsRequested(parentUid: uid));
  }

  // ── unsaved changes guard ───────────────────────────────────────────────────

  Future<bool> _onWillPop() async {
    if (!_isDirty) return true;
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text('You have unsaved changes. Leave without saving?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Stay'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    return leave ?? false;
  }

  // ── delete account ──────────────────────────────────────────────────────────

  Future<void> _confirmDeleteAccount() async {
    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Your Account'),
        content: const Text(
          'This will permanently delete your account. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (proceed != true || !mounted) return;

    final parentUid = context.read<AuthBloc>().state is AuthAuthenticated
        ? (context.read<AuthBloc>().state as AuthAuthenticated).user.uid
        : '';

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<ParentProfileBloc>(),
        child: _ParentDeletePasswordDialog(parentUid: parentUid),
      ),
    );
  }

  // ── logout ──────────────────────────────────────────────────────────────────

  Future<void> _confirmLogout() async {
    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.logout_rounded, color: Colors.red, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Log Out',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to log out of your account?',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (proceed == true && mounted) {
      context.read<AuthBloc>().add(LogoutRequested());
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  // ── build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final parentName = authState is AuthAuthenticated ? authState.user.fullName : '';

    return MultiBlocListener(
      listeners: [
        BlocListener<StudentsBloc, StudentsState>(
          listener: (context, state) {
            if (state is StudentsLoaded) {
              setState(() {
                _linkedChildCount = state.students.length;
                _childLoadError = false;
              });
            } else if (state is StudentsError && _linkedChildCount == null) {
              setState(() {
                _childLoadError = true;
                _linkedChildCount = null;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                    'Could not load linked students. Check your connection.',
                  ),
                  backgroundColor: Colors.red.shade700,
                  action: SnackBarAction(
                    label: 'Retry',
                    textColor: Colors.white,
                    onPressed: _retryLoadChildren,
                  ),
                ),
              );
            }
          },
        ),
        BlocListener<ParentProfileBloc, ParentProfileState>(
          listener: (context, state) {
            if (state is ParentProfileLoading) {
              setState(() => _isSaving = true);
            } else if (state is EmailVerificationPending) {
              setState(() => _pendingEmailNotice = state.pendingEmail);
            } else if (state is ParentProfileUpdateSuccess) {
              setState(() => _isSaving = false);
              _onSaveSuccess(state.updatedUser);
            } else if (state is ParentAccountDeleted) {
              context.read<AuthBloc>().add(LogoutRequested());
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/login',
                  (route) => false,
                );
              }
            } else if (state is ParentProfileError) {
              setState(() => _isSaving = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red.shade700,
                ),
              );
            }
          },
        ),
      ],
      child: PopScope(
        canPop: !_isDirty,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          final leave = await _onWillPop();
          if (leave && context.mounted) Navigator.of(context).pop();
        },
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Scaffold(
            backgroundColor: const Color(0xFFF5F7FA),
            appBar: AppBar(
              backgroundColor: const Color(0xFF2196F3),
              elevation: 4,
              shadowColor: Colors.black.withValues(alpha: 0.15),
              surfaceTintColor: Colors.transparent,
              iconTheme: const IconThemeData(color: Colors.white),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Account Settings',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  if (parentName.isNotEmpty)
                    Text(
                      parentName,
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                    ),
                ],
              ),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_pendingEmailNotice != null) ...[
                      _buildEmailPendingBanner(_pendingEmailNotice!),
                      const SizedBox(height: 16),
                    ],
                    // Card 1: Account Information
                    Container(
                      padding: const EdgeInsets.all(24),
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
                          const Text(
                            'Account Information',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildFullNameField(),
                          const SizedBox(height: 16),
                          _buildEmailField(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Card 2: Change Password
                    Container(
                      padding: const EdgeInsets.all(24),
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
                          const Text(
                            'Change Password',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Leave all password fields empty to keep your current password.',
                            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 24),
                          _buildCurrentPasswordField(),
                          const SizedBox(height: 16),
                          _buildNewPasswordField(),
                          const SizedBox(height: 16),
                          _buildConfirmPasswordField(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSaveButton(),
                    const SizedBox(height: 32),
                    _buildDangerZoneCard(),
                    const SizedBox(height: 16),
                    _buildLogoutButton(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── pending-email banner ────────────────────────────────────────────────────

  Widget _buildEmailPendingBanner(String pendingEmail) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFCC02)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.mark_email_unread_outlined, color: Color(0xFFF9A825), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'A verification link was sent to $pendingEmail. '
              'Your email address will update after you click it.',
              style: const TextStyle(fontSize: 13, color: Color(0xFF5D4037)),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _pendingEmailNotice = null),
            child: const Icon(Icons.close, size: 16, color: Color(0xFF9E9E9E)),
          ),
        ],
      ),
    );
  }

  // ── full name ───────────────────────────────────────────────────────────────

  Widget _buildFullNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Full Name',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _fullNameCtl,
          textCapitalization: TextCapitalization.words,
          style: const TextStyle(color: Color(0xFF1E293B), fontSize: 15),
          decoration: _inputDecoration(label: 'Full Name', icon: Icons.person_outline),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Full name is required.';
            if (v.trim().length < 2) return 'Name must be at least 2 characters.';
            return null;
          },
        ),
      ],
    );
  }

  // ── email ───────────────────────────────────────────────────────────────────

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Email',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _emailCtl,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: Color(0xFF1E293B), fontSize: 15),
          decoration: _inputDecoration(label: 'Email', icon: Icons.email_outlined),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Email is required.';
            final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
            if (!emailRegex.hasMatch(v.trim())) return 'Enter a valid email address.';
            return null;
          },
        ),
        const SizedBox(height: 6),
        const Text(
          'Changing your email will send a verification link to the new address.',
          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
      ],
    );
  }

  // ── current password ────────────────────────────────────────────────────────

  Widget _buildCurrentPasswordField() {
    final emailChanged =
        _emailCtl.text.trim() != _originalEmail &&
        _emailCtl.text.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Current Password',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _currentPassCtl,
          obscureText: _obscureCurrent,
          style: const TextStyle(color: Color(0xFF1E293B), fontSize: 15),
          decoration: _inputDecoration(
            label: 'Current Password',
            icon: Icons.lock_outline,
          ).copyWith(
            suffixIcon: _visibilityToggle(
              obscure: _obscureCurrent,
              onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
            ),
          ),
          validator: (v) {
            final changingPassword = _newPassCtl.text.isNotEmpty;
            final changingEmail =
                _emailCtl.text.trim() != _originalEmail &&
                _emailCtl.text.trim().isNotEmpty;
            if ((changingPassword || changingEmail) && (v == null || v.isEmpty)) {
              return changingEmail
                  ? 'Enter your current password to change your email.'
                  : 'Enter your current password to set a new one.';
            }
            return null;
          },
        ),
        if (emailChanged) ...[
          const SizedBox(height: 6),
          const Text(
            'Required to change the email address.',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
        ],
      ],
    );
  }

  // ── new password ────────────────────────────────────────────────────────────

  Widget _buildNewPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'New Password',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _newPassCtl,
          obscureText: _obscureNew,
          style: const TextStyle(color: Color(0xFF1E293B), fontSize: 15),
          decoration: _inputDecoration(
            label: 'New Password',
            icon: Icons.lock_reset_outlined,
          ).copyWith(
            suffixIcon: _visibilityToggle(
              obscure: _obscureNew,
              onToggle: () => setState(() => _obscureNew = !_obscureNew),
            ),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return null;
            if (v.length < 6) return 'Password must be at least 6 characters.';
            if (_currentPassCtl.text.isEmpty) return 'Enter your current password first.';
            return null;
          },
        ),
      ],
    );
  }

  // ── confirm password ────────────────────────────────────────────────────────

  Widget _buildConfirmPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Confirm New Password',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _confirmPassCtl,
          obscureText: _obscureConfirm,
          style: const TextStyle(color: Color(0xFF1E293B), fontSize: 15),
          decoration: _inputDecoration(
            label: 'Confirm New Password',
            icon: Icons.lock_outline,
          ).copyWith(
            suffixIcon: _visibilityToggle(
              obscure: _obscureConfirm,
              onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
            ),
          ),
          validator: (v) {
            if (_newPassCtl.text.isEmpty) return null;
            if (v != _newPassCtl.text) return 'Passwords do not match.';
            return null;
          },
        ),
      ],
    );
  }

  // ── save button ─────────────────────────────────────────────────────────────

  Widget _buildSaveButton() {
    final canSave = _isDirty && !_isSaving;
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: canSave ? _save : null,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: const StadiumBorder(),
          backgroundColor: const Color(0xFF2196F3),
          disabledBackgroundColor: const Color(0xFFE2E8F0),
          foregroundColor: Colors.white,
          disabledForegroundColor: const Color(0xFF94A3B8),
          elevation: 0,
        ),
        child: _isSaving
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
              )
            : Text(
                'Save Changes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: canSave ? Colors.white : const Color(0xFF94A3B8),
                ),
              ),
      ),
    );
  }

  // ── danger zone card ────────────────────────────────────────────────────────

  Widget _buildDangerZoneCard() {
    final isLoadingChildren = !_childLoadError && _linkedChildCount == null;
    final hasLinkedChildren = _linkedChildCount != null && _linkedChildCount! > 0;
    final canDelete = !isLoadingChildren && !hasLinkedChildren && !_childLoadError;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.warning_amber_rounded, color: Colors.red.shade600, size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                'Danger Zone',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Permanently removes your account and all data. '
            'You must delete all student accounts first.',
            style: TextStyle(fontSize: 13, color: Colors.red.shade800, height: 1.4),
          ),
          if (_childLoadError) ...[
            const SizedBox(height: 10),
            _buildChildLoadErrorNotice(),
          ],
          if (hasLinkedChildren) ...[
            const SizedBox(height: 10),
            _buildLinkedChildrenNotice(),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: Tooltip(
              message: hasLinkedChildren
                  ? 'Remove all linked children before deleting your account.'
                  : _childLoadError
                      ? 'Could not verify linked students. Please retry.'
                      : '',
              child: OutlinedButton.icon(
                onPressed: canDelete ? _confirmDeleteAccount : null,
                icon: isLoadingChildren
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.grey.shade400,
                        ),
                      )
                    : Icon(
                        Icons.delete_forever_rounded,
                        size: 18,
                        color: canDelete ? Colors.red.shade600 : Colors.grey.shade400,
                      ),
                label: Text(
                  'Delete My Account',
                  style: TextStyle(
                    color: canDelete ? Colors.red.shade600 : Colors.grey.shade400,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  side: BorderSide(
                    color: canDelete ? Colors.red.shade400 : Colors.grey.shade300,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildLoadErrorNotice() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFB74D)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(Icons.wifi_off_rounded, size: 15, color: Color(0xFFF57C00)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Could not verify linked students. '
              'Deletion is disabled until this is resolved.',
              style: TextStyle(fontSize: 12, color: Colors.orange.shade900, height: 1.4),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _retryLoadChildren,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF57C00),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkedChildrenNotice() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFB74D)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(Icons.child_care_rounded, size: 15, color: Color(0xFFF57C00)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'You can only delete your account after removing all linked '
              'children. Go to the Students tab to delete each child\'s account first.',
              style: TextStyle(fontSize: 12, color: Colors.orange.shade900, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  // ── logout button ───────────────────────────────────────────────────────────

  Widget _buildLogoutButton() {
    return OutlinedButton.icon(
      onPressed: _confirmLogout,
      icon: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 18),
      label: const Text(
        'Log Out',
        style: TextStyle(
          color: Color(0xFFEF4444),
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── helpers ─────────────────────────────────────────────────────────────────

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    bool enabled = true,
  }) {
    return InputDecoration(
      prefixIcon: Icon(
        icon,
        color: enabled ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
      ),
      filled: true,
      fillColor: WidgetStateColor.resolveWith((states) {
        if (states.contains(WidgetState.focused)) return Colors.white;
        if (states.contains(WidgetState.disabled)) return const Color(0xFFF1F5F9);
        return const Color(0xFFF8FAFC);
      }),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2196F3)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade400),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade600, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _visibilityToggle({required bool obscure, required VoidCallback onToggle}) {
    return IconButton(
      icon: Icon(
        obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        color: const Color(0xFF64748B),
      ),
      onPressed: onToggle,
    );
  }
}

// ── _ParentDeletePasswordDialog ───────────────────────────────────────────────

class _ParentDeletePasswordDialog extends StatefulWidget {
  final String parentUid;
  const _ParentDeletePasswordDialog({required this.parentUid});

  @override
  State<_ParentDeletePasswordDialog> createState() =>
      _ParentDeletePasswordDialogState();
}

class _ParentDeletePasswordDialogState
    extends State<_ParentDeletePasswordDialog> {
  final _passCtl = TextEditingController();
  bool _obscure = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passCtl.dispose();
    super.dispose();
  }

  void _submit() {
    final password = _passCtl.text.trim();
    if (password.isEmpty) {
      setState(() => _errorMessage = 'Please enter your current password.');
      return;
    }
    setState(() => _errorMessage = null);
    context.read<ParentProfileBloc>().add(
      DeleteParentAccountRequested(
        parentUid: widget.parentUid,
        currentPassword: password,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isLoading,
      child: BlocListener<ParentProfileBloc, ParentProfileState>(
        listener: (context, state) {
          if (state is ParentProfileLoading) {
            setState(() => _isLoading = true);
          } else if (state is ParentAccountDeleted) {
            // Navigation is handled by the parent screen's listener via
            // pushNamedAndRemoveUntil — popping here would race with it.
            Navigator.of(context, rootNavigator: true)
                .pushNamedAndRemoveUntil('/login', (route) => false);
          } else if (state is ParentProfileError) {
            setState(() {
              _isLoading = false;
              _errorMessage = state.message;
            });
          }
        },
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.lock_outline, color: Colors.red.shade600, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Confirm Your Password',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enter your current password to permanently delete your account. This cannot be undone.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passCtl,
                  obscureText: _obscure,
                  autofocus: true,
                  enabled: !_isLoading,
                  onChanged: (_) {
                    if (_errorMessage != null) setState(() => _errorMessage = null);
                  },
                  onSubmitted: (_) {
                    if (!_isLoading) _submit();
                  },
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    errorText: _errorMessage,
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.red.shade600, width: 1.5),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.red.shade400),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.red.shade600, width: 1.5),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 18,
                        color: Colors.grey.shade500,
                      ),
                      onPressed:
                          _isLoading ? null : () => setState(() => _obscure = !_obscure),
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
              onPressed: _isLoading ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Delete Account'),
            ),
          ],
        ),
      ),
    );
  }
}
