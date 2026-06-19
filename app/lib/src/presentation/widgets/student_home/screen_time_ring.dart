import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../domain/models/app_config_model.dart';
import '../../../services/overlay/mascot_overlay_service.dart';
import '../../../../l10n/app_localizations.dart';

/// A single circular "time ring" that unifies screen-time and cooldown.
///
/// • Normal — fills green→amber→red as monitored-app usage approaches the
///   limit; center shows remaining time (minutes).
/// • Cooldown (`MascotOverlayService.isBlocked`) — amber ring fills as the
///   rest period elapses; center shows a bedtime icon + mm:ss countdown.
///
/// Reads live values from [MascotOverlayService]; the parent screen already
/// rebuilds every second, which animates the countdown.
class ScreenTimeRing extends StatelessWidget {
  final StudentConfigModel config;

  const ScreenTimeRing({super.key, required this.config});

  static const Color _green = Color(0xFF4CAF50);
  static const Color _amber = Color(0xFFFFC107);
  static const Color _red = Color(0xFFEF5350);
  static const Color _ink = Color(0xFF1F2937);

  @override
  Widget build(BuildContext context) {
    final svc = MascotOverlayService.instance;
    final usageLimit = (config.usageHours * 3600) + (config.usageMinutes * 60);
    final cooldownTotal =
        (config.cooldownHours * 3600) + (config.cooldownMinutes * 60);

    final loc = AppLocalizations.of(context);

    if (usageLimit <= 0) {
      return _shell(child: _noLimit(loc));
    }

    final bool resting = svc.isBlocked;
    final double fraction;
    final Color color;
    final String title;

    if (resting) {
      final remaining = svc.remainingSeconds.clamp(0, 1 << 31);
      fraction = cooldownTotal > 0
          ? ((cooldownTotal - remaining) / cooldownTotal).clamp(0.0, 1.0)
          : 0.0;
      color = _amber;
      title = loc.timeToRestTitle;
    } else {
      final used = svc.totalUsageSeconds.clamp(0, usageLimit);
      fraction = (used / usageLimit).clamp(0.0, 1.0);
      color = fraction < 0.6 ? _green : (fraction < 0.85 ? _amber : _red);
      title = loc.screenTimeTitle;
    }

    return _shell(
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: _ink,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 150,
            height: 150,
            child: CustomPaint(
              painter: _RingPainter(fraction: fraction, color: color),
              child: Center(
                child: resting
                    ? _restingCenter(loc, svc.remainingSeconds, color)
                    : _usageCenter(loc, usageLimit, svc.totalUsageSeconds, color),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            loc.limitRestSummaryLabel(
              _dur(config.usageHours, config.usageMinutes),
              _dur(config.cooldownHours, config.cooldownMinutes),
            ),
            style: GoogleFonts.cairo(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _usageCenter(AppLocalizations loc, int limit, int used, Color color) {
    final remaining = (limit - used).clamp(0, limit);
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

  Widget _restingCenter(AppLocalizations loc, int remainingSeconds, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.bedtime_rounded, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          _mmss(remainingSeconds),
          style: GoogleFonts.cairo(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: color,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          loc.restingLabel,
          style: GoogleFonts.cairo(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  Widget _shell({required Widget child}) {
    return Container(
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
  }

  Widget _noLimit(AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.screenTimeTitle,
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: _ink,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _green.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.all_inclusive_rounded,
                  color: _green, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                loc.noTimeLimitMessage,
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _mmss(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _dur(int hours, int minutes) {
    if (hours == 0 && minutes == 0) return '0m';
    if (hours == 0) return '${minutes}m';
    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes}m';
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