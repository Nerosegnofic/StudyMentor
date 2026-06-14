import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/students/students_bloc.dart';
import '../../../bloc/students/students_event.dart';
import '../../../bloc/students/students_state.dart';
import '../../../domain/models/app_config_model.dart';

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

  void _submit(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;
    context.read<StudentsBloc>().add(
      CreateStudentRequested(
        fullName: _fullNameCtl.text.trim(),
        username: _usernameCtl.text.trim(),
        email: _emailCtl.text.trim(),
        password: _passCtl.text.trim(),
        parentUid: widget.parentUid,
        gradeLevel: _selectedGrade!,
        rules: const [],
        config: const StudentConfigModel(usageHours: 0, usageMinutes: 0),
      ),
    );
  }

  // ── build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocListener<StudentsBloc, StudentsState>(
      listener: (context, state) {
        if (state is StudentCreated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Student Registered Successfully!',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'On your child\'s phone, open the app and log in with the credentials you just created. They\'ll need to verify their email before getting started.',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
              backgroundColor: Color(0xFF34A853),
              duration: Duration(seconds: 10),
            ),
          );
          Navigator.pop(context);
        }
        if (state is StudentCreateError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
      },
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          appBar: AppBar(
            backgroundColor: const Color(0xFF2196F3),
            elevation: 4,
            shadowColor: Colors.black.withValues(alpha: 0.15),
            surfaceTintColor: Colors.transparent,
            iconTheme: const IconThemeData(color: Colors.white),
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Register Student',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Create a new student account',
                  style: TextStyle(fontSize: 12, color: Colors.white),
                ),
              ],
            ),
          ),
          body: BlocBuilder<StudentsBloc, StudentsState>(
            buildWhen: (prev, curr) =>
                curr is StudentCreateLoading || prev is StudentCreateLoading,
            builder: (context, state) {
              final loading = state is StudentCreateLoading;
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Card 1: Student Information
                      _buildCard(
                        title: 'Student Information',
                        children: [
                          _buildField(
                            label: 'Full Name',
                            child: TextFormField(
                              controller: _fullNameCtl,
                              textCapitalization: TextCapitalization.words,
                              style: const TextStyle(
                                  color: Color(0xFF1E293B), fontSize: 15),
                              decoration: _inputDecoration(
                                  label: 'Full Name', icon: Icons.person_outline),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Full name is required.';
                                }
                                if (v.trim().length < 2) {
                                  return 'Name must be at least 2 characters.';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildField(
                            label: 'Username',
                            hint: 'Shown on the leaderboard (e.g. coolkid42)',
                            child: TextFormField(
                              controller: _usernameCtl,
                              autocorrect: false,
                              enableSuggestions: false,
                              style: const TextStyle(
                                  color: Color(0xFF1E293B), fontSize: 15),
                              decoration: _inputDecoration(
                                  label: 'Username',
                                  icon: Icons.alternate_email_rounded),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Username is required.';
                                }
                                if (v.trim().length < 3) {
                                  return 'At least 3 characters.';
                                }
                                if (v.trim().length > 50) {
                                  return 'Max 50 characters.';
                                }
                                if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v.trim())) {
                                  return 'Only letters, numbers and underscores.';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildField(
                            label: 'Grade',
                            child: DropdownButtonFormField<int>(
                              value: _selectedGrade,
                              style: const TextStyle(
                                  color: Color(0xFF1E293B), fontSize: 15),
                              decoration: _inputDecoration(
                                  label: 'Grade', icon: Icons.school_outlined),
                              items: _gradeOptions
                                  .map(
                                    (g) => DropdownMenuItem<int>(
                                      value: g['value'] as int,
                                      child: Text(g['label'] as String),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) =>
                                  setState(() => _selectedGrade = value),
                              validator: (v) =>
                                  v == null ? 'Please select a grade.' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Card 2: Account Credentials
                      _buildCard(
                        title: 'Account Credentials',
                        children: [
                          _buildField(
                            label: 'Email Address',
                            hint: 'The student will use this to log in.',
                            child: TextFormField(
                              controller: _emailCtl,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(
                                  color: Color(0xFF1E293B), fontSize: 15),
                              decoration: _inputDecoration(
                                  label: 'Email Address',
                                  icon: Icons.email_outlined),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Email is required.';
                                }
                                final emailRegex =
                                    RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                                if (!emailRegex.hasMatch(v.trim())) {
                                  return 'Enter a valid email address.';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildField(
                            label: 'Password',
                            child: TextFormField(
                              controller: _passCtl,
                              obscureText: _obscurePassword,
                              style: const TextStyle(
                                  color: Color(0xFF1E293B), fontSize: 15),
                              decoration: _inputDecoration(
                                label: 'Password',
                                icon: Icons.lock_outline,
                              ).copyWith(
                                suffixIcon: _visibilityToggle(
                                  obscure: _obscurePassword,
                                  onToggle: () => setState(
                                      () => _obscurePassword = !_obscurePassword),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Password is required.';
                                }
                                if (v.length < 6) {
                                  return 'Password must be at least 6 characters.';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildField(
                            label: 'Confirm Password',
                            child: TextFormField(
                              controller: _confirmCtl,
                              obscureText: _obscureConfirm,
                              style: const TextStyle(
                                  color: Color(0xFF1E293B), fontSize: 15),
                              decoration: _inputDecoration(
                                label: 'Confirm Password',
                                icon: Icons.lock_reset_outlined,
                              ).copyWith(
                                suffixIcon: _visibilityToggle(
                                  obscure: _obscureConfirm,
                                  onToggle: () => setState(
                                      () => _obscureConfirm = !_obscureConfirm),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Please confirm your password.';
                                }
                                if (v != _passCtl.text) {
                                  return 'Passwords do not match.';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: loading ? null : () => _submit(context),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: const StadiumBorder(),
                            backgroundColor: const Color(0xFF2196F3),
                            disabledBackgroundColor: const Color(0xFFE2E8F0),
                            foregroundColor: Colors.white,
                            disabledForegroundColor: const Color(0xFF94A3B8),
                            elevation: 0,
                          ),
                          child: loading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5, color: Colors.white),
                                )
                              : const Text(
                                  'Register Student',
                                  style: TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ── helpers ─────────────────────────────────────────────────────────────────

  Widget _buildCard({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildField({
    required String label,
    String? hint,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (hint != null) ...[
          const SizedBox(height: 2),
          Text(
            hint,
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
          ),
        ],
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: const Color(0xFF64748B)),
      filled: true,
      fillColor: WidgetStateColor.resolveWith((states) {
        if (states.contains(WidgetState.focused)) return Colors.white;
        if (states.contains(WidgetState.disabled)) return const Color(0xFFF1F5F9);
        return const Color(0xFFF8FAFC);
      }),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2196F3)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade400),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade600, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _visibilityToggle({
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return IconButton(
      icon: Icon(
        obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        color: const Color(0xFF64748B),
      ),
      onPressed: onToggle,
    );
  }
}
