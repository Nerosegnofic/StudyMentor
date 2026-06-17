import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/auth/auth_event.dart';
import '../../../bloc/auth/auth_state.dart';
import '../../../bloc/auth/auth_bloc.dart';
import 'auth_style.dart';
import '../../../../l10n/app_localizations.dart';

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
    final loc = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: kAuthBackground,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is PasswordResetEmailSent) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(loc.passwordResetLinkSentMessage)));
            Navigator.pop(context);
          }
          if (state is AuthError) {
            setState(() => _error = state.message);
          }
        },
        child: Column(
          children: [
            AuthHeader(
              subtitle: "We'll email you a reset link",
              keyboardOpen: keyboardOpen,
              onBack: () => Navigator.of(context).maybePop(),
              logo: Icons.lock_reset_rounded,
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
                          label: 'Email',
                          icon: Icons.email_outlined,
                        ),
                        validator: (v) => v!.contains('@') ? null : 'Please enter a valid email address.',
                      ),
                      SizedBox(height: 24),
                      authPrimaryButton(
                        label: 'Send Reset Link',
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
