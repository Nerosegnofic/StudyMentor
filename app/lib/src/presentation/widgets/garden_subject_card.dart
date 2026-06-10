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
                Positioned(
                  bottom: 2,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: 60,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
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
                          color: Colors.black.withOpacity(0.25),
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

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
