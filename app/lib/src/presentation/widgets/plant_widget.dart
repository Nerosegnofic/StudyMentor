import 'package:flutter/material.dart';
import '../../data/catalog/subject_catalog.dart';
import '../../utils/growth_stage_utils.dart';

/// Renders a subject plant using pure Flutter [CustomPaint].
/// Each plant type maps to the exact React SVG reference design.
class PlantWidget extends StatelessWidget {
  final PlantType plantType;
  final GrowthStage stage;
  final Color primaryColor;

  /// Mastery 0–100 drives the health-dot colour.  Null hides the dot.
  final double? masteryPercent;
  final double size;

  const PlantWidget({
    super.key,
    required this.plantType,
    required this.stage,
    required this.primaryColor,
    this.masteryPercent,
    this.size = 100,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _PlantPainter(
          plantType: plantType,
          stage: stage,
          primaryColor: primaryColor,
          complexity: GrowthStageUtils.complexityFromStage(stage),
          scale: GrowthStageUtils.scaleFactor(stage),
          healthColor: masteryPercent != null
              ? GrowthStageUtils.healthColor(masteryPercent!)
              : null,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Painter
// ─────────────────────────────────────────────────────────────────────────────

class _PlantPainter extends CustomPainter {
  final PlantType plantType;
  final GrowthStage stage;
  final Color primaryColor;
  final int complexity;
  final double scale;
  final Color? healthColor;

  static const double _pi = 3.14159265358979;

  // ── React SVG reference colours ───────────────────────────────────────────
  static const Color _stemGreen   = Color(0xFF6DBF5E);
  static const Color _leafLight   = Color(0xFF9ED49A);
  static const Color _leafMid     = Color(0xFF7CC97A);
  static const Color _leafDark    = Color(0xFF4CAF6B);
  static const Color _leafDeep    = Color(0xFF5DBF5E);
  static const Color _budGreen    = Color(0xFF6DBF5E);
  static const Color _budTip      = Color(0xFFA8E0A5);
  static const Color _petalSoft   = Color(0xFFF9A8C9);
  static const Color _petalInner  = Color(0xFFF48FB1);
  static const Color _centerYellow = Color(0xFFFFD54F);
  static const Color _centerHighlight = Color(0xFFFFF9C4);
  // Round tree canopy colours (HistoryTree from Figma)
  static const Color _canopyMid   = Color(0xFF68CA68);
  static const Color _canopyLight = Color(0xFF8DDB8D);

  const _PlantPainter({
    required this.plantType,
    required this.stage,
    required this.primaryColor,
    required this.complexity,
    required this.scale,
    this.healthColor,
  });

  // ── Entry point ──────────────────────────────────────────────────────────

  @override
  void paint(Canvas canvas, Size size) {
    // Seed: draw mound in canvas space (no SVG transform needed)
    if (stage == GrowthStage.seed) {
      _drawSeedMound(canvas, size);
    } else if (plantType == PlantType.flower) {
      _drawFlower(canvas, size);
    } else if (plantType == PlantType.bush) {
      _drawBush(canvas, size);
    } else if (plantType == PlantType.tree) {
      _drawTree(canvas, size);
    } else {
      _drawMagicPlant(canvas, size);
    }

    // Health dot
    if (healthColor != null && stage != GrowthStage.seed) {
      canvas.drawCircle(
        Offset(size.width * 0.78, size.height * 0.16),
        5.0 * scale,
        Paint()..color = healthColor!,
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SVG transform helper
  // Maps an SVG viewport (svgW × svgH) into the Flutter canvas, bottom-aligned
  // and horizontally centred.  The growth-stage [scale] is baked in.
  // All drawing calls inside [draw] use plain SVG coordinates.
  // ─────────────────────────────────────────────────────────────────────────

  void _withSvg(Canvas canvas, Size canvasSize, double svgW, double svgH,
      void Function() draw) {
    final s  = (canvasSize.height / svgH) * scale;
    final dx = (canvasSize.width  - svgW * s) / 2;
    final dy =  canvasSize.height - svgH * s;        // bottom-align
    canvas.save();
    canvas.translate(dx, dy);
    canvas.scale(s);
    draw();
    canvas.restore();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Primitive helpers (work in the already-transformed SVG coordinate space)
  // ─────────────────────────────────────────────────────────────────────────

  /// Draws an oval at (cx, cy) optionally rotated around pivot (px, py).
  /// When pivot == ellipse centre the oval just spins in place.
  void _oval(Canvas canvas, double cx, double cy, double rx, double ry,
      Color color, {double deg = 0, double? px, double? py, double opacity = 1}) {
    final paint = Paint()
      ..color = opacity < 1 ? color.withOpacity(opacity) : color;
    if (deg == 0 && px == null) {
      canvas.drawOval(
          Rect.fromCenter(center: Offset(cx, cy), width: rx * 2, height: ry * 2),
          paint);
      return;
    }
    final pivX = px ?? cx, pivY = py ?? cy;
    canvas.save();
    canvas.translate(pivX, pivY);
    canvas.rotate(deg * _pi / 180);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx - pivX, cy - pivY), width: rx * 2, height: ry * 2),
        paint);
    canvas.restore();
  }

  void _circle(Canvas canvas, double cx, double cy, double r, Color color,
      {double opacity = 1}) {
    canvas.drawCircle(
        Offset(cx, cy),
        r,
        Paint()..color = opacity < 1 ? color.withOpacity(opacity) : color);
  }

  void _stem(Canvas canvas, double x1, double y1, double x2, double y2,
      Color color, double w) {
    canvas.drawLine(
        Offset(x1, y1),
        Offset(x2, y2),
        Paint()
          ..color = color
          ..strokeWidth = w
          ..strokeCap = StrokeCap.round);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // FLOWER  (Science)  –  React SVG viewport 96 × 148
  // ─────────────────────────────────────────────────────────────────────────

  void _drawFlower(Canvas canvas, Size size) {
    _withSvg(canvas, size, 96, 148, () {
      switch (stage) {

        case GrowthStage.sprout: // complexity = 1
          // Small sprout: two angled leaves + closed bud  (same palette as MathSprout)
          _stem(canvas, 48, 148, 48, 90, _stemGreen, 2.4);
          _oval(canvas, 48, 94, 17, 9.5, _leafLight, deg: -38);
          _oval(canvas, 48, 94, 17, 9.5, _leafMid,   deg:  38);
          _oval(canvas, 48, 80, 7.5, 11, _budGreen);
          _oval(canvas, 48, 73,  5,  6.5, _budTip);

        case GrowthStage.smallPlant: // complexity = 2  — closed bud with stem leaves
          _stem(canvas, 48, 148, 48, 56, _stemGreen, 3.5);
          _oval(canvas, 36, 102, 17, 10, _leafLight, deg: -42);
          _oval(canvas, 60,  83, 17, 10, _leafMid,   deg:  42);
          _oval(canvas, 48, 78,  11, 16, _budGreen);
          _oval(canvas, 48, 67,   8,  9, _budTip);

        case GrowthStage.mediumPlant: // complexity = 3  — partly open
          _stem(canvas, 48, 148, 48, 56, _stemGreen, 3.5);
          _oval(canvas, 36, 102, 17, 10, _leafLight, deg: -42);
          _oval(canvas, 60,  83, 17, 10, _leafMid,   deg:  42);
          for (int i = 0; i < 5; i++) {
            _oval(canvas, 48, 28, 9, 13, _petalSoft,
                deg: i * 72.0, px: 48, py: 44, opacity: 0.85);
          }
          _circle(canvas, 48, 44, 12, _centerYellow);

        default: // fullBloom, complexity = 5  — EXACT React ScienceFlower SVG
          // Stem
          _stem(canvas, 48, 148, 48, 56, _stemGreen, 3.5);
          // Two stem leaves
          _oval(canvas, 36, 102, 17, 10, _leafLight, deg: -42);
          _oval(canvas, 60,  83, 17, 10, _leafMid,   deg:  42);
          // 8 outer petals  (rotate around flower centre 48,44)
          for (int i = 0; i < 8; i++) {
            _oval(canvas, 48, 27, 10.5, 17, _petalSoft,
                deg: i * 45.0, px: 48, py: 44);
          }
          // 8 inner petal layer at 22.5° offset for depth
          for (int i = 0; i < 8; i++) {
            _oval(canvas, 48, 30, 7, 12, _petalInner,
                deg: i * 45.0 + 22.5, px: 48, py: 44, opacity: 0.50);
          }
          // Yellow centre disc
          _circle(canvas, 48, 44, 14.5, _centerYellow);
          // Soft highlight
          _circle(canvas, 44, 40, 5, _centerHighlight, opacity: 0.65);
      }
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUSH  (History)  –  React SVG viewport 82 × 112  (HistoryTree from Figma)
  // Round circular canopy on a stem, growing in 4 stages.
  // ─────────────────────────────────────────────────────────────────────────

  void _drawBush(Canvas canvas, Size size) {
    _withSvg(canvas, size, 82, 112, () {
      switch (stage) {

        case GrowthStage.sprout: // tiny round crown
          _stem(canvas, 41, 112, 41, 88, _stemGreen, 2.5);
          _oval(canvas, 41, 78, 13, 12, _leafDark, opacity: 0.45);
          _oval(canvas, 41, 75, 11, 10, _leafDeep);
          _oval(canvas, 41, 74, 9.5, 8.5, _canopyMid);
          _oval(canvas, 35, 66, 5, 4, _canopyLight, opacity: 0.55);

        case GrowthStage.smallPlant: // growing canopy
          _stem(canvas, 41, 112, 41, 82, _stemGreen, 2.8);
          _oval(canvas, 41, 65, 22, 20, _leafDark, opacity: 0.45);
          _oval(canvas, 41, 62, 20, 18, _leafDeep);
          _oval(canvas, 41, 61, 17, 15, _canopyMid);
          _oval(canvas, 34, 52, 8, 7, _canopyLight, opacity: 0.55);

        case GrowthStage.mediumPlant: // EXACT React HistoryTree SVG (82×112)
          _stem(canvas, 41, 112, 41, 78, _stemGreen, 3.0);
          _oval(canvas, 41, 52, 33, 31, _leafDark, opacity: 0.45);
          _oval(canvas, 41, 49, 31, 29, _leafDeep);
          _oval(canvas, 41, 48, 28, 26, _canopyMid);
          _oval(canvas, 33, 37, 12, 10, _canopyLight, opacity: 0.55);

        default: // fullBloom — grander round canopy
          _stem(canvas, 41, 112, 41, 76, _stemGreen, 3.0);
          _oval(canvas, 41, 50, 36, 34, _leafDark, opacity: 0.40);
          _oval(canvas, 41, 47, 33, 31, _leafDeep);
          _oval(canvas, 41, 46, 30, 28, _canopyMid);
          _oval(canvas, 33, 35, 14, 12, _canopyLight, opacity: 0.55);
      }
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TREE  (Math)  –  React SVG viewport 58 × 88
  // ─────────────────────────────────────────────────────────────────────────

  void _drawTree(Canvas canvas, Size size) {
    _withSvg(canvas, size, 58, 88, () {
      switch (stage) {

        case GrowthStage.sprout: // EXACT React MathSprout SVG
          _stem(canvas, 29, 88, 29, 52, _stemGreen, 2.4);
          _oval(canvas, 29, 56, 17, 9.5, _leafLight, deg: -38);
          _oval(canvas, 29, 56, 17, 9.5, _leafMid,   deg:  38);
          _oval(canvas, 29, 45, 7.5, 11, _budGreen);
          _oval(canvas, 29, 40,   5, 6.5, _budTip);

        case GrowthStage.smallPlant: // MathSprout + second leaf pair higher up
          _stem(canvas, 29, 88, 29, 38, _stemGreen, 2.4);
          _oval(canvas, 29, 60, 17, 9.5, _leafLight, deg: -38);
          _oval(canvas, 29, 60, 17, 9.5, _leafMid,   deg:  38);
          _oval(canvas, 29, 47, 14,   8, _leafLight, deg: -42);
          _oval(canvas, 29, 47, 14,   8, _leafMid,   deg:  42);
          _oval(canvas, 29, 36, 7.5, 10, _budGreen);
          _oval(canvas, 29, 30,   5,  6, _budTip);

        case GrowthStage.mediumPlant: // Three leaf tiers + small round crown
          _stem(canvas, 29, 88, 29, 24, _stemGreen, 2.6);
          _oval(canvas, 29, 64, 17, 9.5, _leafLight, deg: -38);
          _oval(canvas, 29, 64, 17, 9.5, _leafMid,   deg:  38);
          _oval(canvas, 29, 50, 15,   9, _leafLight, deg: -40);
          _oval(canvas, 29, 50, 15,   9, _leafMid,   deg:  40);
          _oval(canvas, 29, 36, 14,   8, _leafDark,  deg: -30);
          _oval(canvas, 29, 36, 14,   8, _leafDark,  deg:  30);
          _circle(canvas, 29, 22, 14, _leafDeep);

        default: // fullBloom — rounded tree crown
          // Trunk
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(25.5, 60, 7, 28), const Radius.circular(4)),
            Paint()..color = const Color(0xFF8D6E63));
          // Lower canopy blobs
          _circle(canvas, 15, 44, 16, _leafDeep);
          _circle(canvas, 43, 44, 16, _leafDeep);
          // Mid canopy
          _circle(canvas, 10, 30, 13, _leafDark);
          _circle(canvas, 48, 30, 13, _leafDark);
          // Main canopy
          _circle(canvas, 29, 22, 20, _leafDeep);
          // Top highlight blob
          _circle(canvas, 29, 12, 11, _leafMid);
      }
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MAGIC PLANT  (English)  –  orb on stem, uses subject primaryColor
  // ─────────────────────────────────────────────────────────────────────────

  void _drawMagicPlant(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final groundY = cy + size.height * 0.3;
    final stemH = size.height * 0.40 * scale;

    _stem(canvas, cx, groundY, cx, groundY - stemH,
        primaryColor.withOpacity(0.7), size.width * 0.045 * scale);

    final orbR = size.width * 0.16 * scale;
    canvas.drawCircle(
        Offset(cx, groundY - stemH),
        orbR * 1.4,
        Paint()
          ..color = primaryColor.withOpacity(0.30)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    canvas.drawCircle(
        Offset(cx, groundY - stemH), orbR, Paint()..color = primaryColor);

    if (complexity >= 3) {
      final sp = Paint()..color = Colors.white.withOpacity(0.85);
      for (int i = 0; i < complexity; i++) {
        final a = (i / complexity.toDouble()) * 2 * _pi;
        canvas.drawCircle(
            Offset(cx + orbR * 0.65 * _cos(a),
                groundY - stemH + orbR * 0.65 * _sin(a)),
            2.5 * scale,
            sp);
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Seed mound  (drawn directly in canvas space, no SVG transform)
  // ─────────────────────────────────────────────────────────────────────────

  void _drawSeedMound(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final gy = size.height * 0.80;
    canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, gy),
            width: size.width * 0.30, height: size.height * 0.10),
        Paint()..color = const Color(0xFFA1887F));
    canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, gy - 4),
            width: size.width * 0.11, height: size.height * 0.13),
        Paint()..color = const Color(0xFF6D4C41));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Trig helpers (Bhaskara I approximation — no dart:math)
  // ─────────────────────────────────────────────────────────────────────────

  double _sin(double rad) {
    double r = rad % (2 * _pi);
    if (r < 0) r += 2 * _pi;
    if (r <= _pi) {
      return (4 * r * (_pi - r)) / (_pi * _pi * 1.2732395 - r * (_pi - r));
    }
    r -= _pi;
    return -((4 * r * (_pi - r)) / (_pi * _pi * 1.2732395 - r * (_pi - r)));
  }

  double _cos(double rad) => _sin(rad + _pi / 2);

  @override
  bool shouldRepaint(_PlantPainter old) =>
      old.stage != stage ||
      old.complexity != complexity ||
      old.primaryColor != primaryColor;
}
