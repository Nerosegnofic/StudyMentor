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

  const StudentGamificationModel({
    required this.studentId,
    this.xpTotal = 0,
    this.coinsTotal = 0,
    this.currentLevel = 1,
  });

  StudentGamificationModel copyWith({
    String? studentId,
    int? xpTotal,
    int? coinsTotal,
    int? currentLevel,
  }) {
    return StudentGamificationModel(
      studentId: studentId ?? this.studentId,
      xpTotal: xpTotal ?? this.xpTotal,
      coinsTotal: coinsTotal ?? this.coinsTotal,
      currentLevel: currentLevel ?? this.currentLevel,
    );
  }

  factory StudentGamificationModel.fromJson(Map<String, dynamic> json) {
    return StudentGamificationModel(
      studentId: json['student_id'] as String,
      xpTotal: json['xp_total'] as int? ?? 0,
      coinsTotal: json['coins_total'] as int? ?? 0,
      currentLevel: json['current_level'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'student_id': studentId,
      'xp_total': xpTotal,
      'coins_total': coinsTotal,
      'current_level': currentLevel,
    };
  }
}

/// A single XP or Coin transaction in the reward ledger.
class RewardTransactionModel {
  final String id;
  final String studentId;
  final int amount;

  /// Either 'xp' or 'coin'.
  final String type;

  /// Human-readable reason (e.g. 'correctAnswer', 'dailyLogin').
  final String reason;
  final DateTime createdAt;

  const RewardTransactionModel({
    required this.id,
    required this.studentId,
    required this.amount,
    required this.type,
    required this.reason,
    required this.createdAt,
  });

  factory RewardTransactionModel.fromJson(Map<String, dynamic> json) {
    return RewardTransactionModel(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      amount: json['amount'] as int,
      type: json['type'] as String,
      reason: json['reason'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'amount': amount,
      'type': type,
      'reason': reason,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
