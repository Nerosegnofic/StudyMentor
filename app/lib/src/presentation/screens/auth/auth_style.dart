import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../l10n/app_localizations.dart';

// ── StudyMentor shared auth style (pre-role brand: Primary Green) ────────────
//
// Login / Register / Forgot Password / Confirm Email are shown before the app
// knows whether the user is a parent or a student, so they share one neutral
// brand treatment built on the Primary Green ("Growth") hero color.
const Color kAuthBackground = Color(0xFFF5F7FA); // Soft Cloud
const Color kAuthGreen = Color(0xFF4CAF50); // Primary Green
const Color kAuthGreenDark = Color(0xFF43A047); // gradient top
const Color kAuthInk = Color(0xFF1F2937); // title ink
const Color kAuthRed = Color(0xFFEF5350); // error / destructive

/// Flat green brand header with a logo badge + "StudyMentor" wordmark.
///
/// When the keyboard opens it collapses with a "slide & shrink" animation: the
/// logo glides from center-top to the left, the wordmark scales down and slides
/// beside it, and the subtitle fades out — freeing space for the form.
/// [onBack] adds a white back button (omit on screens that block back).
class AuthHeader extends StatefulWidget {
  final String? subtitle;
  final VoidCallback? onBack;
  final IconData logo;

  /// Mascot image asset path shown in the logo circle. Defaults to idle.
  /// Pass a different path (e.g. sad) for screens like forgot password.
  final String mascotAsset;

  /// Optional explicit keyboard-open override. Normally left null: the header
  /// detects the keyboard itself via the raw view inset (see [_AuthHeaderState]),
  /// so callers no longer read `MediaQuery.viewInsets` above the Scaffold — that
  /// read used to rebuild the entire screen on every keyboard-animation frame,
  /// which is what made the collapse feel laggy.
  final bool? keyboardOpen;

  const AuthHeader({
    super.key,
    this.subtitle,
    this.onBack,
    this.logo = Icons.school_rounded,
    this.mascotAsset = 'assets/mascot/idle.png',
    this.keyboardOpen,
  });

  @override
  State<AuthHeader> createState() => _AuthHeaderState();
}

class _AuthHeaderState extends State<AuthHeader> with WidgetsBindingObserver {
  // Flipped ONCE when the keyboard opens/closes (not per animation frame), so
  // only the header re-runs its collapse animation — the rest of the screen
  // never rebuilds for the keyboard.
  final ValueNotifier<bool> _keyboardOpen = ValueNotifier<bool>(false);

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncKeyboard());
  }

  @override
  void didChangeMetrics() => _syncKeyboard();

  void _syncKeyboard() {
    if (!mounted) return;
    // Raw view inset — NOT the Scaffold-zeroed MediaQuery — so it detects the
    // keyboard even though this widget lives inside the Scaffold body.
    _keyboardOpen.value = View.of(context).viewInsets.bottom > 0;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _keyboardOpen.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final explicit = widget.keyboardOpen;
    if (explicit != null) return _buildHeader(context, explicit);
    return ValueListenableBuilder<bool>(
      valueListenable: _keyboardOpen,
      builder: (context, collapsed, _) => _buildHeader(context, collapsed),
    );
  }

  Widget _buildHeader(BuildContext context, bool collapsed) {
    // paddingOf (not MediaQuery.of) so the header does NOT depend on viewInsets
    // and therefore does not rebuild on every keyboard-animation frame.
    final topInset = MediaQuery.paddingOf(context).top;

    // Hoisted once per build so they aren't recreated on every animation frame.
    final loc = AppLocalizations.of(context);
    final String title = loc.appTitle;
    final String? backTooltip = widget.onBack != null ? loc.backTooltip : null;
    final TextStyle wordmarkBase = GoogleFonts.cairo(
      fontWeight: FontWeight.w800,
      color: Colors.white,
    );
    final TextStyle subtitleStyle = GoogleFonts.cairo(
      fontSize: 14,
      color: Colors.white.withValues(alpha: 0.9),
    );
    // Decoded once and passed via the builder's `child` so the bitmap isn't
    // rebuilt/re-decoded each frame — only its enclosing box is resized.
    final Widget mascot = Image.asset(
      widget.mascotAsset,
      width: 72 * 1.3,
      height: 72 * 1.3,
      cacheWidth: 240,
      fit: BoxFit.contain,
    );

    return RepaintBoundary(
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
        tween: Tween<double>(begin: 0, end: collapsed ? 1 : 0),
        child: mascot,
        builder: (context, t, mascotChild) {
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
                            child: SizedBox(
                              width: logoSize * 1.3,
                              height: logoSize * 1.3,
                              child: FittedBox(
                                fit: BoxFit.contain,
                                child: mascotChild,
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
                              title,
                              textAlign: TextAlign.center,
                              style: wordmarkBase.copyWith(
                                fontSize: _lerp(24, 22, t),
                              ),
                            ),
                          ),
                          // Subtitle — fades + collapses out when the keyboard opens.
                          if (widget.subtitle != null)
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: Opacity(
                                opacity: (1 - t * 1.6).clamp(0.0, 1.0),
                                child: Text(
                                  widget.subtitle!,
                                  textAlign: TextAlign.center,
                                  style: subtitleStyle,
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
                if (widget.onBack != null)
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
                          onPressed: widget.onBack,
                          tooltip: backTooltip,
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
      ),
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
                    style: GoogleFonts.cairo(
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
    labelStyle: GoogleFonts.cairo(color: Colors.grey.shade600),
    hintStyle: GoogleFonts.cairo(color: Colors.grey.shade400),
    errorText: errorText,
    errorStyle: GoogleFonts.cairo(),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
      style: GoogleFonts.cairo(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: color ?? kAuthGreen,
      ),
    ),
  );
}
