// lib/src/presentation/screens/parent/parent_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import '../../../bloc/auth/auth_bloc.dart';
import '../../../bloc/auth/auth_event.dart';
import '../../widgets/parent_navigation_bar.dart';
import 'add_student_screen.dart';
import 'parent_dashboard.dart';
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
  int _selectedIndex = 1;

  // False until the parent has passed (or skipped) the permission gate.
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
      context.read<AuthBloc>().add(
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
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) SystemNavigator.pop();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FF),
        appBar: AppBar(
          title: Text('Welcome, ${widget.fullName}'),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => context.read<AuthBloc>().add(LogoutRequested()),
            ),
          ],
        ),
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            ParentDashboard(parentUid: widget.uid),
            ParentStudents(parentUid: widget.uid),
            const ParentSettings(),
          ],
        ),
        bottomNavigationBar: ParentNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onTabSelected,
        ),
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
