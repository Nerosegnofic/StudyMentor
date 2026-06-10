// lib/src/presentation/screens/parent/parent_student_settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/student_profile/student_profile_bloc.dart';
import '../../../bloc/student_profile/student_profile_event.dart';
import '../../../bloc/student_profile/student_profile_state.dart';
import '../../../domain/models/student_model.dart';
import '../../../data/providers/dataconnect_provider.dart';

class ParentStudentSettingsScreen extends StatefulWidget {
  final StudentModel student;

  const ParentStudentSettingsScreen({super.key, required this.student});

  @override
  State<ParentStudentSettingsScreen> createState() =>
      _ParentStudentSettingsScreenState();
}

class _ParentStudentSettingsScreenState
    extends State<ParentStudentSettingsScreen> {
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

  final _usernameCtl = TextEditingController();
  bool _loadingExtra = true;

  // Shown after a successful email-change request.
  String? _pendingEmailNotice;

  @override
  void initState() {
    super.initState();
    _originalFullName = widget.student.fullName;
    _originalEmail = widget.student.email;

    _fullNameCtl = TextEditingController(text: _originalFullName);
    _emailCtl = TextEditingController(text: _originalEmail);

    _fullNameCtl.addListener(_onFieldChanged);
    _emailCtl.addListener(_onFieldChanged);
    _currentPassCtl.addListener(_onFieldChanged);
    _newPassCtl.addListener(_onFieldChanged);
    _confirmPassCtl.addListener(_onFieldChanged);

    _loadExtra();

  }

  @override
  void dispose() {
    _fullNameCtl.dispose();
    _emailCtl.dispose();
    _usernameCtl.dispose();
    _currentPassCtl.dispose();
    _newPassCtl.dispose();
    _confirmPassCtl.dispose();
    super.dispose();
  }

  Future<void> _loadExtra() async {
    try {
      final profile = await DataConnectProvider().getStudentProfile(
        widget.student.uid,
      );
      if (mounted) {
        final username = profile['username'] as String? ?? '';
        _usernameCtl.text = username;
        setState(() => _loadingExtra = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loadingExtra = false);
    }
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

  // ── save ─────────────────────────────────────────────────────────────────────

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final newName = _fullNameCtl.text.trim();
    final newEmail = _emailCtl.text.trim();
    final isChangingPassword = _newPassCtl.text.isNotEmpty;
    final emailChanged = newEmail != _originalEmail && newEmail.isNotEmpty;

    context.read<StudentProfileBloc>().add(
      UpdateStudentProfileRequested(
        studentUid: widget.student.uid,
        studentEmail: _originalEmail,
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

  void _onSaveSuccess(StudentProfileUpdateSuccess state) {
    _originalFullName = state.updatedStudent.fullName;
    _fullNameCtl.text = state.updatedStudent.fullName;
    
    // If email changed we keep _originalEmail as-is until student verifies.
    _currentPassCtl.clear();
    _newPassCtl.clear();
    _confirmPassCtl.clear();

    // In a real app we might handle pending email here.
    setState(() {
      _isSaving = false;
      _isDirty = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Student profile updated successfully.'),
        backgroundColor: Color(0xFF34A853),
      ),
    );
  }

  // ── build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocListener<StudentProfileBloc, StudentProfileState>(
      listener: (context, state) {
        if (state is StudentProfileLoading) {
          setState(() => _isSaving = true);
        } else if (state is StudentProfileUpdateSuccess &&
            state.updatedStudent.uid == widget.student.uid) {
          _onSaveSuccess(state);
        } else if (state is StudentProfileError) {
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
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          appBar: AppBar(
            backgroundColor: const Color(0xFF2196F3),
            elevation: 4,
            shadowColor: Colors.black.withOpacity(0.15),
            surfaceTintColor: Colors.transparent,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Student Profile',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  widget.student.fullName,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          body: Container(
            color: const Color(0xFFF5F7FA),
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
                  // Card 1: Account Information
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
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
                        const SizedBox(height: 16),
                        _buildUsernameField(),
                      ],
                    ),
                  ),
                  // Card 2: Change Password
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
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
                        _buildPasswordHint(),
                        const SizedBox(height: 24),
                        _buildCurrentPasswordField(),
                        const SizedBox(height: 16),
                        _buildNewPasswordField(),
                        const SizedBox(height: 16),
                        _buildConfirmPasswordField(),
                      ],
                    ),
                  ),
                  _buildSaveButton(),
                ],
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }

  // ── pending email banner ────────────────────────────────────────────────────

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
              'The student\'s email will update after they click it.',
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

  // ── password hint ───────────────────────────────────────────────────────────

  Widget _buildPasswordHint() {
    return const Text(
      'Leave all password fields empty to keep the current password.',
      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
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
          style: const TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 15,
          ),
          decoration: _inputDecoration(
            label: 'Full Name',
            icon: Icons.person_outline,
          ),
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
          style: const TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 15,
          ),
          decoration: _inputDecoration(
            label: 'Email',
            icon: Icons.email_outlined,
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Email is required.';
            final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
            if (!emailRegex.hasMatch(v.trim())) {
              return 'Enter a valid email address.';
            }
            return null;
          },
        ),
        const SizedBox(height: 6),
        const Text(
          'Changing the email will send a verification link to the new address.',
          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
      ],
    );
  }

  // ── username (read-only, controller-driven so it updates after async load) ──

  Widget _buildUsernameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Username',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _usernameCtl,
          enabled: false,
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 15,
          ),
          decoration: _inputDecoration(
            label: 'Username',
            icon: Icons.alternate_email_rounded,
            enabled: false,
          ).copyWith(
            suffixIcon: _loadingExtra
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : const Icon(Icons.lock_outline, size: 16, color: Color(0xFF94A3B8)),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Username cannot be changed.',
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
          "Student's Current Password",
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
          style: const TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 15,
          ),
          decoration: _inputDecoration(
            label: "Student's Current Password",
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
                  ? "Enter the student's current password to change their email."
                  : "Enter the student's current password to set a new one.";
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
          style: const TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 15,
          ),
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
            if (_currentPassCtl.text.isEmpty) {
              return "Enter the student's current password first.";
            }
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
          style: const TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 15,
          ),
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
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
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
        if (states.contains(WidgetState.focused)) {
          return Colors.white;
        }
        if (states.contains(WidgetState.disabled)) {
          return const Color(0xFFF1F5F9);
        }
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

  Widget _visibilityToggle({
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return IconButton(
      icon: Icon(
        obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        color: const Color(0xFF64748B),
      ),
      onPressed: onToggle,
    );
  }
}
