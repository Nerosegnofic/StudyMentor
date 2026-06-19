import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/constants/gamification_levels.dart';
import '../../../../l10n/app_localizations.dart';

/// White card showing progress from the current RankName toward the next one,
/// with the XP bar. Matches the profile/settings card vibe (Material icons,
/// Cairo titles, soft shadow).
class RankProgressCard extends StatelessWidget {
  final int xpTotal;
  final int currentLevel;

  const RankProgressCard({
    super.key,
    required this.xpTotal,
    required this.currentLevel,
  });

  static const Color _green = Color(0xFF4CAF50);
  static const Color _amber = Color(0xFFFFC107);
  static const Color _ink = Color(0xFF1F2937);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final levelIdx =
        (currentLevel - 1).clamp(0, kGamificationLevels.length - 1);
    final currentModel = kGamificationLevels[levelIdx];
    final isMax = levelIdx >= kGamificationLevels.length - 1;
    final nextModel = isMax ? null : kGamificationLevels[levelIdx + 1];

    final lower = currentModel.xpRequired;
    final upper = nextModel?.xpRequired ?? currentModel.xpRequired;
    final progress = (isMax || upper <= lower)
        ? 1.0
        : ((xpTotal - lower) / (upper - lower)).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _amber.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isMax ? Icons.emoji_events_rounded : Icons.auto_awesome_rounded,
                  color: const Color(0xFFFFB300),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentModel.levelName,
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _ink,
                      ),
                    ),
                    Text(
                      isMax ? loc.topRankLabel : loc.nextRankLabel(nextModel!.levelName),
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFFE082)),
                ),
                child: Text(
                  loc.levelShortLabel(currentLevel),
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF8D6E00),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: const Color(0xFFE8F5E9),
              valueColor: const AlwaysStoppedAnimation<Color>(_green),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              isMax ? loc.reachedTopMessage : loc.xpProgressLabel(xpTotal, upper),
              style: GoogleFonts.cairo(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      );
}