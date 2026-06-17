import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/auth/auth_bloc.dart';
import '../../../bloc/auth/auth_event.dart';
import '../../../bloc/auth/auth_state.dart';
import '../../../../l10n/app_localizations.dart';
import '../../utils/error_localizer.dart';

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
          if (state is AuthEmailUnverified) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppLocalizations.of(context).emailNotVerifiedYetMessage)),
            );
          }
          if (state is EmailVerificationSent) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppLocalizations.of(context).emailVerificationLinkSentMessage)),
            );
          }
          if (state is EmailVerificationError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(localizeError(state.message, AppLocalizations.of(context)))),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;
          final loc = AppLocalizations.of(context);
          return Scaffold(
            appBar: AppBar(
              title: Text(loc.confirmEmailTitle),
              automaticallyImplyLeading: false, // hide the back arrow
            ),
            body: Center(
              child: isLoading
                  ? const CircularProgressIndicator()
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            loc.confirmEmailInstructions,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => context.read<AuthBloc>().add(
                            SendEmailVerificationRequested(),
                          ),
                          child: Text(loc.sendEmailVerificationButton),
                        ),
                        ElevatedButton(
                          onPressed: () => context.read<AuthBloc>().add(
                            CheckEmailVerificationRequested(),
                          ),
                          child: Text(loc.emailVerifiedButton),
                        ),
                        TextButton(
                          onPressed: () =>
                              context.read<AuthBloc>().add(LogoutRequested()),
                          child: Text(loc.logOutButton),
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
