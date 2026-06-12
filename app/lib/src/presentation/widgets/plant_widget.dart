import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../utils/growth_stage_utils.dart';

class PlantWidget extends StatelessWidget {
  final GrowthStage stage;
  final double size;

  const PlantWidget({
    super.key,
    required this.stage,
    this.size = 100,
  });

  static String _svgAssetForStage(GrowthStage stage) {
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
              _svgAssetForStage(stage),
              fit: BoxFit.contain,
              alignment: Alignment.bottomCenter,
            ),
          ),
        ],
      ),
    );
  }
}
