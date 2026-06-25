// lib/src/domain/models/reward_result.dart

import 'gamification_models.dart';

/// The outcome of a daily-login reward check.
class RewardResult {
  /// The student's updated gamification state after rewards are applied.
  final StudentGamificationModel updatedProfile;

  /// Total Coins earned.
  final int coinsEarned;

  const RewardResult({
    required this.updatedProfile,
    required this.coinsEarned,
  });
}
