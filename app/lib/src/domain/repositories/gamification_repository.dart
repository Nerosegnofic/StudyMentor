// lib/src/domain/repositories/gamification_repository.dart

import '../models/gamification_enums.dart';
import '../models/gamification_models.dart';
import '../models/reward_result.dart';

/// Contract for all gamification read/write operations.
abstract class GamificationRepository {
  /// Fetches the current gamification state for a student.
  Future<StudentGamificationModel> getStudentGamification(String studentId);

  /// Calculates and persists XP + Coin rewards after a quiz,
  /// returning the updated state and any level-up info.
  Future<RewardResult> applyQuizRewards({
    required String studentId,
    required int score,
    required int totalQuestions,
    required Duration timeTaken,
    required QuizContext context,
    required bool isComeback,
  });

  /// Checks if the student has already logged in today and awards +3 coins if not.
  Future<RewardResult?> checkAndAwardDailyLogin(String studentId);
}
