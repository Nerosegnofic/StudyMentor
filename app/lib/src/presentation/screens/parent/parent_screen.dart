// lib/src/presentation/screens/parent/parent_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import '../../../bloc/auth/auth_bloc.dart';
import '../../../bloc/auth/auth_event.dart';
import '../../../bloc/students/students_bloc.dart';
import '../../../bloc/students/students_event.dart';
import '../../widgets/parent_navigation_bar.dart';
import 'add_student_screen.dart';
import 'parent_home_dashboard.dart';
import 'parent_permission_gate_screen.dart';
import 'parent_settings.dart';
import 'parent_students.dart';
import 'parent_help_center.dart';

class ParentScreen extends StatefulWidget {
  final String fullName;
  final String uid;

  const ParentScreen({super.key, required this.fullName, required this.uid});

  @override
  State<ParentScreen> createState() => _ParentScreenState();
}

class _ParentScreenState extends State<ParentScreen> {
  // Default to tab 0 — the new Home Dashboard
  int _selectedIndex = 0;

  // False until the parent has granted the battery-optimisation permission.
  bool _permissionsCleared = false;

  void _onTabSelected(int index) {
    if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ParentHelpCenter(uid: widget.uid, fullName: widget.fullName),
        ),
      );
      return;
    }
    setState(() => _selectedIndex = index);
  }

  Future<void> _openAddStudentScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddStudentScreen(parentUid: widget.uid),
      ),
    );
    if (mounted) {
      context.read<StudentsBloc>().add(
          LoadStudentsRequested(parentUid: widget.uid),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show the permission gate until it's cleared.
    if (!_permissionsCleared) {
      return ParentPermissionGateScreen(
        onAllGranted: () => setState(() => _permissionsCleared = true),
        onSignOut: () => context.read<AuthBloc>().add(LogoutRequested()),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) SystemNavigator.pop();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FF),

        // Tab 0 uses its own branded curved header — hide the standard AppBar.
        // All other tabs keep the standard AppBar.
        appBar: _selectedIndex == 0
            ? null
            : AppBar(
                title: Text('Welcome, ${widget.fullName}'),
                automaticallyImplyLeading: false,
              ),

        body: IndexedStack(
          index: _selectedIndex,
          children: [
            // Tab 0 — New premium Home Dashboard
            ParentHomeDashboard(
              parentUid: widget.uid,
              fullName: widget.fullName,
              onAddStudentPressed: _openAddStudentScreen,
            ),
            // Tab 1 — My Students
            ParentStudents(parentUid: widget.uid),
            // Tab 2 — Settings
            const ParentSettings(),
          ],
        ),

        bottomNavigationBar: ParentNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onTabSelected,
        ),

        // Tab 0 owns its own FAB via the Stack inside ParentHomeDashboard.
        // Tab 1 keeps the original extended FAB for adding a student.
        floatingActionButton: _selectedIndex == 1
            ? FloatingActionButton.extended(
                onPressed: _openAddStudentScreen,
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('Add Student'),
              )
            : null,
      ),
    );
  }
}
