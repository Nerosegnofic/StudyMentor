import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/catalog/subject_metadata_registry.dart';
import '../../../domain/models/report_models.dart';

/// A segmented donut of today's answered questions, one colored arc per
/// subject, with the total in the center and a small legend below.
class QuestionsRing extends StatelessWidget {
  final List<SubjectQuestionCount> segments;

  const QuestionsRing({super.key, required this.segments});

  static const Color _ink = Color(0xFF1F2937);
  static const Color _general = Color(0xFF90A4AE); // blue-grey for "General"

  Color _subjectColor(String name) {
    final key = name.toLowerCase().trim();
    if (key == 'general') return _general;
    final normalized = key == 'mathematics' ? 'math' : key;
    return SubjectMetadataRegistry.getDefinition(normalized).primaryColor;
  }

  @override
  Widget build(BuildContext context) {
    final active =
        segments.where((s) => s.questions > 0).toList(growable: false);
    final total = active.fold<int>(0, (sum, e) => sum + e.questions);

    final arcs = total == 0
        ? const <_RingArc>[]
        : active
            .map((s) => _RingArc(s.questions / total, _subjectColor(s.subjectName)))
            .toList(growable: false);

    return Column(
      children: [
        SizedBox(
          width: 150,
          height: 150,
          child: CustomPaint(
            painter: _DonutPainter(arcs),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$total',
                    style: GoogleFonts.cairo(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'questions today',
                    style: GoogleFonts.roboto(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (total == 0)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              'No questions yet today — let\'s start! 🌱',
              style: GoogleFonts.roboto(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade500,
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 14,
              runSpacing: 8,
              children: active.map(_legendItem).toList(),
            ),
          ),
      ],
    );
  }

  Widget _legendItem(SubjectQuestionCount s) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: _subjectColor(s.subjectName),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '${s.subjectName}  ${s.questions}',
          style: GoogleFonts.roboto(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF374151),
          ),
        ),
      ],
    );
  }
}

class _RingArc {
  final double fraction;
  final Color color;
  const _RingArc(this.fraction, this.color);
}

class _DonutPainter extends CustomPainter {
  final List<_RingArc> arcs;
  _DonutPainter(this.arcs);

  static const Color _track = Color(0xFFE2E8F0);

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 14.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = _track
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    if (arcs.isEmpty) return;

    final gap = arcs.length > 1 ? 0.07 : 0.0;
    final available = (2 * math.pi) - (gap * arcs.length);
    double start = -math.pi / 2 + gap / 2;

    for (final arc in arcs) {
      final sweep = available * arc.fraction;
      final paint = Paint()
        ..color = arc.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, start, sweep, false, paint);
      start += sweep + gap;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.arcs != arcs;
}