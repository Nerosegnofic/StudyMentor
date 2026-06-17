// lib/src/presentation/screens/auth/parent_register_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/auth/auth_bloc.dart';
import '../../../bloc/auth/auth_event.dart';
import '../../../bloc/auth/auth_state.dart';
import 'auth_style.dart';

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
  String? _error;

  void _clearError() {
    if (_error != null) setState(() => _error = null);
  }

  @override
  Widget build(BuildContext context) {
    // Computed above the Scaffold so the keyboard is detected (a Scaffold zeroes
    // viewInsets.bottom for its body subtree).
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    return Scaffold(
      backgroundColor: kAuthBackground,
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
              setState(() => _error = state.message);
            }
          }
        },
        builder: (context, state) {
          final loading = state is AuthLoading;
          return Column(
            children: [
              AuthHeader(
                subtitle: 'Create your parent account',
                keyboardOpen: keyboardOpen,
                onBack: () => Navigator.of(context).maybePop(),
              ),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                    children: [
                      authErrorBanner(_error),
                      TextFormField(
                        controller: _fullNameCtl,
                        onChanged: (_) => _clearError(),
                        decoration: authInputDecoration(
                          label: 'Full Name',
                          icon: Icons.person_outline,
                        ),
                        validator: (v) => v!.isEmpty ? 'Full name is required.' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _emailCtl,
                        onChanged: (_) => _clearError(),
                        decoration: authInputDecoration(
                          label: 'Email',
                          icon: Icons.email_outlined,
                        ),
                        validator: (v) => v!.contains('@') ? null : 'Please enter a valid email address.',
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _passCtl,
                        onChanged: (_) => _clearError(),
                        decoration: authInputDecoration(
                          label: 'Password',
                          icon: Icons.lock_outline,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey.shade500,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                        ),
                        obscureText: _obscurePassword,
                        validator: (v) => v!.length >= 6 ? null : 'Password must be at least 6 characters.',
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _confirmCtl,
                        onChanged: (_) => _clearError(),
                        decoration: authInputDecoration(
                          label: 'Confirm Password',
                          icon: Icons.lock_outline,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey.shade500,
                            ),
                            onPressed: () => setState(
                              () => _obscureConfirm = !_obscureConfirm,
                            ),
                          ),
                        ),
                        obscureText: _obscureConfirm,
                        validator: (v) =>
                            v == _passCtl.text ? null : 'Passwords do not match',
                      ),
                      const SizedBox(height: 24),
                      authPrimaryButton(
                        label: 'Register',
                        loading: loading,
                        onPressed: () {
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
                      ),
                      const SizedBox(height: 4),
                      authTextLink(
                        text: 'Already registered? Sign In',
                        onPressed: () =>
                            Navigator.pushReplacementNamed(context, '/login'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
