import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Study Mentor shared auth style (pre-role brand: Primary Green) ────────────
//
// Login / Register / Forgot Password / Confirm Email are shown before the app
// knows whether the user is a parent or a student, so they share one neutral
// brand treatment built on the Primary Green ("Growth") hero color.
const Color kAuthBackground = Color(0xFFF5F7FA); // Soft Cloud
const Color kAuthGreen = Color(0xFF4CAF50); // Primary Green
const Color kAuthGreenDark = Color(0xFF43A047); // gradient top
const Color kAuthInk = Color(0xFF1F2937); // title ink
const Color kAuthRed = Color(0xFFEF5350); // error / destructive

/// Flat green brand header with a logo badge + "Study Mentor" wordmark.
///
/// When the keyboard opens it collapses with a "slide & shrink" animation: the
/// logo glides from center-top to the left, the wordmark scales down and slides
/// beside it, and the subtitle fades out — freeing space for the form.
/// [onBack] adds a white back button (omit on screens that block back).
class AuthHeader extends StatelessWidget {
  final String? subtitle;
  final VoidCallback? onBack;
  final IconData logo;

  /// Whether the keyboard is open (header collapses). Callers must compute this
  /// from a context ABOVE the Scaffold — a Scaffold zeroes `viewInsets.bottom`
  /// for its body subtree, so reading it inside `AuthHeader` would never detect
  /// the keyboard. When null, falls back to the local MediaQuery.
  final bool? keyboardOpen;

  const AuthHeader({
    super.key,
    this.subtitle,
    this.onBack,
    this.logo = Icons.school_rounded,
    this.keyboardOpen,
  });

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    final collapsed =
        keyboardOpen ?? (MediaQuery.of(context).viewInsets.bottom > 0);

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
      tween: Tween<double>(begin: 0, end: collapsed ? 1 : 0),
      builder: (context, t, _) {
        final logoSize = _lerp(72, 40, t);
        final stackHeight = _lerp(150, 44, t);

        return Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(
            24,
            topInset + _lerp(16, 8, t),
            24,
            _lerp(28, 10, t),
          ),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [kAuthGreenDark, kAuthGreen],
            ),
          ),
          child: Stack(
            children: [
              // Logo/title block — identical layout whether or not there's a
              // back arrow, so all auth headers look the same.
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: _lerp(12, 4, t)),
                  SizedBox(
                    height: stackHeight,
                    child: Stack(
                  children: [
                    // Logo badge — center-top → center-left.
                    Align(
                      alignment: Alignment.lerp(
                        Alignment.topCenter,
                        Alignment.centerLeft,
                        t,
                      )!,
                      child: Container(
                        width: logoSize,
                        height: logoSize,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          logo,
                          color: kAuthGreen,
                          size: _lerp(38, 22, t),
                        ),
                      ),
                    ),
                    // Wordmark — stays horizontally centered; moves up to the
                    // band center when collapsed and grows slightly.
                    Align(
                      alignment: Alignment.lerp(
                        const Alignment(0, 0.6),
                        Alignment.center,
                        t,
                      )!,
                      child: Text(
                        'Study Mentor',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(
                          fontSize: _lerp(24, 22, t),
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    // Subtitle — fades + collapses out when the keyboard opens.
                    if (subtitle != null)
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Opacity(
                          opacity: (1 - t * 1.6).clamp(0.0, 1.0),
                          child: Text(
                            subtitle!,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.roboto(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
                ],
              ),
              // Floating back arrow — overlays the top-left corner with no
              // layout impact, so the logo/title stay centered like login.
              // Fades out while the header is collapsed (keyboard open).
              if (onBack != null)
                Positioned(
                  top: 0,
                  left: 0,
                  child: IgnorePointer(
                    ignoring: t > 0.5,
                    child: AnimatedOpacity(
                      opacity: collapsed ? 0.0 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                        color: Colors.white,
                        onPressed: onBack,
                        tooltip: 'Back',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Inline error banner shown above an auth form. Animates in/out; renders
/// nothing when [message] is null.
Widget authErrorBanner(String? message) {
  return AnimatedSize(
    duration: const Duration(milliseconds: 250),
    curve: Curves.easeInOut,
    alignment: Alignment.topCenter,
    child: message == null
        ? const SizedBox(width: double.infinity)
        : Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: kAuthRed.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kAuthRed.withValues(alpha: 0.5)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.error_outline, color: kAuthRed, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: GoogleFonts.roboto(
                      fontSize: 13,
                      height: 1.4,
                      color: const Color(0xFFB71C1C),
                    ),
                  ),
                ),
              ],
            ),
          ),
  );
}

/// Shared text-field decoration: soft fill, rounded 14, green focus border.
InputDecoration authInputDecoration({
  required String label,
  required IconData icon,
  String? hintText,
  String? errorText,
  Widget? suffixIcon,
}) {
  OutlineInputBorder border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: width),
      );

  return InputDecoration(
    labelText: label,
    hintText: hintText,
    labelStyle: GoogleFonts.roboto(color: Colors.grey.shade600),
    hintStyle: GoogleFonts.roboto(color: Colors.grey.shade400),
    errorText: errorText,
    errorStyle: GoogleFonts.roboto(),
    prefixIcon: Icon(icon, color: Colors.grey.shade500),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: kAuthBackground,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    enabledBorder: border(Colors.grey.shade200),
    focusedBorder: border(kAuthGreen, 2),
    errorBorder: border(kAuthRed),
    focusedErrorBorder: border(kAuthRed, 2),
  );
}

/// Full-width green primary button with a loading spinner variant.
Widget authPrimaryButton({
  required String label,
  required VoidCallback? onPressed,
  bool loading = false,
}) {
  return SizedBox(
    width: double.infinity,
    height: 54,
    child: ElevatedButton(
      onPressed: loading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: kAuthGreen,
        foregroundColor: Colors.white,
        disabledBackgroundColor: kAuthGreen.withValues(alpha: 0.6),
        disabledForegroundColor: Colors.white,
        elevation: 2,
        shadowColor: kAuthGreen.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: loading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
    ),
  );
}

/// Full-width outlined secondary button (green border + text).
Widget authSecondaryButton({
  required String label,
  required VoidCallback? onPressed,
}) {
  return SizedBox(
    width: double.infinity,
    height: 54,
    child: OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: kAuthGreen,
        side: const BorderSide(color: kAuthGreen, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
  );
}

/// Centered green text link.
Widget authTextLink({
  required String text,
  required VoidCallback? onPressed,
  Color? color,
}) {
  return TextButton(
    onPressed: onPressed,
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: GoogleFonts.roboto(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: color ?? kAuthGreen,
      ),
    ),
  );
}
