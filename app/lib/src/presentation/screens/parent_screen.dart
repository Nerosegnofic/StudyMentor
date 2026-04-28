// lib/src/presentation/screens/parent_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';
import '../../domain/models/student_model.dart';
import '../widgets/student_card.dart';
import 'add_student_screen.dart';

class ParentScreen extends StatefulWidget {
  final String fullName;
  final String uid;
  const ParentScreen({super.key, required this.fullName, required this.uid});

  @override
  State<ParentScreen> createState() => _ParentScreenState();
}

class _ParentScreenState extends State<ParentScreen> {
  List<StudentModel> _students = [];
  bool _isLoading = true;
  Timer? _verificationPollTimer;

  // ── lifecycle ───────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    context.read<AuthBloc>().add(LoadStudentsRequested(parentUid: widget.uid));
  }

  @override
  void dispose() {
    _verificationPollTimer?.cancel();
    super.dispose();
  }

  // ── polling ─────────────────────────────────────────────────────────────────

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

  // ── actions ─────────────────────────────────────────────────────────────────

  Future<void> _refresh() async {
    setState(() => _isLoading = true);
    context.read<AuthBloc>().add(LoadStudentsRequested(parentUid: widget.uid));
  }

  // ── build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) SystemNavigator.pop();
      },
      child: BlocListener<AuthBloc, AuthState>(
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
        child: Scaffold(
          backgroundColor: const Color(0xFFF5F7FF),
          appBar: AppBar(
            title: Text('Welcome, ${widget.fullName}'),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () =>
                    context.read<AuthBloc>().add(LogoutRequested()),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _refresh,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _students.isEmpty
                    ? _buildEmptyState()
                    : _buildStudentList(),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddStudentScreen(parentUid: widget.uid),
                ),
              );
              if (mounted) {
                context.read<AuthBloc>().add(
                  LoadStudentsRequested(parentUid: widget.uid),
                );
              }
            },
            icon: const Icon(Icons.person_add),
            label: const Text('Add Student'),
          ),
        ),
      ),
    );
  }

  // ── sub-widgets ─────────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: 400,
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
                'Tap the button below to add your first child.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentList() {
    final unverifiedStudents = _students.where((s) => !s.isEmailVerified).toList();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 12, bottom: 100),
      children: [
        if (unverifiedStudents.isNotEmpty)
          _buildUnverifiedBanner(unverifiedStudents),
        for (final student in _students)
          StudentCard(
            student: student,
            onTap: null,
          ),
      ],
    );
  }

  Widget _buildUnverifiedBanner(List<StudentModel> unverifiedStudents) {
    final count = unverifiedStudents.length;
    final names = unverifiedStudents.map((s) => s.fullName.split(' ').first).toList();

    // Build a natural-language name list: "Alice", "Alice and Bob",
    // "Alice, Bob and Charlie", etc.
    String nameList;
    if (names.length == 1) {
      nameList = names.first;
    } else if (names.length == 2) {
      nameList = '${names[0]} and ${names[1]}';
    } else {
      final allButLast = names.sublist(0, names.length - 1).join(', ');
      nameList = '$allButLast and ${names.last}';
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
                  'Ask them to open the app, log in with the credentials you created, and verify their email. This card will update automatically once they do.',
                  style: TextStyle(fontSize: 12, color: Color(0xFFBF360C)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}