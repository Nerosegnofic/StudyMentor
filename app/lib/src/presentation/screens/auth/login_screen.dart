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
  bool _loading = false;
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) SystemNavigator.pop();
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Login')),
        body: BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthLoading) {
              setState(() => _loading = true);
            } else {
              setState(() => _loading = false);
            }
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
              _passCtl.clear();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
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
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (v) => v!.contains('@') ? null : 'Invalid email',
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
                    onPressed: _loading
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
                    child: _loading
                        ? const CircularProgressIndicator()
                        : const Text('Login'),
                  ),
                  TextButton(
                    onPressed: () =>
                        Navigator.pushReplacementNamed(context, '/register'),
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
          ),
        ),
      ),
    );
  }
}
