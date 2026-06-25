// lib/src/domain/models/gamification_models.dart

/// Represents a single level definition in the progression system.
class LevelModel {
  final int levelNumber;
  final int xpRequired;

  const LevelModel({
    required this.levelNumber,
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

  const StudentGamificationModel({
    required this.studentId,
    this.xpTotal = 0,
    this.coinsTotal = 0,
    this.currentLevel = 1,
    this.currentStreak = 0,
  });

  StudentGamificationModel copyWith({
    String? studentId,
    int? xpTotal,
    int? coinsTotal,
    int? currentLevel,
    int? currentStreak,
  }) {
    return StudentGamificationModel(
      studentId: studentId ?? this.studentId,
      xpTotal: xpTotal ?? this.xpTotal,
      coinsTotal: coinsTotal ?? this.coinsTotal,
      currentLevel: currentLevel ?? this.currentLevel,
      currentStreak: currentStreak ?? this.currentStreak,
    );
  }

  factory StudentGamificationModel.fromJson(Map<String, dynamic> json) {
    return StudentGamificationModel(
      studentId: json['student_uid'] as String? ?? json['student_id'] as String? ?? '',
      xpTotal: json['xp_total'] as int? ?? 0,
      coinsTotal: json['coins_total'] as int? ?? 0,
      currentLevel: json['current_level'] as int? ?? 1,
      currentStreak: json['current_streak'] as int? ?? 0,
    );
  }
}
