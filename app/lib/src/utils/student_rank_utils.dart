/// Shared utilities for computing a student's level and rank from XP.
/// Used by both StudentProfile and StudentLeaderboard.
class StudentRankUtils {
  StudentRankUtils._();

  // 500 XP per level
  static int levelFromXp(int totalXp) => (totalXp ~/ 500) + 1;

  // One title per level (index = level - 1); beyond the list → 'Legend'
  static const List<String> _ranks = [
    'Seedling',          // L1
    'Sprout',            // L2
    'Explorer',          // L3
    'Curious Learner',   // L4
    'Scholar',           // L5
    'Achiever',          // L6
    'Problem Solver',    // L7
    'Thinker',           // L8
    'Brain Booster',     // L9
    'Smart Cookie',      // L10
    'Rising Star',       // L11
    'Knowledge Seeker',  // L12
    'Study Champion',    // L13
    'Plant Expert',      // L14
    'Master Gardener',   // L15
    'Elite Scholar',     // L16
    'Wisdom Keeper',     // L17
    'Grand Scholar',     // L18
    'Super Brain',       // L19
    'Grand Master',      // L20
    'Legend',            // L21+
  ];

  static String rankFromLevel(int level) {
    if (level < 1) return _ranks[0];
    if (level >= _ranks.length) return 'Legend';
    return _ranks[level - 1];
  }

  static String rankFromXp(int totalXp) => rankFromLevel(levelFromXp(totalXp));

  /// Online = lastActiveAt within the last [thresholdMinutes] minutes.
  static bool isOnline(DateTime? lastActiveAt, {int thresholdMinutes = 5}) {
    if (lastActiveAt == null) return false;
    return DateTime.now().toUtc().difference(lastActiveAt.toUtc()).inMinutes < thresholdMinutes;
  }
}
