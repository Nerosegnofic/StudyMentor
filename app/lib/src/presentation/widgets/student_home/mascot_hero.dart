import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../l10n/app_localizations.dart';

/// Hero greeting card: a speech bubble (with the student's RankName-based
/// motivational message) sitting above a reserved 120×120 mascot slot.
///
/// The mascot is an **SVG**, rendered through `flutter_svg` exactly like the
/// garden plants (see plant_widget.dart). Until the art is ready, pass nothing
/// and a neutral placeholder is shown; once the asset exists, pass
/// [mascotAsset] (e.g. `'assets/mascot/mascot.svg'`) — the surrounding layout
/// is unchanged because the slot keeps its 120×120 footprint.
class MascotHero extends StatelessWidget {
  final String firstName;

  /// Current level number (1–10). Drives the motivational message.
  final int level;

  /// Path to the mascot asset. Defaults to idle PNG.
  final String? mascotAsset;

  const MascotHero({
    super.key,
    required this.firstName,
    required this.level,
    this.mascotAsset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          _speechBubble(context),
          // Downward tail pointing at the mascot.
          CustomPaint(
            size: const Size(20, 9),
            painter: _BubbleTailPainter(),
          ),
          const SizedBox(height: 6),
          _mascotSlot(),
        ],
      ),
    );
  }

  Widget _speechBubble(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            loc.mascotHiGreeting(firstName),
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            _motivation(loc, level),
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF4CAF50),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _mascotSlot() {
    final asset = mascotAsset ?? 'assets/mascot/idle.png';
    return SizedBox(
      width: 120,
      height: 120,
      child: Image.asset(
        asset,
        fit: BoxFit.contain,
        alignment: Alignment.bottomCenter,
      ),
    );
  }

  /// Returns a level-specific encouraging message (levels 1–10).
  String _motivation(AppLocalizations loc, int lvl) {
    switch (lvl) {
      case 1:
        return loc.motivationLevel1;
      case 2:
        return loc.motivationLevel2;
      case 3:
        return loc.motivationLevel3;
      case 4:
        return loc.motivationLevel4;
      case 5:
        return loc.motivationLevel5;
      case 6:
        return loc.motivationLevel6;
      case 7:
        return loc.motivationLevel7;
      case 8:
        return loc.motivationLevel8;
      case 9:
        return loc.motivationLevel9;
      case 10:
        return loc.motivationLevel10;
      default:
        return loc.motivationDefault;
    }
  }
}

/// Small downward triangle that joins the speech bubble to the mascot.
class _BubbleTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFE8F5E9);
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_BubbleTailPainter oldDelegate) => false;
}