import 'package:flutter/material.dart';
import '../../domain/models/garden_plant_model.dart';
import '../../utils/growth_stage_utils.dart';
import 'plant_widget.dart';

class GardenSubjectCard extends StatelessWidget {
  final GardenPlantModel plant;
  final VoidCallback onTap;

  const GardenSubjectCard({
    super.key,
    required this.plant,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final stage = GrowthStageUtils.fromMastery(plant.masteryPercent);
    final stageNum = GrowthStage.values.indexOf(stage) + 1;
    const badgeColor = Color(0xFF4CAF50);
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // ── Plant + badge + shadow ─────────────────────────────────
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                PlantWidget(stage: stage, size: 110),
                // Stage badge — top-right of plant
                Positioned(
                  top: 0,
                  right: 2,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: badgeColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '$stageNum',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 5),

            // ── Subject name ───────────────────────────────────────────
            Text(
              plant.subjectName,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF3D6B2E),
              ),
            ),

            const SizedBox(height: 4),

            // ── Mastery % ──────────────────────────────────────────────
            Text(
              '${plant.masteryPercent.toStringAsFixed(0)}%',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFF5A8A4A),
              ),
            ),

            const SizedBox(height: 4),

            // ── Within-stage progress bar ──────────────────────────────
            // Each stage spans 20 mastery points (0-20, 20-40, …, 80-100).
            // The bar fills proportionally within the current stage so even
            // small BKT gains are immediately visible.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (plant.masteryPercent % 20) / 20,
                  minHeight: 4,
                  backgroundColor: const Color(0xFFD4ECC8),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF4CAF50),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
