import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../data/catalog/subject_catalog.dart';
import '../../utils/growth_stage_utils.dart';

/// Renders a subject plant using SVG assets from assets/plants/.
class PlantWidget extends StatelessWidget {
  final PlantType plantType;
  final GrowthStage stage;
  final Color primaryColor;

  /// Mastery 0–100 drives the health-dot colour.  Null hides the dot.
  final double? masteryPercent;
  final double size;

  const PlantWidget({
    super.key,
    required this.plantType,
    required this.stage,
    required this.primaryColor,
    this.masteryPercent,
    this.size = 100,
  });

  static String _svgAssetForStage(GrowthStage stage, PlantType plantType) {
    switch (stage) {
      case GrowthStage.seed:        return 'assets/plants/plant_stage1.svg';
      case GrowthStage.sprout:      return 'assets/plants/plant_stage2.svg';
      case GrowthStage.smallPlant:  return 'assets/plants/plant_stage3.svg';
      case GrowthStage.mediumPlant: return 'assets/plants/plant_stage4.svg';
      case GrowthStage.fullBloom:   return 'assets/plants/plant_stage5.svg';
    }
  }

  @override
  Widget build(BuildContext context) {
    final healthColor = masteryPercent != null
        ? GrowthStageUtils.healthColor(masteryPercent!)
        : null;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: size * 0.10,
            child: SvgPicture.asset(
              _svgAssetForStage(stage, plantType),
              fit: BoxFit.contain,
              alignment: Alignment.bottomCenter,
            ),
          ),
          if (healthColor != null)
            Positioned(
              right: size * 0.06,
              top:   size * 0.06,
              child: Container(
                width:  size * 0.14,
                height: size * 0.14,
                decoration: BoxDecoration(
                  color: healthColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

