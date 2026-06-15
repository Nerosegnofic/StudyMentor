import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../l10n/app_localizations.dart';

/// A full-screen modal or dialog to show when a streak milestone is hit.
class StreakMilestoneModal extends StatelessWidget {
  final int milestoneDays;
  final int coinReward;
  final int currentStreak;

  const StreakMilestoneModal({
    super.key,
    required this.milestoneDays,
    required this.coinReward,
    required this.currentStreak,
  });

  static Future<void> show(
    BuildContext context, {
    required int milestoneDays,
    required int coinReward,
    required int currentStreak,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StreakMilestoneModal(
        milestoneDays: milestoneDays,
        coinReward: coinReward,
        currentStreak: currentStreak,
      ),
    );
  }

  String _getMilestoneName(AppLocalizations loc, int days) {
    switch (days) {
      case 3:
        return loc.streakMilestoneOnARoll;
      case 7:
        return loc.streakMilestoneWeekWarrior;
      case 14:
        return loc.streakMilestoneFortnightFocus;
      case 30:
        return loc.streakMilestoneMonthlyMaster;
      default:
        return loc.streakMilestoneGeneric;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Flame Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                shape: BoxShape.circle,
              ),
              child: const Text('🔥', style: TextStyle(fontSize: 64)),
            ),
            const SizedBox(height: 24),

            // Milestone Name
            Text(
              _getMilestoneName(loc, milestoneDays),
              style: GoogleFonts.cairo(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F2937),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              loc.streakMilestoneDescriptionMessage(milestoneDays),
              style: GoogleFonts.cairo(
                fontSize: 16,
                color: const Color(0xFF6B7280),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Reward
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🪙', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Text(
                    loc.coinsRewardLabel(coinReward),
                    style: GoogleFonts.cairo(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFD97706),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Dismiss Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  loc.awesomeButton,
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
