// lib/src/data/constants/gamification_levels.dart

import 'package:studymentor/src/domain/models/gamification_models.dart';

/// The 10 progression levels with their XP thresholds.
/// Ordered by levelNumber; XP thresholds follow the v1 Plan.
const List<LevelModel> kGamificationLevels = [
  LevelModel(levelNumber: 1,  levelName: 'Seedling',     xpRequired: 0),
  LevelModel(levelNumber: 2,  levelName: 'Sprout',        xpRequired: 150),
  LevelModel(levelNumber: 3,  levelName: 'Explorer',      xpRequired: 350),
  LevelModel(levelNumber: 4,  levelName: 'Curious Mind',  xpRequired: 650),
  LevelModel(levelNumber: 5,  levelName: 'Scholar',       xpRequired: 1050),
  LevelModel(levelNumber: 6,  levelName: 'Achiever',      xpRequired: 1600),
  LevelModel(levelNumber: 7,  levelName: 'Champion',      xpRequired: 2300),
  LevelModel(levelNumber: 8,  levelName: 'Sage',          xpRequired: 3200),
  LevelModel(levelNumber: 9,  levelName: 'Luminary',      xpRequired: 4500),
  LevelModel(levelNumber: 10, levelName: 'Master',        xpRequired: 6000),
];

/// Returns the [LevelModel] for a given XP total.
/// Walks the list in reverse to find the highest level the student qualifies for.
LevelModel levelForXp(int xp) {
  for (int i = kGamificationLevels.length - 1; i >= 0; i--) {
    if (xp >= kGamificationLevels[i].xpRequired) {
      return kGamificationLevels[i];
    }
  }
  return kGamificationLevels.first;
}
