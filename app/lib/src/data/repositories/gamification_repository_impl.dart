// lib/src/data/repositories/gamification_repository_impl.dart

import 'package:studymentor/src/domain/models/gamification_enums.dart';
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
  Future<RewardResult> applyQuizRewards({
    required String studentId,
    required int score,
    required int totalQuestions,
    required Duration timeTaken,
    required QuizContext context,
    required bool isComeback,
  }) async {
    // ──────────────────────────────────────────────────────────────────
    // NOTE: Rewards are now computed server-side inside routes_quizzes.py
    // on quiz submission.  This method is kept for backward compatibility
    // but the real source of truth is the `rewards` field in the
    // QuizSubmissionResponse returned by submitQuiz().
    //
    // When the UI calls this method (e.g., after receiving submission
    // results), we simply re-fetch the latest profile from the backend
    // and return it — no client-side math.
    // ──────────────────────────────────────────────────────────────────
    final profile = await _api.getGamificationProfile(studentId);
    final updated = StudentGamificationModel.fromJson(profile);

    // We can't precisely know if a level-up happened here, but the
    // quiz submission response.rewards.did_level_up field has that info.
    // The BLoC layer should use the submission response for level-up toasts.
    return RewardResult(
      updatedProfile: updated,
      xpEarned: 0,  // Real value lives in submission response
      coinsEarned: 0,
      newLevel: null,
    );
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
        xpEarned: 0,
        coinsEarned: result['coins_earned'] as int? ?? 3,
        newLevel: null,
      );
    } catch (_) {
      return null;
    }
  }
}
