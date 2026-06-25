import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'mascot_state.dart';
import 'mascot_widget.dart';

/// Loading state laid out as a cohesive, vertically-centered stack:
/// mascot on top, a prominent spinner, then the message caption directly
/// beneath it — keeping the loading indicator and its label together rather
/// than the understated corner-badge spinner of [MascotWithBubble].
class MascotLoadingView extends StatelessWidget {
  final String message;

  const MascotLoadingView({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MascotWidget(state: MascotState.thinking, size: 100),
          const SizedBox(height: 20),
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: Color(0xFF4CAF50), // Primary Green (design system)
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}