import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/auth/auth_bloc.dart';
import '../../../bloc/auth/auth_event.dart';
import '../../../bloc/auth/auth_state.dart';

class AddStudentScreen extends StatefulWidget {
  final String parentUid;
  const AddStudentScreen({super.key, required this.parentUid});

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameCtl = TextEditingController();
  final _usernameCtl = TextEditingController();
  final _emailCtl = TextEditingController();
  final _passCtl = TextEditingController();
  final _confirmCtl = TextEditingController();
  int? _selectedGrade;
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  static const List<Map<String, dynamic>> _gradeOptions = [
    {'label': 'Grade 1', 'value': 1},
    {'label': 'Grade 2', 'value': 2},
    {'label': 'Grade 3', 'value': 3},
    {'label': 'Grade 4', 'value': 4},
    {'label': 'Grade 5', 'value': 5},
    {'label': 'Grade 6', 'value': 6},
  ];

  @override
  void dispose() {
    _fullNameCtl.dispose();
    _usernameCtl.dispose();
    _emailCtl.dispose();
    _passCtl.dispose();
    _confirmCtl.dispose();
    super.dispose();
  }

  void _showSuccessAndPop() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🎉 Student Registered Successfully!',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            SizedBox(height: 6),
            Text(
              'On your child\'s phone, open the app and log in with the credentials you just created. They\'ll need to verify their email before getting started.',
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
        duration: Duration(seconds: 10),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthLoading) {
          setState(() => _loading = true);
        } else {
          setState(() => _loading = false);
        }
        if (state is StudentCreated) {
          _showSuccessAndPop();
        }
        if (state is AuthError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Register Your Child')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                TextFormField(
                  controller: _fullNameCtl,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                  ), // ── CHANGED
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _usernameCtl,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    hintText: 'Shown on leaderboard (e.g. coolkid42)',
                  ),
                  autocorrect: false,
                  enableSuggestions: false,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    if (v.trim().length < 3) return 'At least 3 characters';
                    if (v.trim().length > 50) return 'Max 50 characters';
                    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v.trim())) {
                      return 'Only letters, numbers and underscores';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  initialValue: _selectedGrade,
                  decoration: const InputDecoration(labelText: 'Grade'),
                  items: _gradeOptions
                      .map(
                        (g) => DropdownMenuItem<int>(
                          value: g['value'] as int,
                          child: Text(g['label'] as String),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _selectedGrade = value),
                  validator: (v) => v == null ? 'Please select a grade' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailCtl,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (v) => v!.contains('@') ? null : 'Invalid email',
                ),
                const SizedBox(height: 8),
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
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  obscureText: _obscurePassword,
                  validator: (v) => v!.length >= 6 ? null : 'Min 6 characters',
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _confirmCtl,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
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
                  validator: (v) =>
                      v == _passCtl.text ? null : 'Passwords do not match',
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loading
                      ? null
                      : () {
                          if (_formKey.currentState!.validate()) {
                            context.read<AuthBloc>().add(
                              CreateStudentRequested(
                                fullName: _fullNameCtl.text.trim(),
                                username: _usernameCtl.text.trim(),
                                email: _emailCtl.text.trim(),
                                password: _passCtl.text.trim(),
                                parentUid: widget.parentUid,
                                gradeLevel: _selectedGrade!,
                              ),
                            );
                          }
                        },
                  child: _loading
                      ? const CircularProgressIndicator()
                      : const Text('Register Student'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
