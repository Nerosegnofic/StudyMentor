import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';

class StudentScreen extends StatefulWidget {
  final String fullName;
  final String uid;
  const StudentScreen({super.key, required this.fullName, required this.uid});

  @override
  State<StudentScreen> createState() => _StudentScreenState();
}

class _StudentScreenState extends State<StudentScreen> {
  String? _parentFullName;

  @override
  void initState() {
    super.initState();
    context.read<AuthBloc>().add(
      LoadParentNameRequested(studentUid: widget.uid),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is ParentNameLoaded) {
          setState(() => _parentFullName = state.parentFullName);
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
        body: Center(
          child: _parentFullName == null
              ? const CircularProgressIndicator()
              : Text('Your parent is $_parentFullName'),
        ),
      ),
    );
  }
}
