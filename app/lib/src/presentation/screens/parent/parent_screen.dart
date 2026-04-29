import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import '../../../bloc/auth/auth_bloc.dart';
import '../../../bloc/auth/auth_event.dart';
import '../../../bloc/auth/auth_state.dart';
import '../../widgets/parent_navigation_bar.dart';
import 'add_student_screen.dart';
import 'parent_dashboard.dart';
import 'parent_settings.dart';
import 'parent_students.dart';

class ParentScreen extends StatefulWidget {
  final String fullName;
  final String uid;

  const ParentScreen({super.key, required this.fullName, required this.uid});

  @override
  State<ParentScreen> createState() => _ParentScreenState();
}

class _ParentScreenState extends State<ParentScreen> {
  int _selectedIndex = 1;

  void _onTabSelected(int index) {
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) SystemNavigator.pop();
      },
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
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
          body: IndexedStack(
            index: _selectedIndex,
            children: [
              const ParentDashboard(),
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
      ),
    );
  }
}
