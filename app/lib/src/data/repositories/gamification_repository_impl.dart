// lib/src/data/repositories/gamification_repository_impl.dart

import 'package:studymentor/src/domain/models/gamification_models.dart';
import 'package:studymentor/src/domain/models/reward_result.dart';
import 'package:studymentor/src/domain/repositories/gamification_repository.dart';
import 'package:studymentor/src/data/repositories/ai_engine_repository.dart';

/// Server-authoritative gamification repository.
///
/// All reward calculations now happen on the backend (FastAPI).
/// The client fetches the profile from the gamification API and
/// receives rewards as part of the quiz submission response.
class GamificationRepositoryImpl implements GamificationRepository {
  final AiEngineRepository _api;

  GamificationRepositoryImpl({AiEngineRepository? api})
      : _api = api ?? AiEngineRepository.instance;

  // ═══════════════════════════════════════════════════════════════════════
  //  PUBLIC API
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<StudentGamificationModel> getStudentGamification(
    String studentId,
  ) async {
    try {
      final profile = await _api.getGamificationProfile(studentId);
      return StudentGamificationModel.fromJson(profile);
    } catch (_) {
      // Fallback: return defaults if the backend is unreachable.
      return StudentGamificationModel(studentId: studentId);
    }
  }

  @override
  Future<RewardResult?> checkAndAwardDailyLogin(String studentId) async {
    try {
      final result = await _api.checkDailyLogin(studentId);
      final awarded = result['awarded'] as bool? ?? false;
      if (!awarded) return null;

      final profile = await _api.getGamificationProfile(studentId);
      final updated = StudentGamificationModel.fromJson(profile);

      return RewardResult(
        updatedProfile: updated,
        coinsEarned: result['coins_earned'] as int? ?? 3,
      );
    } catch (_) {
      return null;
    }
  }
}
