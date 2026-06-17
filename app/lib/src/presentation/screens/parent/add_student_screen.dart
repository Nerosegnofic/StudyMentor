import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../bloc/students/students_bloc.dart';
import '../../../bloc/students/students_event.dart';
import '../../../bloc/students/students_state.dart';
import '../../../domain/models/app_config_model.dart';
import '../../../../l10n/app_localizations.dart';

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

  static const List<int> _gradeOptions = [1, 2, 3, 4, 5, 6];

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
    final loc = AppLocalizations.of(context);
    return BlocListener<StudentsBloc, StudentsState>(
      listener: (context, state) {
        if (state is StudentCreated) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.studentRegisteredSuccessTitle,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    loc.studentRegisteredSuccessDetail,
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF34A853),
              duration: const Duration(seconds: 10),
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
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.registerStudentTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  loc.createNewStudentAccountSubtitle,
                  style: const TextStyle(fontSize: 12, color: Colors.white),
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
                        title: loc.studentInformationSection,
                        children: [
                          _buildField(
                            label: loc.fieldFullName,
                            child: TextFormField(
                              controller: _fullNameCtl,
                              textCapitalization: TextCapitalization.words,
                              style: const TextStyle(
                                  color: Color(0xFF1E293B), fontSize: 15),
                              decoration: _inputDecoration(
                                  label: loc.fieldFullName, icon: Icons.person_outline),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return loc.validatorFullNameRequired;
                                }
                                if (v.trim().length < 2) {
                                  return loc.validatorFullNameMinLength;
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildField(
                            label: loc.fieldUsername,
                            hint: loc.usernameHint,
                            child: TextFormField(
                              controller: _usernameCtl,
                              autocorrect: false,
                              enableSuggestions: false,
                              style: const TextStyle(
                                  color: Color(0xFF1E293B), fontSize: 15),
                              decoration: _inputDecoration(
                                  label: loc.fieldUsername,
                                  icon: Icons.alternate_email_rounded),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return loc.validatorUsernameRequired;
                                }
                                if (v.trim().length < 3) {
                                  return loc.validatorUsernameMinLength;
                                }
                                if (v.trim().length > 50) {
                                  return loc.validatorUsernameMaxLength;
                                }
                                if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v.trim())) {
                                  return loc.validatorUsernameFormat;
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildField(
                            label: loc.fieldGrade,
                            child: DropdownButtonFormField<int>(
                              value: _selectedGrade,
                              style: GoogleFonts.cairo(
                                  color: const Color(0xFF1E293B), fontSize: 15),
                              decoration: _inputDecoration(
                                  label: loc.fieldGrade, icon: Icons.school_outlined),
                              items: _gradeOptions
                                  .map(
                                    (g) => DropdownMenuItem<int>(
                                      value: g,
                                      child: Text(loc.gradeLabel(g)),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) =>
                                  setState(() => _selectedGrade = value),
                              validator: (v) =>
                                  v == null ? loc.validatorGradeRequired : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Card 2: Account Credentials
                      _buildCard(
                        title: loc.accountCredentialsSection,
                        children: [
                          _buildField(
                            label: loc.fieldEmailAddress,
                            hint: loc.emailAddressHint,
                            child: TextFormField(
                              controller: _emailCtl,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(
                                  color: Color(0xFF1E293B), fontSize: 15),
                              decoration: _inputDecoration(
                                  label: loc.fieldEmailAddress,
                                  icon: Icons.email_outlined),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return loc.validatorEmailRequired;
                                }
                                final emailRegex =
                                    RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                                if (!emailRegex.hasMatch(v.trim())) {
                                  return loc.validatorEmailInvalid;
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildField(
                            label: loc.fieldPassword,
                            child: TextFormField(
                              controller: _passCtl,
                              obscureText: _obscurePassword,
                              style: const TextStyle(
                                  color: Color(0xFF1E293B), fontSize: 15),
                              decoration: _inputDecoration(
                                label: loc.fieldPassword,
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
                                  return loc.validatorPasswordRequired;
                                }
                                if (v.length < 6) {
                                  return loc.validatorPasswordMinLength;
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildField(
                            label: loc.fieldConfirmPassword,
                            child: TextFormField(
                              controller: _confirmCtl,
                              obscureText: _obscureConfirm,
                              style: const TextStyle(
                                  color: Color(0xFF1E293B), fontSize: 15),
                              decoration: _inputDecoration(
                                label: loc.fieldConfirmPassword,
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
                                  return loc.validatorConfirmPasswordRequired;
                                }
                                if (v != _passCtl.text) {
                                  return loc.validatorPasswordsDoNotMatch;
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
                              : Text(
                                  loc.registerStudentTitle,
                                  style: const TextStyle(
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
