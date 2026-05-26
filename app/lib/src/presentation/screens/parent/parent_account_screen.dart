// lib/src/presentation/screens/parent/parent_account_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../bloc/auth/auth_bloc.dart';
import '../../../bloc/auth/auth_event.dart';
import '../../../bloc/auth/auth_state.dart';
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

  // Baselines for dirty detection.
  String _originalFullName = '';
  String _originalEmail = '';

  // Shown after a successful email-change request.
  String? _pendingEmailNotice;

  // Student list — loaded once on init and updated whenever StudentsLoaded
  // is emitted (e.g. after a student is deleted in the Students tab).
  // null  → still loading (show a spinner on the delete button)
  // empty → no children, delete is allowed
  // non-empty → children exist, delete is blocked
  int? _linkedChildCount;

  // Set to true when LoadStudentsRequested fails so the UI can surface a
  // retry option instead of leaving the delete button frozen indefinitely.
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

    // Kick off a student-list load so we know whether the parent has any
    // linked children. Re-uses the same event/state as ParentStudents —
    // no new BLoC wiring needed.
    if (user != null) {
      context.read<AuthBloc>().add(LoadStudentsRequested(parentUid: user.uid));
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

  // ── retry child-list load ───────────────────────────────────────────────────

  void _retryLoadChildren() {
    final authState = context.read<AuthBloc>().state;
    final uid = authState is AuthAuthenticated ? authState.user.uid : null;
    if (uid == null) return;

    setState(() {
      _childLoadError = false;
      _linkedChildCount = null; // back to loading state
    });
    context.read<AuthBloc>().add(LoadStudentsRequested(parentUid: uid));
  }

  // ── delete account ──────────────────────────────────────────────────────────
  //
  // Two-step flow:
  //   1. Warning dialog (unchanged) — asks the user to confirm they understand
  //      all student accounts must be deleted first.
  //   2. _ParentDeletePasswordDialog — a self-contained StatefulWidget that
  //      dispatches DeleteParentAccountRequested, shows a spinner while the
  //      request is in flight, surfaces auth errors inline, and only closes
  //      when the deletion succeeds or the user cancels.
  //      The dialog is non-dismissible (barrier + back) while loading to prevent
  //      the user from abandoning an in-flight delete without feedback.

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
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (proceed != true || !mounted) return;

    // Step 2: Password confirmation dialog — self-contained, stays open on
    // error, closes automatically on ParentAccountDeleted.
    //
    // barrierDismissible is false here: _ParentDeletePasswordDialog also
    // uses PopScope(canPop: !_isLoading) to block the back gesture while a
    // delete is in flight, but setting barrierDismissible: false closes the
    // second dismissal path (tapping the scrim) for the same period.
    // When _isLoading is false the dialog controls its own dismissal via the
    // Cancel button, so the tighter default is the correct one.
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<AuthBloc>(),
        child: const _ParentDeletePasswordDialog(),
      ),
    );
  }

  // ── build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2196F3),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Account Settings',
          style: GoogleFonts.cairo(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
        if (state is StudentsLoaded) {
          // Keep _linkedChildCount in sync whenever the student list changes —
          // whether from our own initState request or from the Students tab.
          setState(() {
            _linkedChildCount = state.students.length;
            _childLoadError = false;
          });
        } else if (state is ProfileUpdateLoading) {
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
        } else if (state is AuthError && _linkedChildCount == null) {
          // LoadStudentsRequested failed before we got a count — surface the
          // error and let the user retry rather than leaving them stuck with
          // a frozen spinner and a permanently disabled delete button.
          setState(() => _childLoadError = true);
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
        // ParentAccountDeleteLoading, ParentAccountDeleted, and
        // ParentAccountDeleteError are handled entirely inside
        // _ParentDeletePasswordDialog — no screen-level reaction needed.
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
    // _childLoadError    → load failed; show retry instead of frozen spinner
    // _linkedChildCount == null  → still loading, disable the button
    // _linkedChildCount == 0     → no children, allow deletion
    // _linkedChildCount  > 0     → children exist, block deletion
    final isLoadingChildren = !_childLoadError && _linkedChildCount == null;
    final hasLinkedChildren =
        _linkedChildCount != null && _linkedChildCount! > 0;
    final canDelete =
        !isLoadingChildren && !hasLinkedChildren && !_childLoadError;

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
              // ── Child-load error notice with retry ─────────────────────
              if (_childLoadError) ...[
                const SizedBox(height: 10),
                _buildChildLoadErrorNotice(),
              ],
              // ── Linked-children restriction notice ─────────────────────
              if (hasLinkedChildren) ...[
                const SizedBox(height: 10),
                _buildLinkedChildrenNotice(),
              ],
              const SizedBox(height: 12),
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
                            color: canDelete
                                ? Colors.red.shade600
                                : Colors.grey.shade400,
                          ),
                    label: Text(
                      'Delete My Account',
                      style: TextStyle(
                        color: canDelete
                            ? Colors.red.shade600
                            : Colors.grey.shade400,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(
                        color: canDelete
                            ? Colors.red.shade400
                            : Colors.grey.shade300,
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
        ),
      ],
    );
  }

  // ── child-load error notice ────────────────────────────────────────────────

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
            child: Icon(
              Icons.wifi_off_rounded,
              size: 15,
              color: Color(0xFFF57C00),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Could not verify linked students. '
              'Deletion is disabled until this is resolved.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange.shade900,
                height: 1.4,
              ),
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
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── linked-children restriction notice ────────────────────────────────────

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
            child: Icon(
              Icons.child_care_rounded,
              size: 15,
              color: Color(0xFFF57C00),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'You can only delete your account after removing all linked '
              'children. Go to the Students tab to delete each child\'s '
              'account first.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange.shade900,
                height: 1.4,
              ),
            ),
          ),
        ],
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

// ── _ParentDeletePasswordDialog ───────────────────────────────────────────────
//
// Self-contained password-confirmation dialog for parent account deletion.
//
// Lifecycle:
//   • "Delete Account" pressed        → dispatches DeleteParentAccountRequested,
//                                       shows an inline spinner, disables buttons.
//   • ParentAccountDeleteLoading      → spinner visible, buttons disabled,
//                                       back gesture and barrier both blocked
//                                       via PopScope(canPop: false).
//   • ParentAccountDeleted            → pops itself; AuthUnauthenticated follows
//                                       and the root navigator handles sign-out.
//   • ParentAccountDeleteError        → stops spinner, shows the error message
//                                       inline as the field's errorText; dialog
//                                       remains open for the user to correct.
//   • "Cancel" pressed / tap outside  → pops normally (only when not loading).
//
// Dismissal is guarded on two levels:
//   1. showDialog(barrierDismissible: false) — prevents scrim taps at all times.
//      The Cancel button provides a deliberate exit when not loading.
//   2. PopScope(canPop: !_isLoading) — blocks the Android back gesture / back
//      button exclusively while the delete request is in flight.

class _ParentDeletePasswordDialog extends StatefulWidget {
  const _ParentDeletePasswordDialog();

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
    context.read<AuthBloc>().add(
      DeleteParentAccountRequested(currentPassword: password),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Block the back gesture / Android back button while the delete request
      // is in flight. When not loading, the back gesture dismisses normally
      // (equivalent to tapping Cancel).
      canPop: !_isLoading,
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is ParentAccountDeleteLoading) {
            setState(() => _isLoading = true);
          } else if (state is ParentAccountDeleted) {
            // Close the dialog. AuthUnauthenticated follows immediately and the
            // root navigator redirects to the login screen — no extra navigation
            // needed here.
            Navigator.of(context).pop();
          } else if (state is ParentAccountDeleteError) {
            setState(() {
              _isLoading = false;
              _errorMessage = state.message;
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
                child: Icon(
                  Icons.lock_outline,
                  color: Colors.red.shade600,
                  size: 20,
                ),
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
                    if (_errorMessage != null) {
                      setState(() => _errorMessage = null);
                    }
                  },
                  onSubmitted: (_) {
                    if (!_isLoading) _submit();
                  },
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    errorText: _errorMessage,
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Colors.red.shade600,
                        width: 1.5,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.red.shade400),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Colors.red.shade600,
                        width: 1.5,
                      ),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 18,
                        color: Colors.grey.shade500,
                      ),
                      onPressed: _isLoading
                          ? null
                          : () => setState(() => _obscure = !_obscure),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Delete Account'),
            ),
          ],
        ),
      ),
    );
  }
}
