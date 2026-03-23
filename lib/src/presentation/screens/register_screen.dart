import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameCtl = TextEditingController();
  final _emailCtl = TextEditingController();
  final _passCtl = TextEditingController();
  final _confirmCtl = TextEditingController();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Register')),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthLoading) {
            setState(() => _loading = true);
          } else {
            setState(() => _loading = false);
          }

          if (state is AuthEmailUnverified) {
            Navigator.pushReplacementNamed(context, '/confirm-email');
          }
          if (state is AuthError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                TextFormField(
                  controller: _fullNameCtl,
                  decoration: InputDecoration(labelText: 'Full Name'),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: _emailCtl,
                  decoration: InputDecoration(labelText: 'Email'),
                  validator: (v) => v!.contains('@') ? null : 'Invalid email',
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: _passCtl,
                  decoration: InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (v) => v!.length >= 6 ? null : 'Min 6 chars',
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: _confirmCtl,
                  decoration: InputDecoration(labelText: 'Confirm Password'),
                  obscureText: true,
                  validator: (v) =>
                      v == _passCtl.text ? null : 'Passwords do not match',
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loading
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
                  child: _loading
                      ? CircularProgressIndicator()
                      : Text('Register'),
                ),
                TextButton(
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, '/login'),
                  child: Text('Already registered? Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
