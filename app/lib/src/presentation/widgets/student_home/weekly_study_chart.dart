import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../domain/models/report_models.dart';
import '../../../../l10n/app_localizations.dart';

/// "This week" card — a 7-day study-minutes bar chart, styled to match the
/// parent report's `_DailyStudyPainter` (green rounded bars + value labels).
class WeeklyStudyChart extends StatelessWidget {
  final List<DailyStudyPoint> points;

  const WeeklyStudyChart({super.key, required this.points});

  static const Color _ink = Color(0xFF1F2937);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final total = points.fold<int>(0, (s, e) => s + e.studyMinutes);
    final hasData = points.isNotEmpty && total > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                loc.thisWeekSublabel,
                style: GoogleFonts.cairo(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                ),
              ),
              Text(
                loc.totalSuffixLabel(_formatTotal(total, loc)),
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (!hasData)
            _placeholder(loc)
          else ...[
            SizedBox(
              height: 120,
              child: CustomPaint(
                size: Size.infinite,
                painter: _BarsPainter(points),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: points
                  .map(
                    (p) => Expanded(
                      child: Text(
                        p.dayLabel,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _placeholder(AppLocalizations loc) {
    return SizedBox(
      height: 90,
      child: Center(
        child: Text(
          loc.noStudyTimeWeekMessage,
          style: GoogleFonts.cairo(fontSize: 13, color: Colors.grey.shade500),
        ),
      ),
    );
  }

  String _formatTotal(int minutes, AppLocalizations loc) {
    final h = loc.hourUnitLabel;
    final m = loc.minuteUnitLabel;
    if (minutes <= 0) return '0$m';
    if (minutes < 60) return '$minutes$m';
    final hrs = minutes ~/ 60;
    final rem = minutes % 60;
    return rem > 0 ? '$hrs$h $rem$m' : '$hrs$h';
  }
}

class _BarsPainter extends CustomPainter {
  final List<DailyStudyPoint> data;
  _BarsPainter(this.data);

  static const Color _green = Color(0xFF4CAF50);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final values = data.map((e) => e.studyMinutes).toList();
    final maxVal = values.reduce((a, b) => a > b ? a : b).toDouble();
    final scale = maxVal <= 0 ? 1.0 : maxVal;

    final n = data.length;
    final stepX = size.width / n;
    final barWidth = (stepX * 0.5).clamp(6.0, 26.0);
    const labelGap = 18.0;
    final chartHeight = size.height - labelGap;

    final paint = Paint()
      ..color = _green
      ..style = PaintingStyle.fill;

    for (int i = 0; i < n; i++) {
      final centerX = (i * stepX) + (stepX / 2);
      final h = (values[i] / scale) * (chartHeight - 4);
      final top = size.height - h;
      final rect = Rect.fromLTWH(centerX - barWidth / 2, top, barWidth, h);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(5)),
        paint,
      );

      if (values[i] > 0) {
        final tp = TextPainter(
          text: TextSpan(
            text: _formatMinutes(values[i]),
            style: GoogleFonts.cairo(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF374151),
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(centerX - tp.width / 2, top - tp.height - 2));
      }
    }
  }

  String _formatMinutes(int minutes) {
    if (minutes >= 60) {
      final h = minutes ~/ 60;
      final m = minutes % 60;
      return m == 0 ? '${h}h' : '${h}h ${m}m';
    }
    return '${minutes}m';
  }

  @override
  bool shouldRepaint(_BarsPainter old) => old.data != data;
}