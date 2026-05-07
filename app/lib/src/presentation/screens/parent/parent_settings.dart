// lib/src/presentation/screens/parent/parent_settings.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/auth/auth_bloc.dart';
import '../../../bloc/auth/auth_event.dart';
import '../../../bloc/auth/auth_state.dart';
import '../../../domain/models/user_model.dart';

class ParentSettings extends StatefulWidget {
  const ParentSettings({super.key});

  @override
  State<ParentSettings> createState() => _ParentSettingsState();
}

class _ParentSettingsState extends State<ParentSettings> {
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
  bool _isDeletingAccount = false;

  // Baselines for dirty detection.
  String _originalFullName = '';
  String _originalEmail = '';

  // Shown after a successful email-change request.
  String? _pendingEmailNotice;

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

  // ── save logic ──────────────────────────────────────────────────────────────

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final newName = _fullNameCtl.text.trim();
    final newEmail = _emailCtl.text.trim();
    final isChangingPassword = _newPassCtl.text.isNotEmpty;

    // Email or password changes both require the current password.
    final emailChanged = newEmail != _originalEmail && newEmail.isNotEmpty;

    context.read<AuthBloc>().add(
      UpdateProfileRequested(
        newFullName: newName != _originalFullName && newName.isNotEmpty
            ? newName
            : null,
        newEmail: emailChanged ? newEmail : null,
        currentPassword: (isChangingPassword || emailChanged)
            ? _currentPassCtl.text
            : null,
        newPassword: isChangingPassword ? _newPassCtl.text : null,
      ),
    );
  }

  // ── after successful save ───────────────────────────────────────────────────

  void _onSaveSuccess(UserModel updatedUser) {
    _originalFullName = updatedUser.fullName;
    _originalEmail = updatedUser.email;
    _fullNameCtl.text = updatedUser.fullName;
    // Keep the email field showing what the user typed (the pending address).

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

  // ── delete account ──────────────────────────────────────────────────────────

  Future<void> _confirmDeleteAccount() async {
    // Step 1: Warn user they must delete all children first.
    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Your Account'),
        content: const Text(
          'This will permanently delete your account and all associated data. '
          'You must delete all student accounts first.\n\n'
          'This action cannot be undone. Continue?',
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
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (proceed != true || !mounted) return;

    // Step 2: Ask for current password to re-authenticate.
    final password = await _showPasswordConfirmDialog();
    if (password == null || password.isEmpty || !mounted) return;

    context.read<AuthBloc>().add(
      DeleteParentAccountRequested(currentPassword: password),
    );
  }

  Future<String?> _showPasswordConfirmDialog() async {
    final passCtl = TextEditingController();
    bool obscure = true;

    return await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Confirm Your Password'),
          content: TextField(
            controller: passCtl,
            obscureText: obscure,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Current Password',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(
                  obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () => setS(() => obscure = !obscure),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(passCtl.text),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade600,
              ),
              child: const Text('Delete Account'),
            ),
          ],
        ),
      ),
    );
  }

  // ── build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is ProfileUpdateLoading) {
          setState(() => _isSaving = true);
        } else if (state is EmailUpdateVerificationSent) {
          // Show the pending-verification banner; keep saving = true
          // because ProfileUpdateSuccess follows immediately after.
          setState(() => _pendingEmailNotice = state.pendingEmail);
        } else if (state is ProfileUpdateSuccess) {
          setState(() => _isSaving = false);
          _onSaveSuccess(state.updatedUser);
        } else if (state is ProfileUpdateError) {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red.shade700,
            ),
          );
        } else if (state is ParentAccountDeleteLoading) {
          setState(() => _isDeletingAccount = true);
        } else if (state is ParentAccountDeleted) {
          // AuthUnauthenticated follows immediately — no extra navigation needed.
        } else if (state is ParentAccountDeleteError) {
          setState(() => _isDeletingAccount = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
      },
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
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
                _buildSectionHeader('Account Information'),
                const SizedBox(height: 12),
                _buildFullNameField(),
                const SizedBox(height: 12),
                _buildEmailField(),
                const SizedBox(height: 32),
                _buildSectionHeader('Change Password'),
                const SizedBox(height: 4),
                _buildPasswordHint(),
                const SizedBox(height: 12),
                _buildCurrentPasswordField(),
                const SizedBox(height: 12),
                _buildNewPasswordField(),
                const SizedBox(height: 12),
                _buildConfirmPasswordField(),
                const SizedBox(height: 32),
                _buildSaveButton(),
                const SizedBox(height: 40),
                _buildDeleteAccountSection(),
              ],
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
          const Icon(
            Icons.mark_email_unread_outlined,
            color: Color(0xFFF9A825),
            size: 20,
          ),
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

  // ── section header ──────────────────────────────────────────────────────────

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Colors.grey.shade500,
        letterSpacing: 0.8,
      ),
    );
  }

  // ── password hint ───────────────────────────────────────────────────────────

  Widget _buildPasswordHint() {
    return Text(
      'Leave all password fields empty to keep your current password.',
      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
    );
  }

  // ── full name ───────────────────────────────────────────────────────────────

  Widget _buildFullNameField() {
    return TextFormField(
      controller: _fullNameCtl,
      textCapitalization: TextCapitalization.words,
      decoration: _inputDecoration(
        label: 'Full Name',
        icon: Icons.person_outline,
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Full name is required.';
        if (v.trim().length < 2) return 'Name must be at least 2 characters.';
        return null;
      },
    );
  }

  // ── email (now editable) ────────────────────────────────────────────────────

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailCtl,
      keyboardType: TextInputType.emailAddress,
      decoration: _inputDecoration(label: 'Email', icon: Icons.email_outlined)
          .copyWith(
            helperText:
                'Changing your email will send a verification link to the new address.',
            helperStyle: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            helperMaxLines: 2,
          ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Email is required.';
        final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
        if (!emailRegex.hasMatch(v.trim())) {
          return 'Enter a valid email address.';
        }
        return null;
      },
    );
  }

  // ── current password ────────────────────────────────────────────────────────

  Widget _buildCurrentPasswordField() {
    // Required when changing email OR password.
    final emailChanged =
        _emailCtl.text.trim() != _originalEmail &&
        _emailCtl.text.trim().isNotEmpty;

    return TextFormField(
      controller: _currentPassCtl,
      obscureText: _obscureCurrent,
      decoration:
          _inputDecoration(
            label: 'Current Password',
            icon: Icons.lock_outline,
          ).copyWith(
            helperText: emailChanged
                ? 'Required to change your email address.'
                : null,
            helperStyle: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            suffixIcon: _visibilityToggle(
              obscure: _obscureCurrent,
              onToggle: () =>
                  setState(() => _obscureCurrent = !_obscureCurrent),
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
    );
  }

  // ── new password ────────────────────────────────────────────────────────────

  Widget _buildNewPasswordField() {
    return TextFormField(
      controller: _newPassCtl,
      obscureText: _obscureNew,
      decoration:
          _inputDecoration(
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
        if (_currentPassCtl.text.isEmpty) {
          return 'Enter your current password first.';
        }
        return null;
      },
    );
  }

  // ── confirm password ────────────────────────────────────────────────────────

  Widget _buildConfirmPasswordField() {
    return TextFormField(
      controller: _confirmPassCtl,
      obscureText: _obscureConfirm,
      decoration:
          _inputDecoration(
            label: 'Confirm New Password',
            icon: Icons.lock_outline,
          ).copyWith(
            suffixIcon: _visibilityToggle(
              obscure: _obscureConfirm,
              onToggle: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
            ),
          ),
      validator: (v) {
        if (_newPassCtl.text.isEmpty) return null;
        if (v != _newPassCtl.text) return 'Passwords do not match.';
        return null;
      },
    );
  }

  // ── save button ─────────────────────────────────────────────────────────────

  Widget _buildSaveButton() {
    final canSave = _isDirty && !_isSaving;

    return AnimatedOpacity(
      opacity: canSave ? 1.0 : 0.4,
      duration: const Duration(milliseconds: 200),
      child: FilledButton(
        onPressed: canSave ? _save : null,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: const Color(0xFF4A6CF7),
        ),
        child: _isSaving
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Save Changes',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  // ── delete account section ──────────────────────────────────────────────────

  Widget _buildDeleteAccountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader('Danger Zone'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.red.shade600,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Delete Account',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.red.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Permanently removes your account and all data. '
                'You must delete all student accounts first.',
                style: TextStyle(fontSize: 12, color: Colors.red.shade800),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isDeletingAccount
                      ? null
                      : _confirmDeleteAccount,
                  icon: _isDeletingAccount
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.red.shade600,
                          ),
                        )
                      : Icon(
                          Icons.delete_forever_rounded,
                          size: 18,
                          color: Colors.red.shade600,
                        ),
                  label: Text(
                    'Delete My Account',
                    style: TextStyle(
                      color: Colors.red.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: Colors.red.shade400),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── helpers ─────────────────────────────────────────────────────────────────

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF4A6CF7), width: 1.5),
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

  Widget _visibilityToggle({
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return IconButton(
      icon: Icon(
        obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        color: Colors.grey.shade500,
      ),
      onPressed: onToggle,
    );
  }
}
