import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../domain/models/app_config_model.dart';
import '../../../services/overlay/mascot_overlay_service.dart';
import '../../../../l10n/app_localizations.dart';

/// Circular ring showing the student's reward time state.
///
/// Three modes:
///   • **Earned** — green→amber→red ring depletes as reward time is used.
///     Centre shows remaining minutes/seconds.
///   • **Cooldown** — amber ring fills as the cooldown elapses.
///     Centre shows bedtime icon + mm:ss countdown.
///   • **No time** — grey ring (0 earned, not in cooldown).
///     Centre prompts the student to complete a quiz.
///
/// The parent screen rebuilds every second (via its Timer), which drives
/// the live countdown animations.
class ScreenTimeRing extends StatelessWidget {
  final StudentConfigModel config;

  const ScreenTimeRing({super.key, required this.config});

  static const Color _green = Color(0xFF4CAF50);
  static const Color _amber = Color(0xFFFFC107);
  static const Color _red = Color(0xFFEF5350);
  static const Color _grey = Color(0xFFE2E8F0);
  static const Color _ink = Color(0xFF1F2937);

  @override
  Widget build(BuildContext context) {
    final svc = MascotOverlayService.instance;
    final loc = AppLocalizations.of(context);

    final perQuizSecs = config.rewardPerQuizSeconds;
    final cooldownTotal = config.cooldownSeconds;

    final int earned = svc.earnedRewardSeconds;
    // Use the service getter which correctly ignores stale usage during cooldown.
    final int remaining = svc.remainingRewardSeconds.clamp(0, earned == 0 ? 0 : earned);

    // ── No earned time (initial, post-cooldown with no quiz, or no quizzes yet) ─
    if (earned <= 0) {
      return _shell(
        child: Column(
          children: [
            _title(loc.screenTimeTitle),
            const SizedBox(height: 16),
            _ring(
              fraction: 0.0,
              color: _grey,
              center: _noTimeCenter(loc),
            ),
            const SizedBox(height: 16),
            _footer(loc, perQuizSecs, cooldownTotal),
          ],
        ),
      );
    }

    // ── Active / banked: show reward time (depleting when in use, static when banked) ──
    final fraction = ((earned - remaining) / earned).clamp(0.0, 1.0);
    final color = fraction < 0.6 ? _green : (fraction < 0.85 ? _amber : _red);

    return _shell(
      child: Column(
        children: [
          _title(loc.screenTimeTitle),
          const SizedBox(height: 16),
          _ring(
            fraction: fraction,
            color: color,
            center: _usageCenter(loc, remaining, color),
          ),
          const SizedBox(height: 16),
          _footer(loc, perQuizSecs, cooldownTotal),
        ],
      ),
    );
  }

  // ── Centre widgets ─────────────────────────────────────────────────────────

  Widget _usageCenter(AppLocalizations loc, int remaining, Color color) {
    final String big;
    final String small;
    if (remaining >= 60) {
      big = '${(remaining / 60).ceil()}';
      small = loc.minLeftLabel;
    } else {
      big = '$remaining';
      small = loc.secLeftLabel;
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          big,
          style: GoogleFonts.cairo(
            fontSize: 34,
            fontWeight: FontWeight.w800,
            color: color,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          small,
          style: GoogleFonts.cairo(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  Widget _noTimeCenter(AppLocalizations loc) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.quiz_rounded, color: Colors.grey.shade400, size: 28),
        const SizedBox(height: 6),
        Text(
          loc.doQuizNowLabel,
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade500,
            height: 1.2,
          ),
        ),
      ],
    );
  }

  // ── Layout helpers ─────────────────────────────────────────────────────────

  Widget _title(String text) => Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: _ink,
          ),
        ),
      );

  Widget _ring({
    required double fraction,
    required Color color,
    required Widget center,
  }) =>
      SizedBox(
        width: 150,
        height: 150,
        child: CustomPaint(
          painter: _RingPainter(fraction: fraction, color: color),
          child: Center(child: center),
        ),
      );

  Widget _footer(AppLocalizations loc, int perQuizSecs, int cooldownSecs) =>
      Text(
        loc.limitRestSummaryLabel(
          _dur(perQuizSecs ~/ 3600, (perQuizSecs % 3600) ~/ 60, loc),
          _dur(cooldownSecs ~/ 3600, (cooldownSecs % 3600) ~/ 60, loc),
        ),
        style: GoogleFonts.cairo(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: Colors.grey.shade500,
        ),
      );

  Widget _shell({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
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
        child: child,
      );

  // ── Formatting ─────────────────────────────────────────────────────────────

  String _dur(int hours, int minutes, AppLocalizations loc) {
    final h = loc.hourUnitLabel;
    final m = loc.minuteUnitLabel;
    if (hours == 0 && minutes == 0) return '0$m';
    if (hours == 0) return '$minutes$m';
    if (minutes == 0) return '$hours$h';
    return '$hours$h $minutes$m';
  }
}

class _RingPainter extends CustomPainter {
  final double fraction;
  final Color color;

  _RingPainter({required this.fraction, required this.color});

  static const Color _track = Color(0xFFE2E8F0);

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 12.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - stroke) / 2;

    final trackPaint = Paint()
      ..color = _track
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    if (fraction > 0) {
      final progressPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * fraction.clamp(0.0, 1.0),
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.fraction != fraction || old.color != color;
}
