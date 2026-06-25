import 'package:studymentor/src/data/constants/gamification_levels.dart';
import '../../l10n/app_localizations.dart';

/// Shared utilities for computing a student's level and rank from XP.
/// Used by both StudentProfile and StudentLeaderboard.
class StudentRankUtils {
  StudentRankUtils._();

  static int levelFromXp(int totalXp) => levelForXp(totalXp).levelNumber;

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

}
