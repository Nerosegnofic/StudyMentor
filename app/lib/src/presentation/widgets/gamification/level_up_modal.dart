import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../domain/models/gamification_models.dart';
import '../../../features/mascot/mascot_state.dart';
import '../../../features/mascot/mascot_widget.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../utils/student_rank_utils.dart';
// ---------------------------------------------------------------------------
// Design-system tokens (mirrored from student_quiz / shop screens)
// ---------------------------------------------------------------------------
const _kBlue = Color(0xFF2196F3);
const _kBlueLight = Color(0xFFE3F2FD);
const _kGold = Color(0xFFFFD54F);
const _kGoldShadow = Color(0xFFFFC107);
const _kDarkGreen = Color(0xFF1B5E20);
const _kMidGreen = Color(0xFF2E7D32);

/// A fullscreen celebration shown when the student levels up.
///
/// Pushed via [Navigator.push] (not showDialog) so it fills the entire screen
/// and gives the level-up moment the weight it deserves.
class LevelUpCelebrationScreen extends StatefulWidget {
  final LevelModel newLevel;

  const LevelUpCelebrationScreen({super.key, required this.newLevel});

  /// Convenience method to push this screen from anywhere.
  static Future<void> show(BuildContext context, LevelModel newLevel) {
    return Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        opaque: false,
        barrierDismissible: false,
        pageBuilder: (_, _, _) =>
            LevelUpCelebrationScreen(newLevel: newLevel),
        transitionsBuilder: (_, anim, _, child) {
          return FadeTransition(opacity: anim, child: child);
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  @override
  State<LevelUpCelebrationScreen> createState() =>
      _LevelUpCelebrationScreenState();
}

class _LevelUpCelebrationScreenState extends State<LevelUpCelebrationScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_kDarkGreen, _kMidGreen, Color(0xFF388E3C)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),

              // ── Mascot — static, hardcoded celebration state ─────────
              const MascotWidget(state: MascotState.celebration, size: 160),
              const SizedBox(height: 12),

              // ── Animated glow ring + level number ────────────────────
              // Isolate the per-frame animation repaint from the rest of the
              // celebration screen.
              RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _ctrl,
                  builder: (_, _) => Transform.scale(
                    scale: 0.5 + 0.5 * _scale.value, // 0.5 → 1.0
                    child: Opacity(
                      opacity: _fade.value,
                      child: _buildGlowRing(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // ── Title ────────────────────────────────────────────────
              FadeTransition(
                opacity: _fade,
                child: Text(
                  AppLocalizations.of(context).levelUpTitle,
                  style: GoogleFonts.cairo(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Level name pill ──────────────────────────────────────
              FadeTransition(
                opacity: _fade,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  decoration: BoxDecoration(
                    color: _kBlueLight.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _kBlue.withValues(alpha: 0.40),
                    ),
                  ),
                  child: Text(
                    StudentRankUtils.localizedRankName(
                      AppLocalizations.of(context),
                      widget.newLevel.levelNumber,
                    ),
                    style: GoogleFonts.cairo(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: _kBlue,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Subtitle ─────────────────────────────────────────────
              FadeTransition(
                opacity: _fade,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    AppLocalizations.of(context).levelUpSubtitleMessage(widget.newLevel.levelNumber),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                      fontSize: 15,
                      color: Colors.white.withValues(alpha: 0.80),
                      height: 1.6,
                    ),
                  ),
                ),
              ),

              const Spacer(flex: 3),

              // ── Dismiss button ───────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 40),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kGold,
                      foregroundColor: _kDarkGreen,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(context).awesomeButton,
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlowRing() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            _kGold.withValues(alpha: 0.55),
            _kGold.withValues(alpha: 0.0),
          ],
        ),
      ),
      child: Center(
        child: Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _kGold,
            boxShadow: [
              BoxShadow(
                color: _kGoldShadow.withValues(alpha: 0.50),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Center(
            child: Text(
              '${widget.newLevel.levelNumber}',
              style: GoogleFonts.cairo(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: _kDarkGreen,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
