import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../features/mascot/mascot_state.dart';
import '../../../features/mascot/mascot_widget.dart';
import '../../../../l10n/app_localizations.dart';

// ---------------------------------------------------------------------------
// Design-system tokens (mirrored from student_quiz / shop screens)
// ---------------------------------------------------------------------------
const _kGreen = Color(0xFF4CAF50);
const _kInk = Color(0xFF1A1F3C);
const _kMuted = Color(0xFF8B93A7);
const _kAmberLight = Color(0xFFFFF8E1);
const _kAmberDark = Color(0xFFF57F17);
const _kAmberBorder = Color(0xFFFFE082);

/// A celebratory dialog shown when a streak milestone is hit.
class StreakMilestoneModal extends StatefulWidget {
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
      barrierColor: Colors.black.withValues(alpha: 0.60),
      builder: (context) => StreakMilestoneModal(
        milestoneDays: milestoneDays,
        coinReward: coinReward,
        currentStreak: currentStreak,
      ),
    );
  }

  @override
  State<StreakMilestoneModal> createState() => _StreakMilestoneModalState();
}

class _StreakMilestoneModalState extends State<StreakMilestoneModal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
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
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Mascot — static, hardcoded celebration state ─────────
            const MascotWidget(state: MascotState.celebration, size: 160),
            const SizedBox(height: 12),

            // ── Animated flame icon ──────────────────────────────────
            ScaleTransition(
              scale: _scale,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: _kAmberLight,
                  shape: BoxShape.circle,
                ),
                child: const Text('🔥', style: TextStyle(fontSize: 56)),
              ),
            ),
            const SizedBox(height: 20),

            // ── Milestone name ───────────────────────────────────────
            Text(
              _getMilestoneName(loc, widget.milestoneDays),
              style: GoogleFonts.cairo(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: _kInk,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),

            // ── Description ──────────────────────────────────────────
            Text(
              loc.streakMilestoneDescriptionMessage(widget.milestoneDays),
              style: GoogleFonts.cairo(
                fontSize: 15,
                color: _kMuted,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // ── Coin reward pill ─────────────────────────────────────
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: _kAmberLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _kAmberBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🪙', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Text(
                    loc.coinsRewardLabel(widget.coinReward),
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _kAmberDark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── Dismiss button ───────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  loc.awesomeButton,
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
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
