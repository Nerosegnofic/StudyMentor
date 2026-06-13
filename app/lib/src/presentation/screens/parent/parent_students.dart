// lib/src/presentation/screens/parent/parent_students.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/students/students_bloc.dart';
import '../../../bloc/students/students_event.dart';
import '../../../bloc/students/students_state.dart';
import '../../../domain/models/student_model.dart';
import '../../widgets/student_card.dart';
import 'student_profile_dashboard.dart';

class ParentStudents extends StatefulWidget {
  final String parentUid;

  const ParentStudents({super.key, required this.parentUid});

  @override
  State<ParentStudents> createState() => _ParentStudentsState();
}

class _ParentStudentsState extends State<ParentStudents> {
  List<StudentModel> _students = [];
  bool _isLoading = true;

  Timer? _verificationPollTimer;

  @override
  void initState() {
    super.initState();
    context.read<StudentsBloc>().add(
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
        context.read<StudentsBloc>().add(
          RefreshStudentVerificationsRequested(currentStudents: _students),
        );
      });
    } else if (!hasUnverified) {
      _verificationPollTimer?.cancel();
      _verificationPollTimer = null;
    }
  }

  Future<void> _refresh() async {
    context.read<StudentsBloc>().add(
      LoadStudentsRequested(parentUid: widget.parentUid),
    );
  }

  Future<void> _openConfigScreen(StudentModel student) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<StudentsBloc>(),
          child: StudentProfileDashboard(student: student),
        ),
      ),
    );
  }

  Future<void> _confirmAndDeleteStudent(StudentModel student) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<StudentsBloc>(),
        child: _DeleteConfirmationDialog(
          student: student,
          parentUid: widget.parentUid,
        ),
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
                'No children added yet.',
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

  Widget _buildDeleteButton(StudentModel student) {
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
          onPressed: () => _confirmAndDeleteStudent(student),
          icon: const Icon(Icons.delete_outline, size: 15),
          label: const Text(
            'Delete Account',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

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

  @override
  Widget build(BuildContext context) {
    return BlocListener<StudentsBloc, StudentsState>(
      listener: (context, state) {
        if (state is StudentsLoaded) {
          setState(() {
            _students = state.students;
            _isLoading = false;
          });
          _startPollingIfNeeded();
        }

        if (state is StudentDeleted) {
          setState(() => _isLoading = true);
          context.read<StudentsBloc>().add(
            LoadStudentsRequested(parentUid: widget.parentUid),
          );
        }

        if (state is StudentsError) {
          setState(() => _isLoading = false);
        }
      },
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: Stack(
          children: [
            if (_isLoading)
              const SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: SizedBox(height: 420),
              )
            else if (_students.isEmpty)
              _buildEmptyState()
            else
              _buildStudentList(),

            if (_isLoading) const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }
}

// ── _DeleteConfirmationDialog ─────────────────────────────────────────────────

class _DeleteConfirmationDialog extends StatefulWidget {
  final StudentModel student;
  final String parentUid;

  const _DeleteConfirmationDialog({
    required this.student,
    required this.parentUid,
  });

  @override
  State<_DeleteConfirmationDialog> createState() =>
      _DeleteConfirmationDialogState();
}

class _DeleteConfirmationDialogState extends State<_DeleteConfirmationDialog> {
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _submitted = false;
  bool _isLoading = false;
  String? _serverError;

  String get _firstName => widget.student.fullName.split(' ').first;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
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

    context.read<StudentsBloc>().add(
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
    return BlocListener<StudentsBloc, StudentsState>(
      listener: (context, state) {
        if (state is StudentDeleteLoading) {
          setState(() => _isLoading = true);
        } else if (state is StudentDeleted &&
            state.studentUid == widget.student.uid) {
          Navigator.of(context).pop();
        } else if (state is StudentDeleteError) {
          final isWrongPassword = state.message.contains('Invalid credentials');
          setState(() {
            _isLoading = false;
            _serverError = isWrongPassword
                ? 'Incorrect password. Please try again.'
                : state.message;
          });
        }
      },
      child: PopScope(
        canPop: !_isLoading,
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
                'Delete Child Account',
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
                      const TextSpan(
                        text: 'You are about to permanently delete ',
                      ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
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
                          '$_firstName\'s login credentials, progress, and settings '
                          'will all be permanently deleted.',
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
                  enabled: !_isLoading,
                  onChanged: (_) {
                    if (_submitted) setState(() => _serverError = null);
                  },
                  onSubmitted: (_) {
                    if (!_isLoading) _submit();
                  },
                  decoration: InputDecoration(
                    labelText: 'Student\'s password',
                    hintText: 'Password you created for $_firstName',
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
