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

  // Mirrors widget.errorMessage into local state so the error can be cleared
  // immediately when the user starts retyping, matching the behaviour of the
  // other password-confirmation dialogs in the app.
  String? _serverError;

  @override
  void didUpdateWidget(ParentVerificationDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Propagate a new incoming error into local state.
    if (widget.errorMessage != oldWidget.errorMessage &&
        widget.errorMessage != null) {
      setState(() => _serverError = widget.errorMessage);
    }
  }

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
                  // Clear the server error as soon as the user starts
                  // correcting their password, matching the behaviour of
                  // _ParentDeletePasswordDialog and the other dialogs.
                  onChanged: (_) {
                    if (_serverError != null) {
                      setState(() => _serverError = null);
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'Parent\'s Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    // Inline field-level error shown in red beneath the field.
                    errorText: _serverError,
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
