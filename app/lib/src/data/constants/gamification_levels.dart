// lib/src/data/constants/gamification_levels.dart

import 'package:studymentor/src/domain/models/gamification_models.dart';

/// The 10 progression levels with their XP thresholds.
/// Ordered by levelNumber; XP thresholds follow the v1 Plan.
const List<LevelModel> kGamificationLevels = [
  LevelModel(levelNumber: 1,  xpRequired: 0),
  LevelModel(levelNumber: 2,  xpRequired: 150),
  LevelModel(levelNumber: 3,  xpRequired: 350),
  LevelModel(levelNumber: 4,  xpRequired: 650),
  LevelModel(levelNumber: 5,  xpRequired: 1050),
  LevelModel(levelNumber: 6,  xpRequired: 1600),
  LevelModel(levelNumber: 7,  xpRequired: 2300),
  LevelModel(levelNumber: 8,  xpRequired: 3200),
  LevelModel(levelNumber: 9,  xpRequired: 4500),
  LevelModel(levelNumber: 10, xpRequired: 6000),
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
