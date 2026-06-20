import 'package:studymentor/src/data/constants/gamification_levels.dart';
import '../../l10n/app_localizations.dart';

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

  static String localizedRankName(AppLocalizations loc, int level) {
    switch (level) {
      case 1: return loc.rankLevel1;
      case 2: return loc.rankLevel2;
      case 3: return loc.rankLevel3;
      case 4: return loc.rankLevel4;
      case 5: return loc.rankLevel5;
      case 6: return loc.rankLevel6;
      case 7: return loc.rankLevel7;
      case 8: return loc.rankLevel8;
      case 9: return loc.rankLevel9;
      default: return loc.rankLevel10;
    }
  }

  /// Online = lastActiveAt within the last [thresholdMinutes] minutes.
  static bool isOnline(DateTime? lastActiveAt, {int thresholdMinutes = 5}) {
    if (lastActiveAt == null) return false;
    return DateTime.now().toUtc().difference(lastActiveAt.toUtc()).inMinutes < thresholdMinutes;
  }
}
