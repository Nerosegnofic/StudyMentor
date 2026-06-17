// lib/src/presentation/screens/auth/parent_register_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/auth/auth_bloc.dart';
import '../../../bloc/auth/auth_event.dart';
import '../../../bloc/auth/auth_state.dart';
import '../../../../l10n/app_localizations.dart';
import '../../utils/error_localizer.dart';

class ParentRegisterScreen extends StatefulWidget {
  const ParentRegisterScreen({super.key});

  @override
  State<ParentRegisterScreen> createState() => _ParentRegisterScreenState();
}

class _ParentRegisterScreenState extends State<ParentRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameCtl = TextEditingController();
  final _emailCtl = TextEditingController();
  final _passCtl = TextEditingController();
  final _confirmCtl = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).registerAsParentTitle),
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        // Only rebuild the button when loading state changes.
        buildWhen: (prev, curr) => curr is AuthLoading || prev is AuthLoading,
        // Handle side effects without setState.
        listener: (context, state) {
          if (state is AuthEmailUnverified) {
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/', (route) => false);
          }
          if (state is AuthError) {
            if (ModalRoute.of(context)?.isCurrent ?? false) {
              _passCtl.clear();
              _confirmCtl.clear();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(localizeError(state.message, AppLocalizations.of(context)))),
              );
            }
          }
        },
        builder: (context, state) {
          final loading = state is AuthLoading;
          final loc = AppLocalizations.of(context);
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  TextFormField(
                    controller: _fullNameCtl,
                    decoration: InputDecoration(labelText: loc.fieldFullName),
                    validator: (v) =>
                        v!.isEmpty ? loc.validatorFullNameRequired : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailCtl,
                    decoration: InputDecoration(labelText: loc.fieldEmail),
                    validator: (v) =>
                        v!.contains('@') ? null : loc.loginEmailValidator,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passCtl,
                    decoration: InputDecoration(
                      labelText: loc.fieldPassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                    obscureText: _obscurePassword,
                    validator: (v) =>
                        v!.length >= 6 ? null : loc.validatorPasswordMinLength,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _confirmCtl,
                    decoration: InputDecoration(
                      labelText: loc.fieldConfirmPassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),
                    obscureText: _obscureConfirm,
                    validator: (v) => v == _passCtl.text
                        ? null
                        : loc.validatorPasswordsDoNotMatch,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: loading
                        ? null
                        : () {
                            if (_formKey.currentState!.validate()) {
                              context.read<AuthBloc>().add(
                                RegisterRequested(
                                  fullName: _fullNameCtl.text.trim(),
                                  email: _emailCtl.text.trim(),
                                  password: _passCtl.text.trim(),
                                ),
                              );
                            }
                          },
                    child: loading
                        ? const CircularProgressIndicator()
                        : Text(loc.registerButton),
                  ),
                  TextButton(
                    onPressed: () =>
                        Navigator.pushReplacementNamed(context, '/login'),
                    child: Text(loc.alreadyRegisteredButton),
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
