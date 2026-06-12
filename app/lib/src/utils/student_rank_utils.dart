import 'package:studymentor/src/data/constants/gamification_levels.dart';

/// Shared utilities for computing a student's level and rank from XP.
/// Used by both StudentProfile and StudentLeaderboard.
class StudentRankUtils {
  StudentRankUtils._();

  static int levelFromXp(int totalXp) => levelForXp(totalXp).levelNumber;

  static String rankFromLevel(int level) {
    if (level < 1) return 'Seedling';
    if (level > kGamificationLevels.length) return 'Legend';
    return kGamificationLevels[level - 1].levelName;
  }

  static String rankFromXp(int totalXp) => rankFromLevel(levelFromXp(totalXp));

  /// Online = lastActiveAt within the last [thresholdMinutes] minutes.
  static bool isOnline(DateTime? lastActiveAt, {int thresholdMinutes = 5}) {
    if (lastActiveAt == null) return false;
    return DateTime.now().toUtc().difference(lastActiveAt.toUtc()).inMinutes < thresholdMinutes;
  }
}
