import 'package:flutter/material.dart';
import 'mascot_state.dart';

/// The floating widget rendered inside the system overlay window.
/// It is intentionally self-contained — no BLoC, no BuildContext from the
/// main app tree, because it lives in its own Flutter engine entry-point.
class MascotOverlayWidget extends StatefulWidget {
  /// Current mascot behaviour.
  final MascotState mascotState;

  /// Called when the user taps the mascot bubble.
  final VoidCallback? onTap;

  /// Called when the user taps the close (×) button.
  final VoidCallback? onClose;

  /// When true a placeholder quiz panel is shown below the mascot.
  /// Wire real quiz content here in the future.
  final bool showQuizZone;

  const MascotOverlayWidget({
    super.key,
    this.mascotState = MascotState.idle,
    this.onTap,
    this.onClose,
    this.showQuizZone = false,
  });

  @override
  State<MascotOverlayWidget> createState() => _MascotOverlayWidgetState();
}

class _MascotOverlayWidgetState extends State<MascotOverlayWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounce;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _bounce = Tween<double>(begin: 0, end: -8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ── visual helpers ──────────────────────────────────────────────────────────

  String get _emoji {
    switch (widget.mascotState) {
      case MascotState.wave:
        return '🎉';
      case MascotState.sleep:
        return '😴';
      case MascotState.encourage:
        return '💪';
      case MascotState.idle:
        return '🦉';
    }
  }

  String get _label {
    switch (widget.mascotState) {
      case MascotState.wave:
        return 'Great job!';
      case MascotState.sleep:
        return 'Still there?';
      case MascotState.encourage:
        return 'Keep going!';
      case MascotState.idle:
        return 'Study time!';
    }
  }

  Color get _bubbleColor {
    switch (widget.mascotState) {
      case MascotState.wave:
        return const Color(0xFF4CAF50);
      case MascotState.sleep:
        return const Color(0xFF9E9E9E);
      case MascotState.encourage:
        return const Color(0xFFFF9800);
      case MascotState.idle:
        return const Color(0xFF5C6BC0);
    }
  }

  // ── build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildMascotBubble(),
          if (widget.showQuizZone) ...[
            const SizedBox(height: 8),
            _buildQuizZone(),
          ],
        ],
      ),
    );
  }

  Widget _buildMascotBubble() {
    return AnimatedBuilder(
      animation: _bounce,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _bounce.value),
          child: child,
        );
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Main mascot circle
          GestureDetector(
            onTap: widget.onTap,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _bubbleColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _bubbleColor.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _emoji,
                  style: const TextStyle(fontSize: 30),
                ),
              ),
            ),
          ),
          // Speech-bubble label
          Positioned(
            top: -22,
            left: -20,
            right: -20,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Text(
                  _label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _bubbleColor,
                  ),
                ),
              ),
            ),
          ),
          // Close button
          Positioned(
            top: -6,
            right: -6,
            child: GestureDetector(
              onTap: widget.onClose,
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Placeholder quiz zone — replace the inner content with real quiz widgets
  /// when the quiz feature is ready. The container dimensions and structure
  /// should remain stable so layout does not break.
  Widget _buildQuizZone() {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── QUIZ CONTENT SLOT ───────────────────────────────────────────
          // Replace everything inside this comment block with your real
          // quiz widget (e.g. QuizCard, MultipleChoiceWidget, etc.)
          // The container above provides the card shell.
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE0E0E0),
                style: BorderStyle.solid,
              ),
            ),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.quiz_outlined, color: Color(0xFF9E9E9E), size: 32),
                  SizedBox(height: 8),
                  Text(
                    'Quiz goes here',
                    style: TextStyle(
                      color: Color(0xFF9E9E9E),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // ── END QUIZ CONTENT SLOT ───────────────────────────────────────
        ],
      ),
    );
  }
}
