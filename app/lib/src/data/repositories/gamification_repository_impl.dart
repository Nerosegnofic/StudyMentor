// lib/src/data/repositories/gamification_repository_impl.dart

import 'package:studymentor/src/domain/models/gamification_enums.dart';
import 'package:studymentor/src/domain/models/gamification_models.dart';
import 'package:studymentor/src/domain/models/reward_result.dart';
import 'package:studymentor/src/domain/repositories/gamification_repository.dart';
import 'package:studymentor/src/data/constants/gamification_levels.dart';

class GamificationRepositoryImpl implements GamificationRepository {
  // ── In-memory mock store (will be replaced with Firestore) ──────────
  final Map<String, StudentGamificationModel> _store = {};
  final Map<String, DateTime> _lastLoginStore = {};

  // ═══════════════════════════════════════════════════════════════════════
  //  PUBLIC API
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<StudentGamificationModel> getStudentGamification(
    String studentId,
  ) async {
    // Return existing state or a fresh Level-1 profile.
    return _store[studentId] ??
        StudentGamificationModel(studentId: studentId);
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
    // 1. Fetch current state.
    final current = await getStudentGamification(studentId);
    final oldLevel = levelForXp(current.xpTotal);

    // 2. Calculate rewards.
    final xpEarned = calculateQuizXp(
      score: score,
      totalQuestions: totalQuestions,
      timeTaken: timeTaken,
      context: context,
      isComeback: isComeback,
    );
    final coinsEarned = calculateQuizCoins(context: context);

    // 3. Build updated profile.
    final newXpTotal = current.xpTotal + xpEarned;
    final newCoinsTotal = current.coinsTotal + coinsEarned;
    final newLevel = levelForXp(newXpTotal);

    final updated = current.copyWith(
      xpTotal: newXpTotal,
      coinsTotal: newCoinsTotal,
      currentLevel: newLevel.levelNumber,
    );

    // 4. Simulate a backend save.
    await Future.delayed(const Duration(milliseconds: 800));
    _store[studentId] = updated;

    // 5. Return result with optional level-up.
    final didLevelUp = newLevel.levelNumber > oldLevel.levelNumber;
    return RewardResult(
      updatedProfile: updated,
      xpEarned: xpEarned,
      coinsEarned: coinsEarned,
      newLevel: didLevelUp ? newLevel : null,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  MATH LOGIC (internal)
  // ═══════════════════════════════════════════════════════════════════════

  /// Calculates the total XP earned from a single quiz.
  ///
  /// Breakdown:
  /// • +10  per correct answer
  /// • +50  perfect bonus   (score == totalQuestions)
  /// • +5   speed bonus     (finished under 1 min per question)
  /// • +20  comeback bonus  (student returning after absence)
  /// • +5   persistence     (quiz was parent-forced, student pushed through)
  int calculateQuizXp({
    required int score,
    required int totalQuestions,
    required Duration timeTaken,
    required QuizContext context,
    required bool isComeback,
  }) {
    // ── Defensive clamping ──────────────────────────────────────────────
    final clampedTotal = totalQuestions < 0 ? 0 : totalQuestions;
    final clampedScore = score.clamp(0, clampedTotal);

    int xp = 0;

    // Base XP: +10 per correct answer.
    xp += clampedScore * 10;

    // Perfect bonus: all answers correct.
    if (clampedTotal > 0 && clampedScore == clampedTotal) {
      xp += 50;
    }

    // Speed bonus: finished within the target time (1 min per question).
    if (clampedTotal > 0) {
      final targetDuration = Duration(minutes: clampedTotal);
      if (timeTaken > Duration.zero && timeTaken <= targetDuration) {
        xp += 5;
      }
    }

    // Comeback bonus.
    if (isComeback) {
      xp += 20;
    }

    // Persistence bonus: forced context means the student was told to study.
    if (context == QuizContext.forced) {
      xp += 5;
    }

    return xp;
  }

  /// Calculates the total Coins earned from a single quiz.
  ///
  /// Breakdown:
  /// • +5  base completion reward
  /// • +5  freedom bonus (quiz was forced, rewarding compliance)
  int calculateQuizCoins({required QuizContext context}) {
    int coins = 5; // Base completion reward.

    if (context == QuizContext.forced) {
      coins += 5; // Freedom bonus.
    }

    return coins;
  }

  @override
  Future<RewardResult?> checkAndAwardDailyLogin(String studentId) async {
    final today = DateTime.now();
    final lastLogin = _lastLoginStore[studentId];
    if (lastLogin != null &&
        lastLogin.year == today.year &&
        lastLogin.month == today.month &&
        lastLogin.day == today.day) {
      return null;
    }
    _lastLoginStore[studentId] = today;

    final current = await getStudentGamification(studentId);
    final updated = current.copyWith(
      coinsTotal: current.coinsTotal + 3,
    );
    _store[studentId] = updated;

    return RewardResult(
      updatedProfile: updated,
      xpEarned: 0,
      coinsEarned: 3,
      newLevel: null,
    );
  }
}
