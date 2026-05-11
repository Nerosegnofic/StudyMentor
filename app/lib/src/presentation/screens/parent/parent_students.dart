import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/auth/auth_bloc.dart';
import '../../../bloc/auth/auth_event.dart';
import '../../../bloc/auth/auth_state.dart';
import '../../../domain/models/student_model.dart';
import '../../widgets/student_card.dart';
import 'student_config_screen.dart';

class ParentStudents extends StatefulWidget {
  final String parentUid;

  const ParentStudents({super.key, required this.parentUid});

  @override
  State<ParentStudents> createState() => _ParentStudentsState();
}

class _ParentStudentsState extends State<ParentStudents> {
  List<StudentModel> _students = [];
  bool _isLoading = true;

  // Tracks which student UID is currently being deleted, so we can show a
  // per-card loading indicator without blocking the whole screen.
  String? _deletingStudentUid;

  Timer? _verificationPollTimer;

  @override
  void initState() {
    super.initState();
    context.read<AuthBloc>().add(
      LoadStudentsRequested(parentUid: widget.parentUid),
    );
  }

  @override
  void dispose() {
    _verificationPollTimer?.cancel();
    super.dispose();
  }

  void _startPollingIfNeeded() {
    final hasUnverified = _students.any((s) => !s.isEmailVerified);

    if (hasUnverified && _verificationPollTimer == null) {
      _verificationPollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        if (!mounted) return;
        context.read<AuthBloc>().add(
          RefreshStudentVerificationsRequested(currentStudents: _students),
        );
      });
    } else if (!hasUnverified) {
      _verificationPollTimer?.cancel();
      _verificationPollTimer = null;
    }
  }

  Future<void> _refresh() async {
    context.read<AuthBloc>().add(
      LoadStudentsRequested(parentUid: widget.parentUid),
    );
  }

  Future<void> _openConfigScreen(StudentModel student) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<AuthBloc>(),
          child: StudentConfigScreen(student: student),
        ),
      ),
    );
  }

  // ── Delete flow ────────────────────────────────────────────────────────────

  // _activeDeleteDialog lets the StudentDeleteError listener push an inline
  // error message directly into the open dialog, keeping it open so the
  // parent can correct their password without the dialog closing.
  _DeleteConfirmationDialogState? _activeDeleteDialog;

  Future<void> _confirmAndDeleteStudent(StudentModel student) async {
    final firstName = student.fullName.split(' ').first;

    final password = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => _DeleteConfirmationDialog(
        student: student,
        firstName: firstName,
        onStateCreated: (s) => _activeDeleteDialog = s,
      ),
    );

    _activeDeleteDialog = null;

    if (password == null || password.isEmpty || !mounted) return;

    setState(() => _deletingStudentUid = student.uid);

    context.read<AuthBloc>().add(
      DeleteStudentRequested(
        studentUid: student.uid,
        studentEmail: student.email,
        studentPassword: password,
        parentUid: widget.parentUid,
      ),
    );
  }

  // ── Empty / banner widgets ─────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: 420,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.group_outlined, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'No students yet.',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Use the Add Student button to register your first child.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnverifiedBanner(List<StudentModel> unverifiedStudents) {
    final count = unverifiedStudents.length;
    final names = unverifiedStudents
        .map((s) => s.fullName.split(' ').first)
        .toList();

    String nameList;
    if (names.length == 1) {
      nameList = names.first;
    } else if (names.length == 2) {
      nameList = '${names[0]} and ${names[1]}';
    } else {
      nameList =
          '${names.sublist(0, names.length - 1).join(', ')} and ${names.last}';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFB74D), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.info_outline, color: Color(0xFFF57C00), size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count == 1
                      ? '$nameList hasn\'t activated their account yet.'
                      : '$nameList haven\'t activated their accounts yet.',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFE65100),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Ask them to open the app, log in with the credentials you created, and verify their email.',
                  style: TextStyle(fontSize: 12, color: Color(0xFFBF360C)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTapHintBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EDFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4A6CF7).withOpacity(0.3)),
      ),
      child: Row(
        children: const [
          Icon(Icons.touch_app_outlined, color: Color(0xFF4A6CF7), size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Tap on a student card to monitor their activity, manage app usage rules, and review their academic status.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF4A6CF7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Delete button rendered beneath each unverified card ───────────────────

  Widget _buildDeleteButton(StudentModel student) {
    final isDeleting = _deletingStudentUid == student.uid;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: SizedBox(
        width: double.infinity,
        height: 36,
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFD32F2F),
            side: const BorderSide(color: Color(0xFFEF9A9A), width: 1),
            backgroundColor: const Color(0xFFFFF5F5),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            padding: EdgeInsets.zero,
          ),
          onPressed: isDeleting
              ? null
              : () => _confirmAndDeleteStudent(student),
          icon: isDeleting
              ? const SizedBox(
                  width: 13,
                  height: 13,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.8,
                    color: Color(0xFFD32F2F),
                  ),
                )
              : const Icon(Icons.delete_outline, size: 15),
          label: Text(
            isDeleting ? 'Deleting…' : 'Delete Account',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  // ── Student list ───────────────────────────────────────────────────────────

  Widget _buildStudentList() {
    final unverifiedStudents = _students
        .where((s) => !s.isEmailVerified)
        .toList();

    final allVerified =
        _students.isNotEmpty && _students.every((s) => s.isEmailVerified);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 12, bottom: 24),
      children: [
        if (unverifiedStudents.isNotEmpty)
          _buildUnverifiedBanner(unverifiedStudents),
        if (allVerified) _buildTapHintBanner(),
        for (final student in _students) ...[
          StudentCard(
            student: student,
            onTap: student.isEmailVerified
                ? () => _openConfigScreen(student)
                : null,
          ),
          if (!student.isEmailVerified) _buildDeleteButton(student),
        ],
      ],
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is StudentsLoaded) {
          setState(() {
            _students = state.students;
            _isLoading = false;
            _deletingStudentUid = null;
          });
          _startPollingIfNeeded();
        }

        if (state is StudentDeleted) {
          // Switch to the loading spinner immediately so the empty state never
          // flashes while the fresh list is being fetched. The previous
          // approach of optimistically trimming _students could leave the list
          // empty (e.g. after deleting the only student) which caused the
          // "No students yet" text to appear briefly before StudentsLoaded
          // arrived.
          setState(() {
            _isLoading = true;
            _deletingStudentUid = null;
          });
          // Re-fetch the authoritative list from the server. The bloc emits
          // StudentsLoaded during deletion before this screen is listening, so
          // a fresh request here guarantees the list is always correct.
          context.read<AuthBloc>().add(
            LoadStudentsRequested(parentUid: widget.parentUid),
          );
        }

        if (state is StudentDeleteError) {
          setState(() => _deletingStudentUid = null);
          final isWrongPassword = state.message.contains('Invalid credentials');
          if (isWrongPassword && _activeDeleteDialog != null) {
            // Dialog is still open — push the error inline so the parent
            // can correct their password without the dialog closing and
            // without any snackbar appearing.
            _activeDeleteDialog!.showServerError(
              'Incorrect password. Please try again.',
            );
          } else {
            // Dialog already dismissed or non-password error — fall back to
            // a snackbar.
            final message = isWrongPassword
                ? 'Incorrect password. Please enter the password you created for this student.'
                : state.message;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: const Color(0xFFD32F2F),
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }
        }

        if (state is AuthError) {
          setState(() {
            _isLoading = false;
            _deletingStudentUid = null;
          });
        }
      },
      child: RefreshIndicator(
        onRefresh: _refresh,
        // Never render a non-scrollable widget as the direct child of
        // RefreshIndicator. The indicator dismisses itself via scroll
        // notifications; if no scrollable descendant exists the spinner
        // never goes away. The initial full-screen loader is shown as an
        // overlay on top of the scrollable content instead.
        child: Stack(
          children: [
            // The scrollable layer is always present so RefreshIndicator
            // can always receive scroll notifications and dismiss itself.
            if (_isLoading)
              // During any loading phase (initial load or post-deletion
              // re-fetch) keep a scrollable subtree in the tree so the
              // RefreshIndicator can always receive scroll notifications.
              const SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: SizedBox(height: 420),
              )
            else if (_students.isEmpty)
              _buildEmptyState()
            else
              _buildStudentList(),

            // Full-screen spinner overlay — shown during the initial load
            // and during the post-deletion re-fetch, but not during a
            // pull-to-refresh (where the RefreshIndicator's own spinner
            // is sufficient).
            if (_isLoading) const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }
}

// ── Confirmation dialog ────────────────────────────────────────────────────────
//
// The TextEditingController is created and disposed entirely within this
// widget's state. Previously it was created outside and passed in, which caused
// a "_dependents.isEmpty" assertion crash because the parent disposed the
// controller immediately after showDialog returned — before Flutter had
// finished tearing down the dialog's widget tree and the TextField had
// released its dependency on the controller.
//
// onStateCreated lets the parent hold a reference to the live State so it can
// call showServerError() to push a wrong-password message inline — keeping the
// dialog open — rather than closing it and showing a snackbar.

class _DeleteConfirmationDialog extends StatefulWidget {
  final StudentModel student;
  final String firstName;
  final void Function(_DeleteConfirmationDialogState state) onStateCreated;

  const _DeleteConfirmationDialog({
    required this.student,
    required this.firstName,
    required this.onStateCreated,
  });

  @override
  State<_DeleteConfirmationDialog> createState() =>
      _DeleteConfirmationDialogState();
}

class _DeleteConfirmationDialogState extends State<_DeleteConfirmationDialog> {
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _submitted = false;
  String? _serverError;

  @override
  void initState() {
    super.initState();
    widget.onStateCreated(this);
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  /// Called by the parent's BlocListener when Firebase rejects the password.
  /// Keeps the dialog open and shows the error beneath the text field.
  void showServerError(String message) {
    setState(() {
      _serverError = message;
      _submitted = true;
    });
  }

  String? get _passwordError {
    if (_serverError != null) return _serverError;
    if (!_submitted) return null;
    if (_passwordController.text.trim().isEmpty) {
      return 'Please enter the student\'s password.';
    }
    return null;
  }

  void _submit() {
    setState(() {
      _submitted = true;
      _serverError = null;
    });
    final password = _passwordController.text.trim();
    if (password.isEmpty) return;
    Navigator.of(context).pop(password);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                  const TextSpan(text: 'You are about to permanently delete '),
                  TextSpan(
                    text: widget.student.fullName,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const TextSpan(
                    text:
                        '\'s account. This will remove all of their data and cannot be undone.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFFB74D)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 1),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      size: 15,
                      color: Color(0xFFF57C00),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${widget.firstName}\'s login credentials, progress, settings, and friends list will all be permanently deleted.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFE65100),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              onChanged: (_) {
                if (_submitted) setState(() => _serverError = null);
              },
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: 'Student\'s password',
                hintText: 'Password you created for ${widget.firstName}',
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
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    size: 18,
                    color: Colors.grey,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
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
          onPressed: _submit,
          child: const Text('Delete Permanently'),
        ),
      ],
    );
  }
}
