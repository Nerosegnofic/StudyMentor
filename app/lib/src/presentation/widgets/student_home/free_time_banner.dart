import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Amber reward banner showing the free app-time the student has earned so far
/// today — the cumulative monitored-app usage across all cooldown windows
/// (see MascotOverlayService.dailyFreeTimeSeconds). Always in minutes.
///
/// The wording adapts to the student's current state:
///   • free   — apps are unlocked; just enjoy the time (studying now earns
///              nothing extra, so we don't prompt for it).
///   • locked — apps are resting (cooldown); finishing the quiz unlocks more.
///
/// No progress bar: the current usage window is already shown by the
/// screen-time ring above; this banner is the day's running reward total.
class FreeTimeBanner extends StatelessWidget {
  final int earnedSeconds;

  /// True while apps are in cooldown (MascotOverlayService.isBlocked).
  final bool isLocked;

  const FreeTimeBanner({
    super.key,
    required this.earnedSeconds,
    required this.isLocked,
  });

  static const Color _amber = Color(0xFFFFC107);
  static const Color _amberInk = Color(0xFF8D6E00);

  @override
  Widget build(BuildContext context) {
    final earned = earnedSeconds < 0 ? 0 : earnedSeconds;
    final hasEarned = earned >= 60;
    final formatted = _formatMinutes(earned);

    final String headline;
    final String subtitle;
    if (isLocked) {
      headline = 'Apps are resting right now';
      subtitle = hasEarned
          ? "You've earned $formatted of free time today. Finish your quiz to unlock more."
          : 'Finish your quiz to unlock your apps.';
    } else if (hasEarned) {
      headline = "You've earned $formatted of free time today";
      subtitle = 'Your apps are unlocked — enjoy your free time.';
    } else {
      headline = 'Your apps are unlocked';
      subtitle = 'Enjoy your free time.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFE082)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _amber.withValues(alpha: 0.20),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isLocked
                  ? Icons.bedtime_rounded
                  : Icons.card_giftcard_rounded,
              color: const Color(0xFFF57F17),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  headline,
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _amberInk,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    color: _amberInk.withValues(alpha: 0.75),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Whole-minute formatting: 0 → "0 min", 65*60 → "1h 5m".
  String _formatMinutes(int seconds) {
    final m = seconds ~/ 60;
    if (m <= 0) return '0 min';
    if (m < 60) return '$m min';
    final h = m ~/ 60;
    final rem = m % 60;
    return rem > 0 ? '${h}h ${rem}m' : '${h}h';
  }
}
