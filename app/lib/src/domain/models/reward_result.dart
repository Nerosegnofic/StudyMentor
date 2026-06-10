// lib/src/domain/models/reward_result.dart

import 'gamification_models.dart';

/// The outcome of applying quiz rewards to a student's profile.
class RewardResult {
  /// The student's updated gamification state after rewards are applied.
  final StudentGamificationModel updatedProfile;

  /// Total XP earned from this quiz.
  final int xpEarned;

  /// Total Coins earned from this quiz.
  final int coinsEarned;

  /// Non-null only if the student crossed a level threshold.
  final LevelModel? newLevel;

  const RewardResult({
    required this.updatedProfile,
    required this.xpEarned,
    required this.coinsEarned,
    this.newLevel,
  });

  /// Whether the student leveled up as a result of this quiz.
  bool get didLevelUp => newLevel != null;
}
