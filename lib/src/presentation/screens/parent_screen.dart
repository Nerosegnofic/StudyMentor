import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';
import '../../domain/models/student_model.dart';
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

  @override
  void initState() {
    super.initState();
    context.read<AuthBloc>().add(LoadStudentsRequested(parentUid: widget.uid));
  }

  Future<void> _refresh() async {
    context.read<AuthBloc>().add(LoadStudentsRequested(parentUid: widget.uid));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is StudentsLoaded) {
          setState(() => _students = state.students);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Welcome, ${widget.fullName}'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => context.read<AuthBloc>().add(LogoutRequested()),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _refresh,
          child: _students.isEmpty
              ? const SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: 300,
                    child: Center(child: Text('No students yet. Add one!')),
                  ),
                )
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: _students.length,
                  itemBuilder: (context, index) {
                    final student = _students[index];
                    return ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(student.fullName),
                      subtitle: Text(student.email),
                      trailing: Text('XP: ${student.totalXp ?? 0}'),
                    );
                  },
                ),
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
    );
  }
}
