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
    setState(() => _isLoading = true);
    context.read<AuthBloc>().add(
      LoadStudentsRequested(parentUid: widget.parentUid),
    );
  }

  /// Opens the configuration screen for a verified student.
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

  Widget _buildStudentList() {
    final unverifiedStudents = _students
        .where((s) => !s.isEmailVerified)
        .toList();

    // Show a hint banner when all students are verified so the parent
    // knows the cards are now interactive.
    final allVerified =
        _students.isNotEmpty && _students.every((s) => s.isEmailVerified);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 12, bottom: 24),
      children: [
        if (unverifiedStudents.isNotEmpty)
          _buildUnverifiedBanner(unverifiedStudents),
        if (allVerified) _buildTapHintBanner(),
        for (final student in _students)
          StudentCard(
            student: student,
            // Only verified students get an onTap handler.
            onTap: student.isEmailVerified
                ? () => _openConfigScreen(student)
                : null,
          ),
      ],
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
              'Tap a student card to configure their app usage rules.',
              style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF4A6CF7),
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is StudentsLoaded) {
          setState(() {
            _students = state.students;
            _isLoading = false;
          });
          _startPollingIfNeeded();
        }

        if (state is AuthError) {
          setState(() => _isLoading = false);
        }
      },
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _students.isEmpty
            ? _buildEmptyState()
            : _buildStudentList(),
      ),
    );
  }
}
