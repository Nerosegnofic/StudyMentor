import 'package:flutter/material.dart';

/// Visual growth stage of a subject plant, tied to level.
/// Each of the first four levels maps to a distinct visible stage so
/// levels 1–4 always look meaningfully different.
enum GrowthStage {
  seed,        // Level 1
  sprout,      // Level 2
  smallPlant,  // Level 3
  mediumPlant, // Level 4
  fullBloom,   // Level 5+
}

extension GrowthStageX on GrowthStage {
  String get label {
    switch (this) {
      case GrowthStage.seed: return 'Seed';
      case GrowthStage.sprout: return 'Sprout';
      case GrowthStage.smallPlant: return 'Sapling';
      case GrowthStage.mediumPlant: return 'Growing';
      case GrowthStage.fullBloom: return 'Flourishing';
    }
  }
}

/// Utility to compute [GrowthStage] from a subject level.
class GrowthStageUtils {
  GrowthStageUtils._();

  static GrowthStage fromLevel(int level) {
    if (level >= 5) return GrowthStage.fullBloom;
    if (level == 4) return GrowthStage.mediumPlant;
    if (level == 3) return GrowthStage.smallPlant;
    if (level == 2) return GrowthStage.sprout;
    return GrowthStage.seed; // level 0 and 1
  }

  /// Scale factor for the plant widget: [0.3 – 1.0].
  static double scaleFactor(GrowthStage stage) {
    switch (stage) {
      case GrowthStage.seed: return 0.32;
      case GrowthStage.sprout: return 0.52;
      case GrowthStage.smallPlant: return 0.68;
      case GrowthStage.mediumPlant: return 0.84;
      case GrowthStage.fullBloom: return 1.0;
    }
  }

  /// Number of visible "petals" / branches for the plant widget.
  static int complexityFromStage(GrowthStage stage) {
    switch (stage) {
      case GrowthStage.seed: return 0;
      case GrowthStage.sprout: return 1;
      case GrowthStage.smallPlant: return 2;
      case GrowthStage.mediumPlant: return 3;
      case GrowthStage.fullBloom: return 5;
    }
  }

  /// Accent dot/bloom color based on health (mastery percent 0–100).
  static Color healthColor(double masteryPercent) {
    if (masteryPercent >= 75) return const Color(0xFF34A853); // strong green
    if (masteryPercent >= 50) return const Color(0xFFFBBC05); // medium amber
    return const Color(0xFFEA4335); // struggling red
  }
}
