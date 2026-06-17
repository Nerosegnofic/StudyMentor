// lib/src/domain/models/gamification_models.dart

/// Represents a single level definition in the progression system.
class LevelModel {
  final int levelNumber;
  final String levelName;
  final int xpRequired;

  const LevelModel({
    required this.levelNumber,
    required this.levelName,
    required this.xpRequired,
  });
}

/// Aggregated gamification state for a single student.
class StudentGamificationModel {
  final String studentId;
  final int xpTotal;
  final int coinsTotal;
  final int currentLevel;
  final int currentStreak;
  final int longestStreak;
  final String? lastQuizDate;
  final int? nextMilestone;
  final int? nextMilestoneDaysAway;

  const StudentGamificationModel({
    required this.studentId,
    this.xpTotal = 0,
    this.coinsTotal = 0,
    this.currentLevel = 1,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastQuizDate,
    this.nextMilestone,
    this.nextMilestoneDaysAway,
  });

  StudentGamificationModel copyWith({
    String? studentId,
    int? xpTotal,
    int? coinsTotal,
    int? currentLevel,
    int? currentStreak,
    int? longestStreak,
    String? lastQuizDate,
    int? nextMilestone,
    int? nextMilestoneDaysAway,
  }) {
    return StudentGamificationModel(
      studentId: studentId ?? this.studentId,
      xpTotal: xpTotal ?? this.xpTotal,
      coinsTotal: coinsTotal ?? this.coinsTotal,
      currentLevel: currentLevel ?? this.currentLevel,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastQuizDate: lastQuizDate ?? this.lastQuizDate,
      nextMilestone: nextMilestone ?? this.nextMilestone,
      nextMilestoneDaysAway: nextMilestoneDaysAway ?? this.nextMilestoneDaysAway,
    );
  }

  factory StudentGamificationModel.fromJson(Map<String, dynamic> json) {
    return StudentGamificationModel(
      studentId: json['student_uid'] as String? ?? json['student_id'] as String? ?? '',
      xpTotal: json['xp_total'] as int? ?? 0,
      coinsTotal: json['coins_total'] as int? ?? 0,
      currentLevel: json['current_level'] as int? ?? 1,
      currentStreak: json['current_streak'] as int? ?? 0,
      longestStreak: json['longest_streak'] as int? ?? 0,
      lastQuizDate: json['last_quiz_date'] as String?,
      nextMilestone: json['next_milestone'] as int?,
      nextMilestoneDaysAway: json['next_milestone_days_away'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'student_uid': studentId,
      'xp_total': xpTotal,
      'coins_total': coinsTotal,
      'current_level': currentLevel,
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'last_quiz_date': lastQuizDate,
      'next_milestone': nextMilestone,
      'next_milestone_days_away': nextMilestoneDaysAway,
    };
  }
}

