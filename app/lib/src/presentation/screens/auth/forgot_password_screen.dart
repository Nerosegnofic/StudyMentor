import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/auth/auth_event.dart';
import '../../../bloc/auth/auth_state.dart';
import '../../../bloc/auth/auth_bloc.dart';
import 'auth_style.dart';
import '../../../../l10n/app_localizations.dart';
import '../../utils/error_localizer.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _error;
  @override
  Widget build(BuildContext context) {
    // Computed above the Scaffold so the keyboard is detected (a Scaffold zeroes
    // viewInsets.bottom for its body subtree).
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    return Scaffold(
      backgroundColor: kAuthBackground,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          final loc = AppLocalizations.of(context);
          if (state is PasswordResetEmailSent) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(loc.passwordResetLinkSentMessage)));
            Navigator.pop(context);
          }
          if (state is AuthError) {
            setState(() => _error = localizeError(state.message, AppLocalizations.of(context)));
          }
        },
        child: Column(
          children: [
            AuthHeader(
              subtitle: AppLocalizations.of(context).resetPasswordSubtitle,
              keyboardOpen: keyboardOpen,
              onBack: () => Navigator.of(context).maybePop(),
              mascotAsset: 'assets/mascot/sad.png',
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      authErrorBanner(_error),
                      TextFormField(
                        controller: _emailCtl,
                        onChanged: (_) {
                          if (_error != null) setState(() => _error = null);
                        },
                        decoration: authInputDecoration(
                          label: AppLocalizations.of(context).fieldEmail,
                          icon: Icons.email_outlined,
                        ),
                        validator: (v) => v!.contains('@') ? null : AppLocalizations.of(context).loginEmailValidator,
                      ),
                      SizedBox(height: 24),
                      authPrimaryButton(
                        label: AppLocalizations.of(context).sendResetLinkButton,
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            context.read<AuthBloc>().add(
                              PasswordResetRequested(
                                email: _emailCtl.text.trim(),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
