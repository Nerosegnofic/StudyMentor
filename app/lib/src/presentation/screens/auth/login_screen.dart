import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/auth/auth_bloc.dart';
import '../../../bloc/auth/auth_event.dart';
import '../../../bloc/auth/auth_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtl = TextEditingController();
  final _passCtl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    final canGoBack = Navigator.of(context).canPop();
    return PopScope(
      canPop: canGoBack,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !canGoBack) SystemNavigator.pop();
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Login')),
        body: BlocConsumer<AuthBloc, AuthState>(
          // Only rebuild the button when loading state changes.
          buildWhen: (prev, curr) => curr is AuthLoading || prev is AuthLoading,
          // Handle side effects without setState.
          listener: (context, state) {
            if (state is AuthAuthenticated) {
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/', (route) => false);
            }
            if (state is AuthEmailUnverified) {
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/', (route) => false);
            }
            if (state is AuthError) {
              if (ModalRoute.of(context)?.isCurrent ?? false) {
                _passCtl.clear();
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(state.message)));
              }
            }
          },
          builder: (context, state) {
            final loading = state is AuthLoading;
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailCtl,
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: (v) =>
                          v!.contains('@') ? null : 'Invalid email',
                    ),
                    TextFormField(
                      controller: _passCtl,
                      decoration: InputDecoration(
                        labelText: 'Password',
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
                      validator: (v) => v!.isNotEmpty ? null : 'Required',
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: loading
                          ? null
                          : () {
                              if (_formKey.currentState!.validate()) {
                                context.read<AuthBloc>().add(
                                  LoginRequested(
                                    email: _emailCtl.text.trim(),
                                    password: _passCtl.text.trim(),
                                  ),
                                );
                              }
                            },
                      child: loading
                          ? const CircularProgressIndicator()
                          : const Text('Login'),
                    ),
                    TextButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/register'),
                      child: const Text(
                        'Not registered yet? Register as a Parent',
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/forgot-password'),
                      child: const Text('Forgot Password?'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
