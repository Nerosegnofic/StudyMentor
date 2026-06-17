import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/auth/auth_event.dart';
import '../../../bloc/auth/auth_state.dart';
import '../../../bloc/auth/auth_bloc.dart';
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
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(loc.resetPasswordTitle)),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is PasswordResetEmailSent) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(loc.passwordResetLinkSentMessage)));
            Navigator.pop(context);
          }
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(localizeError(state.message, loc))),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _emailCtl,
                  decoration: InputDecoration(labelText: loc.fieldEmail),
                  validator: (v) => v!.contains('@') ? null : loc.loginEmailValidator,
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      context.read<AuthBloc>().add(
                        PasswordResetRequested(email: _emailCtl.text.trim()),
                      );
                    }
                  },
                  child: Text(loc.sendResetLinkButton),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
