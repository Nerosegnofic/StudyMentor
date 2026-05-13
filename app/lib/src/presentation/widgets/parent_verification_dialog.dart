import 'package:flutter/material.dart';

/// A dialog that prompts the student to enter their parent's
/// email and password before allowing logout.
class ParentVerificationDialog extends StatefulWidget {
  final void Function(String email, String password) onSubmit;
  final String? errorMessage;

  const ParentVerificationDialog({
    super.key,
    required this.onSubmit,
    this.errorMessage,
  });

  @override
  State<ParentVerificationDialog> createState() =>
      _ParentVerificationDialogState();
}

class _ParentVerificationDialogState extends State<ParentVerificationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtl = TextEditingController();
  final _passwordCtl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtl.dispose();
    _passwordCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Parent Verification Required'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'To log out, please enter your parent\'s credentials.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              if (widget.errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.errorMessage!,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _emailCtl,
                decoration: const InputDecoration(
                  labelText: 'Parent\'s Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) =>
                    (v != null && v.contains('@')) ? null : 'Invalid email',
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordCtl,
                decoration: InputDecoration(
                  labelText: 'Parent\'s Password',
                  prefixIcon: const Icon(Icons.lock_outline),
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
                validator: (v) =>
                    (v != null && v.isNotEmpty) ? null : 'Required',
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.onSubmit(_emailCtl.text.trim(), _passwordCtl.text.trim());
            }
          },
          child: const Text('Verify & Logout'),
        ),
      ],
    );
  }
}
