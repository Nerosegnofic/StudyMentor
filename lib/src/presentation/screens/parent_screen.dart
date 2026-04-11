import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../src/bloc/auth/auth_bloc.dart';
import '../../../src/bloc/auth/auth_event.dart';

class ParentScreen extends StatelessWidget {
  final String fullName;
  const ParentScreen({super.key, required this.fullName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, $fullName'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthBloc>().add(LogoutRequested()),
          ),
        ],
      ),
      body: Center(child: Text('Parent dashboard - implement features here')),
    );
  }
}