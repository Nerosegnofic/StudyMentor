import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../l10n/app_localizations.dart';

/// Banner showing the student's current reward time status.
///
/// Three states:
///   • **No time, not in cooldown** — apps are blocked; prompt to do a quiz.
///   • **In cooldown** — apps locked; show banked time (if any) or prompt.
///   • **Unlocked, has time** — show remaining time and encourage more quizzes.
class FreeTimeBanner extends StatelessWidget {
  /// Cumulative reward time earned from forced quizzes so far today. Drives the
  /// headline ("You've earned X today"). Resets at local midnight.
  final int dailyEarnedSeconds;

  /// Seconds currently earned and available (earned − used so far in window).
  /// Used only to distinguish a banked vs not-yet-solved cooldown — never shown
  /// as a number, since the ScreenTimeRing above already displays it.
  final int remainingSeconds;

  /// How many seconds one quiz completion grants (from parent config).
  final int perQuizRewardSeconds;

  /// True while in cooldown mode.
  final bool isInCooldown;

  /// True when apps are blocked for any reason (cooldown OR no earned time).
  final bool isLocked;

  /// Whether the parent has configured a cooldown duration > 0.
  /// When false, cooldown-specific messaging is suppressed even if
  /// [isInCooldown] is momentarily true.
  final bool cooldownConfigured;

  const FreeTimeBanner({
    super.key,
    required this.dailyEarnedSeconds,
    required this.remainingSeconds,
    required this.perQuizRewardSeconds,
    required this.isInCooldown,
    required this.isLocked,
    this.cooldownConfigured = true,
  });

  static const Color _amber = Color(0xFFFFC107);
  static const Color _amberInk = Color(0xFF8D6E00);
  static const Color _green = Color(0xFF4CAF50);
  static const Color _greenInk = Color(0xFF1B5E20);
  static const Color _greenBg = Color(0xFFF1F8E9);
  static const Color _greenBorder = Color(0xFFA5D6A7);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final rewardFormatted = _formatTime(perQuizRewardSeconds, loc);
    final dailyFormatted = _formatTime(dailyEarnedSeconds, loc);

    // Headline carries the cumulative daily total whenever the student has earned
    // anything today; it only falls back to a prompt at the day's first quiz.
    final bool hasEarnedToday = dailyEarnedSeconds > 0;
    final String earnedTodayHeadline = loc.earnedTodayTitle(dailyFormatted);

    final String headline;
    final String subtitle;
    final IconData icon;
    final Color iconColor;
    final Color iconBg;
    final Color bgColor;
    final Color borderColor;
    final Color inkColor;

    if (isInCooldown && cooldownConfigured) {
      // Cooldown running. The ScreenTimeRing shows the countdown; the banner just
      // states today's total and whether a quiz still needs solving to unlock.
      bgColor = const Color(0xFFFFF8E1);
      borderColor = const Color(0xFFFFE082);
      inkColor = _amberInk;
      icon = Icons.bedtime_rounded;
      iconColor = const Color(0xFFF57F17);
      iconBg = _amber.withValues(alpha: 0.20);

      headline = hasEarnedToday ? earnedTodayHeadline : loc.appsRestingTitle;
      // remainingSeconds > 0 means the unlock quiz is already solved (reward
      // banked); otherwise the student still needs to finish one.
      subtitle = remainingSeconds > 0
          ? loc.appsRestingUnlockSubtitle
          : loc.appsRestingFinishQuizSubtitle;
    } else if (isLocked) {
      // No earned time, not in cooldown — initial state or post-cooldown.
      bgColor = const Color(0xFFFFF8E1);
      borderColor = const Color(0xFFFFE082);
      inkColor = _amberInk;
      icon = Icons.quiz_rounded;
      iconColor = const Color(0xFFF57F17);
      iconBg = _amber.withValues(alpha: 0.20);

      headline = hasEarnedToday ? earnedTodayHeadline : loc.doQuizToUnlockTitle;
      subtitle = loc.perQuizRewardSubtitle(rewardFormatted);
    } else {
      // Unlocked: apps accessible. The ring shows remaining time; the banner
      // headlines today's total and encourages earning more.
      bgColor = _greenBg;
      borderColor = _greenBorder;
      inkColor = _greenInk;
      icon = Icons.card_giftcard_rounded;
      iconColor = _green;
      iconBg = _green.withValues(alpha: 0.15);

      headline = hasEarnedToday ? earnedTodayHeadline : loc.appsUnlockedTitle;
      subtitle = loc.enjoyFreeTimeSubtitle;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 20),
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
                    color: inkColor,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: inkColor.withValues(alpha: 0.75),
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

  String _formatTime(int seconds, AppLocalizations loc) {
    final min = loc.minuteUnitLabel;
    final hr = loc.hourUnitLabel;
    final m = seconds ~/ 60;
    if (m <= 0) return '0 $min';
    if (m < 60) return '$m $min';
    final h = m ~/ 60;
    final rem = m % 60;
    return rem > 0 ? '$h$hr $rem$min' : '$h$hr';
  }
}
