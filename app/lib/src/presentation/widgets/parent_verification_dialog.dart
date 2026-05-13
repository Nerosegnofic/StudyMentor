import 'package:flutter/material.dart';

/// A dialog that prompts the student to enter their parent's
/// email and password before allowing logout.
///
/// When [isLoading] is true the form inputs and buttons are disabled,
/// the submit button is replaced with a spinner, and the dialog cannot
/// be dismissed (back gesture or barrier tap) until the operation
/// completes. This keeps the dialog open for the full duration of the
/// verification request so the user always sees feedback in context.
class ParentVerificationDialog extends StatefulWidget {
  final void Function(String email, String password) onSubmit;
  final String? errorMessage;
  final bool isLoading;

  const ParentVerificationDialog({
    super.key,
    required this.onSubmit,
    this.errorMessage,
    this.isLoading = false,
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

  void _submit() {
    if (_formKey.currentState!.validate()) {
      widget.onSubmit(_emailCtl.text.trim(), _passwordCtl.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    // PopScope prevents back-gesture and barrier-tap dismissal while a
    // verification request is in flight, so the loading state is never
    // orphaned and the user cannot get stuck on a blank screen.
    return PopScope(
      canPop: !widget.isLoading,
      child: AlertDialog(
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
                  enabled: !widget.isLoading,
                  decoration: const InputDecoration(
                    labelText: 'Parent\'s Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      (v != null && v.contains('@')) ? null : 'Invalid email',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordCtl,
                  enabled: !widget.isLoading,
                  decoration: InputDecoration(
                    labelText: 'Parent\'s Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      // Keep the toggle reachable for usability, but only
                      // when not loading.
                      onPressed: widget.isLoading
                          ? null
                          : () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                    ),
                  ),
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: widget.isLoading ? null : (_) => _submit(),
                  validator: (v) =>
                      (v != null && v.isNotEmpty) ? null : 'Required',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            // Disabled during loading — the user must wait for the result.
            onPressed: widget.isLoading
                ? null
                : () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: widget.isLoading ? null : _submit,
            child: widget.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      // Use the button's foreground colour so the spinner is
                      // visible against both light and dark button styles.
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Verify & Logout'),
          ),
        ],
      ),
    );
  }
}
