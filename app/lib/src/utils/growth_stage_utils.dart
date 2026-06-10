import 'package:flutter/material.dart';

enum GrowthStage {
  seed,        // mastery  0–20 %
  sprout,      // mastery 20–40 %
  smallPlant,  // mastery 40–60 %
  mediumPlant, // mastery 60–80 %
  fullBloom,   // mastery 80–100 %
}

extension GrowthStageX on GrowthStage {
  String get label {
    switch (this) {
      case GrowthStage.seed:        return 'Seed';
      case GrowthStage.sprout:      return 'Sprout';
      case GrowthStage.smallPlant:  return 'Sapling';
      case GrowthStage.mediumPlant: return 'Growing';
      case GrowthStage.fullBloom:   return 'Flourishing';
    }
  }
}

class GrowthStageUtils {
  GrowthStageUtils._();

  /// Maps mastery percent (0–100) to a [GrowthStage].
  static GrowthStage fromMastery(double masteryPercent) {
    if (masteryPercent >= 80) return GrowthStage.fullBloom;
    if (masteryPercent >= 60) return GrowthStage.mediumPlant;
    if (masteryPercent >= 40) return GrowthStage.smallPlant;
    if (masteryPercent >= 20) return GrowthStage.sprout;
    return GrowthStage.seed;
  }

  /// Health indicator color based on mastery percent (0–100).
  static Color healthColor(double masteryPercent) {
    if (masteryPercent >= 75) return const Color(0xFF34A853); // strong green
    if (masteryPercent >= 50) return const Color(0xFFFBBC05); // medium amber
    return const Color(0xFFEA4335);                           // struggling red
  }
}
