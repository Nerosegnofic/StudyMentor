import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

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
  final String rankName;

  /// Path to the mascot SVG asset (declare its folder in pubspec `assets:`).
  /// Null until the asset is added — placeholder is shown instead.
  final String? mascotAsset;

  const MascotHero({
    super.key,
    required this.firstName,
    required this.rankName,
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
          _speechBubble(),
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

  Widget _speechBubble() {
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
            'Hi, $firstName! 👋',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            _motivation(rankName),
            textAlign: TextAlign.center,
            style: GoogleFonts.roboto(
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
    // MASCOT_SLOT: the mascot is an SVG (same pipeline as the garden plants).
    // When the asset is ready, supply `mascotAsset` and declare its folder
    // (e.g. `assets/mascot/`) in pubspec.yaml — no layout changes needed here.
    if (mascotAsset != null) {
      return SizedBox(
        width: 120,
        height: 120,
        child: SvgPicture.asset(
          mascotAsset!,
          fit: BoxFit.contain,
          alignment: Alignment.bottomCenter,
        ),
      );
    }
    return Container(
      width: 120,
      height: 120,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Color(0xFFE8F5E9),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.emoji_nature_rounded,
        size: 60,
        color: const Color(0xFF4CAF50).withValues(alpha: 0.55),
      ),
    );
  }

  /// Picks a friendly line that always includes the RankName, varying by tier.
  String _motivation(String rank) {
    const early = {'Seedling', 'Sprout', 'Explorer'};
    const mid = {'Curious Mind', 'Scholar', 'Achiever'};
    if (early.contains(rank)) {
      return "You're a $rank — great start! 🌱";
    }
    if (mid.contains(rank)) {
      return "You're a $rank — keep it up! ⭐";
    }
    return 'Amazing work, $rank! 🌟';
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