import 'package:flutter/material.dart';
import '../../data/catalog/subject_catalog.dart';
import '../../domain/models/subject_progress_model.dart';
import '../../utils/growth_stage_utils.dart';
import '../../utils/subject_xp_engine.dart';
import 'plant_widget.dart';

/// Plant slot displayed inside the atmospheric garden scene.
/// Transparent background — the garden container provides the soil colour.
/// Plant aligns to the bottom so taller plants (higher levels) appear taller.
class GardenSubjectCard extends StatelessWidget {
  final SubjectDefinition subject;
  final SubjectProgressModel progress;
  final VoidCallback onTap;

  const GardenSubjectCard({
    super.key,
    required this.subject,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final stage = GrowthStageUtils.fromLevel(progress.level);
    final progressFraction = SubjectXpEngine.levelProgress(progress.totalXp);
    final badgeColor = progress.level <= 1
        ? const Color(0xFFFFC107)
        : const Color(0xFF4CAF50);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.max,
        children: [
            // ── Plant + level badge ────────────────────────────────────────
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                // Soft oval ground-shadow under the plant
                Positioned(
                  bottom: 2,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: 70,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.09),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),

                PlantWidget(
                  plantType: subject.plantType,
                  stage: stage,
                  primaryColor: subject.primaryColor,
                  size: 130,
                ),

                // Circular level badge — top-right of plant widget
                Positioned(
                  top: 0,
                  right: 2,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: badgeColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: badgeColor.withValues(alpha: 0.4),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${progress.level}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 5),

            // ── Subject name ───────────────────────────────────────────────
            Text(
              subject.name,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF3D6B2E),
              ),
            ),

            const SizedBox(height: 4),

            // ── XP progress bar ────────────────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progressFraction,
                minHeight: 4,
                backgroundColor: Colors.white.withOpacity(0.5),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
              ),
            ),

            const SizedBox(height: 10),
          ],
        ),
    );
  }
}
