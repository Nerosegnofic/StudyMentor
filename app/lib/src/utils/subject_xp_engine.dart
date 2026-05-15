import '../domain/models/quiz_xp_result.dart';

/// XP thresholds for each level boundary.
/// Level N requires [_levelThresholds[N-1]] total XP to reach.
/// Follows a doubling-gap progression: 100, 200, 400, 800, ...
class SubjectXpEngine {
  SubjectXpEngine._();

  /// XP needed to reach each level. Index = level - 1.
  /// Level 1 = 0, Level 2 = 100, Level 3 = 300, Level 4 = 700, ...
  static const List<int> _levelThresholds = [
    0,    // Level 1
    100,  // Level 2
    300,  // Level 3
    700,  // Level 4
    1500, // Level 5
    3100, // Level 6
    6300, // Level 7
    12700,// Level 8
    25500,// Level 9
    51100,// Level 10 (max shown)
  ];

  static const int _maxLevel = 10;
  static const int _baseXpPerQuestion = 10;
  static const int _perfectScoreBonus = 20;
  static const double _maxStreakBonus = 0.5;

  // ── Level calculation ──────────────────────────────────────────────────────

  /// Returns the level for the given total XP (1-based, min 1, max [_maxLevel]).
  static int levelFromXp(int totalXp) {
    int level = 1;
    for (int i = _levelThresholds.length - 1; i >= 0; i--) {
      if (totalXp >= _levelThresholds[i]) {
        level = i + 1;
        break;
      }
    }
    return level.clamp(1, _maxLevel);
  }

  /// Returns the XP threshold for the start of [level].
  static int xpForLevel(int level) {
    final idx = (level - 1).clamp(0, _levelThresholds.length - 1);
    return _levelThresholds[idx];
  }

  /// Returns the XP threshold for the start of the NEXT level.
  /// Returns null if already at max level.
  static int? xpForNextLevel(int level) {
    final nextIdx = level; // level is 1-based; next level idx = level
    if (nextIdx >= _levelThresholds.length) return null;
    return _levelThresholds[nextIdx];
  }

  /// Progress [0.0 – 1.0] within the current level band.
  static double levelProgress(int totalXp) {
    final level = levelFromXp(totalXp);
    final current = xpForLevel(level);
    final next = xpForNextLevel(level);
    if (next == null) return 1.0;
    if (next == current) return 1.0;
    return ((totalXp - current) / (next - current)).clamp(0.0, 1.0);
  }

  /// XP still needed to reach the next level. 0 if at max.
  static int xpToNextLevel(int totalXp) {
    final level = levelFromXp(totalXp);
    final next = xpForNextLevel(level);
    if (next == null) return 0;
    return (next - totalXp).clamp(0, next);
  }

  // ── XP calculation ─────────────────────────────────────────────────────────

  /// Calculates XP earned from a completed quiz result.
  static int calculateXp(QuizXpResult result) {
    final difficultyMultiplier = _difficultyMultiplier(result.difficulty);
    final streakBonus = _streakBonus(result.currentStreak);
    final base = (_baseXpPerQuestion * result.correctAnswers * difficultyMultiplier * (1 + streakBonus)).floor();
    final bonus = result.isPerfect ? _perfectScoreBonus : 0;
    return base + bonus;
  }

  static double _difficultyMultiplier(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'hard': return 2.0;
      case 'medium': return 1.5;
      default: return 1.0;
    }
  }

  static double _streakBonus(int streakDays) {
    return (streakDays * 0.1).clamp(0.0, _maxStreakBonus);
  }

  // ── Label helpers ──────────────────────────────────────────────────────────

  static String levelLabel(int level) => 'Level $level';

  static String xpSummary(int totalXp) {
    final level = levelFromXp(totalXp);
    final next = xpForNextLevel(level);
    if (next == null) return 'Max Level';
    return '${xpToNextLevel(totalXp)} XP to Level ${level + 1}';
  }
}
