import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../bloc/auth/auth_bloc.dart';
import '../../../bloc/auth/auth_event.dart';
import '../../../bloc/auth/auth_state.dart';
import 'auth_style.dart';
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
          return Scaffold(
            backgroundColor: kAuthBackground,
            body: Column(
              children: [
                // No back affordance — back is blocked on this screen.
                AuthHeader(subtitle: AppLocalizations.of(context).confirmEmailSubtitle),
                Expanded(
                  child: isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: kAuthGreen),
                        )
                      : Center(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 88,
                                  height: 88,
                                  decoration: BoxDecoration(
                                    color: kAuthGreen.withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.mark_email_unread_outlined,
                                    color: kAuthGreen,
                                    size: 44,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  AppLocalizations.of(context).confirmEmailInstructions,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.cairo(
                                    fontSize: 15,
                                    color: Colors.grey.shade600,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 32),
                                authPrimaryButton(
                                  label: AppLocalizations.of(context).sendEmailVerificationButton,
                                  onPressed: () => context.read<AuthBloc>().add(
                                    SendEmailVerificationRequested(),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                authSecondaryButton(
                                  label: AppLocalizations.of(context).emailVerifiedButton,
                                  onPressed: () => context.read<AuthBloc>().add(
                                    CheckEmailVerificationRequested(),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                authTextLink(
                                  text: AppLocalizations.of(context).logOutButton,
                                  color: Colors.grey.shade600,
                                  onPressed: () => context
                                      .read<AuthBloc>()
                                      .add(LogoutRequested()),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
