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

  // Tracks whether any field has been modified from its original value.
  bool _isDirty = false;

  // The original name loaded from the BLoC — used to detect changes.
  String _originalFullName = '';

  @override
  void initState() {
    super.initState();

    // Seed the controllers from the current AuthAuthenticated state.
    final authState = context.read<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;

    _originalFullName = user?.fullName ?? '';
    _fullNameCtl = TextEditingController(text: _originalFullName);
    _emailCtl = TextEditingController(text: user?.email ?? '');

    // Listen for any changes to recompute dirty state.
    _fullNameCtl.addListener(_onFieldChanged);
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
    final passwordSectionTouched =
        _currentPassCtl.text.isNotEmpty ||
        _newPassCtl.text.isNotEmpty ||
        _confirmPassCtl.text.isNotEmpty;

    final dirty = nameChanged || passwordSectionTouched;
    if (dirty != _isDirty) {
      setState(() => _isDirty = dirty);
    }
  }

  // ── save logic ──────────────────────────────────────────────────────────────

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final nameChanged =
        _fullNameCtl.text.trim() != _originalFullName &&
        _fullNameCtl.text.trim().isNotEmpty;

    final isChangingPassword = _newPassCtl.text.isNotEmpty;

    context.read<AuthBloc>().add(
      UpdateProfileRequested(
        newFullName: nameChanged ? _fullNameCtl.text.trim() : null,
        currentPassword: isChangingPassword ? _currentPassCtl.text : null,
        newPassword: isChangingPassword ? _newPassCtl.text : null,
      ),
    );
  }

  // ── after successful save ───────────────────────────────────────────────────

  void _onSaveSuccess(UserModel updatedUser) {
    // Update the baseline so dirty-detection works correctly after saving.
    _originalFullName = updatedUser.fullName;
    _fullNameCtl.text = updatedUser.fullName;

    // Clear password fields.
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

  // ── build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is ProfileUpdateLoading) {
          setState(() => _isSaving = true);
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
        }
      },
      child: GestureDetector(
        // Dismiss keyboard when tapping outside a field.
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
              ],
            ),
          ),
        ),
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

  // ── email (read-only) ───────────────────────────────────────────────────────

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailCtl,
      readOnly: true,
      decoration: _inputDecoration(label: 'Email', icon: Icons.email_outlined)
          .copyWith(
            // Visual cue that the field is not editable.
            filled: true,
            fillColor: Colors.grey.shade100,
            helperText: 'Email cannot be changed.',
            helperStyle: TextStyle(fontSize: 11, color: Colors.grey.shade400),
          ),
      style: TextStyle(color: Colors.grey.shade600),
    );
  }

  // ── current password ────────────────────────────────────────────────────────

  Widget _buildCurrentPasswordField() {
    return TextFormField(
      controller: _currentPassCtl,
      obscureText: _obscureCurrent,
      decoration:
          _inputDecoration(
            label: 'Current Password',
            icon: Icons.lock_outline,
          ).copyWith(
            suffixIcon: _visibilityToggle(
              obscure: _obscureCurrent,
              onToggle: () =>
                  setState(() => _obscureCurrent = !_obscureCurrent),
            ),
          ),
      validator: (v) {
        // Only required when the user is trying to change their password.
        if (_newPassCtl.text.isNotEmpty && (v == null || v.isEmpty)) {
          return 'Enter your current password to set a new one.';
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
        if (v == null || v.isEmpty) return null; // optional
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
        if (_newPassCtl.text.isEmpty) return null; // not changing password
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
