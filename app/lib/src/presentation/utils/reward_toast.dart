import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Design-system tokens (mirrored from student_quiz.dart).
const _kGreen = Color(0xFF2E7D32);

/// Utility for showing non-blocking reward notifications.
class RewardToast {
  RewardToast._();

  /// Shows a brief floating SnackBar announcing the XP and Coins just earned.
  static void show(BuildContext context, int xp, int coins) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text(
                '+$xp XP',
                style: GoogleFonts.roboto(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 14),
              const Text('🪙', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 4),
              Text(
                '+$coins Coins',
                style: GoogleFonts.roboto(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _kGreen,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          duration: const Duration(seconds: 3),
          elevation: 6,
        ),
      );
  }
}
