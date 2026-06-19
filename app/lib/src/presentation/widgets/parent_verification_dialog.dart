import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../l10n/app_localizations.dart';

// ── Study Mentor design tokens (Student app: gamified & immersive) ────────────
const Color _kGreen = Color(0xFF4CAF50); // Primary Green
const Color _kInk = Color(0xFF1F2937); // Title ink
const Color _kRed = Color(0xFFEF5350); // Destructive (log out)

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
    // Only propagate the error once loading has finished. This prevents the
    // error from flashing in while the spinner is still visible. The check
    // intentionally omits the `!= oldWidget.errorMessage` guard so that
    // consecutive submissions returning the same error string still restore
    // _serverError after onChanged cleared it.
    if (widget.errorMessage != null && !widget.isLoading) {
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
    final loc = AppLocalizations.of(context);
    // PopScope prevents back-gesture and barrier-tap dismissal while a
    // verification request is in flight, so the loading state is never
    // orphaned and the user cannot get stuck on a blank screen.
    return PopScope(
      canPop: !widget.isLoading,
      child: AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
        title: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _kGreen.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shield_outlined,
                color: _kGreen,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              loc.parentVerificationRequiredTitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: _kInk,
              ),
            ),
          ],
        ),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  loc.logoutParentCredentialsMessage,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _emailCtl,
                  enabled: !widget.isLoading,
                  style: GoogleFonts.cairo(fontSize: 14, color: _kInk),
                  decoration: _fieldDecoration(
                    label: loc.parentEmailLabel,
                    icon: Icons.email_outlined,
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      (v != null && v.contains('@')) ? null : loc.loginEmailValidator,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _passwordCtl,
                  enabled: !widget.isLoading,
                  style: GoogleFonts.cairo(fontSize: 14, color: _kInk),
                  // Clear the server error as soon as the user starts
                  // correcting their password, matching the behaviour of
                  // _ParentDeletePasswordDialog and the other dialogs.
                  onChanged: (_) {
                    if (_serverError != null) {
                      setState(() => _serverError = null);
                    }
                  },
                  decoration: _fieldDecoration(
                    label: loc.parentPasswordLabel,
                    icon: Icons.lock_outline,
                    // Inline field-level error shown in red beneath the field.
                    errorText: _serverError,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey.shade500,
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
                      (v != null && v.isNotEmpty) ? null : loc.validatorPasswordRequired,
                ),
              ],
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        actions: [
          TextButton(
            // Disabled during loading — the user must wait for the result.
            onPressed: widget.isLoading
                ? null
                : () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade600,
            ),
            child: Text(
              loc.commonCancel,
              style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
            ),
          ),
          ElevatedButton(
            onPressed: widget.isLoading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: _kRed,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
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
                : Text(
                    loc.verifyAndLogOutButton,
                    style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
                  ),
          ),
        ],
      ),
    );
  }

  // Shared field styling — heavily rounded with a green focus accent (Student).
  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
    String? errorText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.cairo(color: Colors.grey.shade600),
      prefixIcon: Icon(icon, color: Colors.grey.shade500),
      suffixIcon: suffixIcon,
      errorText: errorText,
      errorStyle: GoogleFonts.cairo(),
      filled: true,
      fillColor: const Color(0xFFF5F7FA),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _kGreen, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _kRed),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _kRed, width: 2),
      ),
    );
  }
}
