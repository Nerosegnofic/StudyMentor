import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';

class ConfirmEmailScreen extends StatelessWidget {
  const ConfirmEmailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Confirm Email')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Please verify your email.'),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.read<AuthBloc>().add(
                SendEmailVerificationRequested(),
              ),
              child: Text('Send Email Verification Link'),
            ),
            ElevatedButton(
              onPressed: () => context.read<AuthBloc>().add(
                CheckEmailVerificationRequested(),
              ),
              child: Text('I have verified — Refresh'),
            ),
            TextButton(
              onPressed: () {
                context.read<AuthBloc>().add(LogoutRequested());
              },
              child: Text('Cancel / Logout'),
            ),
          ],
        ),
      ),
    );
  }
}
