// lib/src/presentation/screens/parent/parent_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import '../../../bloc/auth/auth_bloc.dart';
import '../../../bloc/auth/auth_event.dart';
import '../../../bloc/students/students_bloc.dart';
import '../../../bloc/students/students_event.dart';
import 'add_student_screen.dart';
import 'parent_home_dashboard.dart';
import 'parent_permission_gate_screen.dart';

class ParentScreen extends StatefulWidget {
  final String fullName;
  final String uid;
  final int initialIndex;

  const ParentScreen({
    super.key,
    required this.fullName,
    required this.uid,
    this.initialIndex = 0,
  });

  @override
  State<ParentScreen> createState() => _ParentScreenState();
}

class _ParentScreenState extends State<ParentScreen>
    with WidgetsBindingObserver {
  bool _permissionsCleared = false;
  final _dashboardKey = GlobalKey<ParentHomeDashboardState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh child cards + AI summary when returning from background so the
    // dashboard isn't showing stale data. refresh() bumps the dashboard's
    // refreshKey, which drives ChildCard + AiSummaryCarousel reloads.
    if (state == AppLifecycleState.resumed && _permissionsCleared) {
      _dashboardKey.currentState?.refresh();
    }
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
        backgroundColor: const Color(0xFFF5F7FA),
        body: ParentHomeDashboard(
          key: _dashboardKey,
          parentUid: widget.uid,
          fullName: widget.fullName,
          onAddStudentPressed: _openAddStudentScreen,
        ),
      ),
    );
  }
}
