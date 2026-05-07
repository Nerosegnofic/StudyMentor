import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/auth/auth_bloc.dart';
import '../../../bloc/auth/auth_event.dart';
import '../../../bloc/auth/auth_state.dart';

class ConfirmEmailScreen extends StatelessWidget {
  const ConfirmEmailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Block back entirely — user must verify or explicitly tap Cancel/Logout.
      // Going back would leave a half-authenticated session with no way to proceed.
      canPop: false,
      child: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/', (route) => false);
          }
          if (state is AuthUnauthenticated) {
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/', (route) => false);
          }
          if (state is EmailVerificationError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;
          return Scaffold(
            appBar: AppBar(
              title: const Text('Confirm Email'),
              automaticallyImplyLeading: false, // hide the back arrow
            ),
            body: Center(
              child: isLoading
                  ? const CircularProgressIndicator()
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Please verify your email.'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => context.read<AuthBloc>().add(
                            SendEmailVerificationRequested(),
                          ),
                          child: const Text('Send Email Verification Link'),
                        ),
                        ElevatedButton(
                          onPressed: () => context.read<AuthBloc>().add(
                            CheckEmailVerificationRequested(),
                          ),
                          child: const Text('I have verified — Refresh'),
                        ),
                        TextButton(
                          onPressed: () =>
                              context.read<AuthBloc>().add(LogoutRequested()),
                          child: const Text('Cancel / Logout'),
                        ),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }
}
