// lib/src/domain/repositories/gamification_repository.dart

import '../models/gamification_models.dart';
import '../models/reward_result.dart';

/// Contract for all gamification read/write operations.
abstract class GamificationRepository {
  /// Fetches the current gamification state for a student.
  Future<StudentGamificationModel> getStudentGamification(String studentId);

  /// Checks if the student has already logged in today and awards +3 coins if not.
  Future<RewardResult?> checkAndAwardDailyLogin(String studentId);
}
