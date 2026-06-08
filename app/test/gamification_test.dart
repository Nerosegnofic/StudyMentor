// test/gamification_test.dart
//
// Unit tests for Sprint 1.1 + 1.2 gamification logic.

import 'package:flutter_test/flutter_test.dart';
import 'package:studymentor/src/domain/models/gamification_enums.dart';
import 'package:studymentor/src/domain/models/gamification_models.dart';
import 'package:studymentor/src/domain/models/reward_result.dart';
import 'package:studymentor/src/data/constants/gamification_levels.dart';
import 'package:studymentor/src/data/repositories/gamification_repository_impl.dart';

void main() {
  late GamificationRepositoryImpl repo;

  setUp(() {
    repo = GamificationRepositoryImpl();
  });

  // ═══════════════════════════════════════════════════════════════════════
  //  levelForXp
  // ═══════════════════════════════════════════════════════════════════════

  group('levelForXp', () {
    test('0 XP → Level 1 Seedling', () {
      final level = levelForXp(0);
      expect(level.levelNumber, 1);
      expect(level.levelName, 'Seedling');
    });

    test('exactly on a threshold → that level', () {
      expect(levelForXp(150).levelNumber, 2);
      expect(levelForXp(350).levelNumber, 3);
      expect(levelForXp(6000).levelNumber, 10);
    });

    test('between thresholds → lower level', () {
      expect(levelForXp(149).levelNumber, 1);
      expect(levelForXp(349).levelNumber, 2);
      expect(levelForXp(5999).levelNumber, 9);
    });

    test('above max → Level 10', () {
      expect(levelForXp(99999).levelNumber, 10);
    });

    test('negative XP → Level 1 (defensive)', () {
      expect(levelForXp(-100).levelNumber, 1);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  //  calculateQuizXp
  // ═══════════════════════════════════════════════════════════════════════

  group('calculateQuizXp', () {
    test('base XP: +10 per correct answer', () {
      final xp = repo.calculateQuizXp(
        score: 3,
        totalQuestions: 5,
        timeTaken: const Duration(minutes: 10),
        context: QuizContext.voluntary,
        isComeback: false,
      );
      expect(xp, 30); // 3 * 10
    });

    test('perfect bonus: +50 when score == totalQuestions', () {
      final xp = repo.calculateQuizXp(
        score: 5,
        totalQuestions: 5,
        timeTaken: const Duration(minutes: 10),
        context: QuizContext.voluntary,
        isComeback: false,
      );
      // 5*10 + 50 perfect = 100 (no speed: 10min > 5min target)
      expect(xp, 100);
    });

    test('speed bonus: +5 when finished within 1 min/question', () {
      final xp = repo.calculateQuizXp(
        score: 3,
        totalQuestions: 5,
        timeTaken: const Duration(minutes: 4), // under 5-min target
        context: QuizContext.voluntary,
        isComeback: false,
      );
      expect(xp, 35); // 30 + 5 speed
    });

    test('speed bonus: exactly on the target time still qualifies', () {
      final xp = repo.calculateQuizXp(
        score: 3,
        totalQuestions: 5,
        timeTaken: const Duration(minutes: 5), // exactly 5-min target
        context: QuizContext.voluntary,
        isComeback: false,
      );
      expect(xp, 35); // 30 + 5 speed
    });

    test('comeback bonus: +20', () {
      final xp = repo.calculateQuizXp(
        score: 1,
        totalQuestions: 5,
        timeTaken: const Duration(minutes: 10),
        context: QuizContext.voluntary,
        isComeback: true,
      );
      expect(xp, 30); // 10 + 20 comeback
    });

    test('persistence bonus: +5 for forced context', () {
      final xp = repo.calculateQuizXp(
        score: 1,
        totalQuestions: 5,
        timeTaken: const Duration(minutes: 10),
        context: QuizContext.forced,
        isComeback: false,
      );
      expect(xp, 15); // 10 + 5 persistence
    });

    test('all bonuses stack correctly', () {
      final xp = repo.calculateQuizXp(
        score: 5,
        totalQuestions: 5,
        timeTaken: const Duration(minutes: 3),
        context: QuizContext.forced,
        isComeback: true,
      );
      // 50 base + 50 perfect + 5 speed + 20 comeback + 5 persistence = 130
      expect(xp, 130);
    });

    // ── Edge cases ─────────────────────────────────────────────────────

    test('zero score → 0 base XP, no perfect bonus', () {
      final xp = repo.calculateQuizXp(
        score: 0,
        totalQuestions: 5,
        timeTaken: const Duration(minutes: 10),
        context: QuizContext.voluntary,
        isComeback: false,
      );
      expect(xp, 0);
    });

    test('zero totalQuestions → no XP (no crash)', () {
      final xp = repo.calculateQuizXp(
        score: 0,
        totalQuestions: 0,
        timeTaken: Duration.zero,
        context: QuizContext.voluntary,
        isComeback: false,
      );
      expect(xp, 0);
    });

    test('negative score is clamped to 0', () {
      final xp = repo.calculateQuizXp(
        score: -5,
        totalQuestions: 5,
        timeTaken: const Duration(minutes: 10),
        context: QuizContext.voluntary,
        isComeback: false,
      );
      expect(xp, 0); // clamped to 0, not -50
    });

    test('score > totalQuestions is clamped to totalQuestions', () {
      final xp = repo.calculateQuizXp(
        score: 20,
        totalQuestions: 5,
        timeTaken: const Duration(minutes: 10),
        context: QuizContext.voluntary,
        isComeback: false,
      );
      // Clamped to 5 correct: 50 base + 50 perfect = 100
      expect(xp, 100);
    });

    test('negative totalQuestions is clamped to 0', () {
      final xp = repo.calculateQuizXp(
        score: 5,
        totalQuestions: -3,
        timeTaken: const Duration(minutes: 1),
        context: QuizContext.voluntary,
        isComeback: false,
      );
      expect(xp, 0); // Both clamped to 0
    });

    test('zero-duration timeTaken does not earn speed bonus', () {
      final xp = repo.calculateQuizXp(
        score: 3,
        totalQuestions: 5,
        timeTaken: Duration.zero,
        context: QuizContext.voluntary,
        isComeback: false,
      );
      expect(xp, 30); // No speed bonus for instant completion
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  //  calculateQuizCoins
  // ═══════════════════════════════════════════════════════════════════════

  group('calculateQuizCoins', () {
    test('voluntary quiz → 5 coins', () {
      expect(repo.calculateQuizCoins(context: QuizContext.voluntary), 5);
    });

    test('forced quiz → 10 coins (5 base + 5 freedom)', () {
      expect(repo.calculateQuizCoins(context: QuizContext.forced), 10);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  //  StudentGamificationModel serialization
  // ═══════════════════════════════════════════════════════════════════════

  group('StudentGamificationModel', () {
    test('toJson → fromJson roundtrip', () {
      const model = StudentGamificationModel(
        studentId: 'abc',
        xpTotal: 500,
        coinsTotal: 30,
        currentLevel: 4,
      );
      final json = model.toJson();
      final restored = StudentGamificationModel.fromJson(json);
      expect(restored.studentId, 'abc');
      expect(restored.xpTotal, 500);
      expect(restored.coinsTotal, 30);
      expect(restored.currentLevel, 4);
    });

    test('fromJson with missing optional fields uses defaults', () {
      final model = StudentGamificationModel.fromJson({
        'student_id': 'xyz',
      });
      expect(model.xpTotal, 0);
      expect(model.coinsTotal, 0);
      expect(model.currentLevel, 1);
    });

    test('copyWith preserves unmodified fields', () {
      const original = StudentGamificationModel(
        studentId: 'abc',
        xpTotal: 100,
        coinsTotal: 20,
        currentLevel: 2,
      );
      final updated = original.copyWith(xpTotal: 200);
      expect(updated.xpTotal, 200);
      expect(updated.coinsTotal, 20); // unchanged
      expect(updated.currentLevel, 2); // unchanged
      expect(updated.studentId, 'abc'); // unchanged
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  //  RewardTransactionModel serialization
  // ═══════════════════════════════════════════════════════════════════════

  group('RewardTransactionModel', () {
    test('toJson → fromJson roundtrip', () {
      final now = DateTime.utc(2026, 6, 8, 12, 0, 0);
      final model = RewardTransactionModel(
        id: 'txn-1',
        studentId: 'abc',
        amount: 50,
        type: 'xp',
        reason: 'correctAnswer',
        createdAt: now,
      );
      final json = model.toJson();
      final restored = RewardTransactionModel.fromJson(json);
      expect(restored.id, 'txn-1');
      expect(restored.amount, 50);
      expect(restored.type, 'xp');
      expect(restored.createdAt, now);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  //  applyQuizRewards (integration)
  // ═══════════════════════════════════════════════════════════════════════

  group('applyQuizRewards', () {
    test('first quiz on a fresh student starts from 0', () async {
      final result = await repo.applyQuizRewards(
        studentId: 'student-1',
        score: 3,
        totalQuestions: 5,
        timeTaken: const Duration(minutes: 10),
        context: QuizContext.voluntary,
        isComeback: false,
      );
      expect(result.xpEarned, 30);
      expect(result.coinsEarned, 5);
      expect(result.updatedProfile.xpTotal, 30);
      expect(result.updatedProfile.coinsTotal, 5);
      expect(result.didLevelUp, false);
    });

    test('rewards accumulate across multiple quizzes', () async {
      // Quiz 1
      await repo.applyQuizRewards(
        studentId: 'student-2',
        score: 5,
        totalQuestions: 5,
        timeTaken: const Duration(minutes: 3),
        context: QuizContext.voluntary,
        isComeback: false,
      );

      // Quiz 2
      final result = await repo.applyQuizRewards(
        studentId: 'student-2',
        score: 5,
        totalQuestions: 5,
        timeTaken: const Duration(minutes: 3),
        context: QuizContext.voluntary,
        isComeback: false,
      );

      // Each quiz: 50 + 50 + 5 = 105 XP, 5 coins
      expect(result.updatedProfile.xpTotal, 210);
      expect(result.updatedProfile.coinsTotal, 10);
    });

    test('detects level-up when crossing threshold', () async {
      // Push to just below level 2 (150 XP)
      // A perfect 10-question quiz with speed: 100 + 50 + 5 = 155 XP → Level 2
      final result = await repo.applyQuizRewards(
        studentId: 'student-3',
        score: 10,
        totalQuestions: 10,
        timeTaken: const Duration(minutes: 5),
        context: QuizContext.voluntary,
        isComeback: false,
      );
      expect(result.xpEarned, 155);
      expect(result.didLevelUp, true);
      expect(result.newLevel!.levelNumber, 2);
      expect(result.newLevel!.levelName, 'Sprout');
    });

    test('no level-up if staying within same level', () async {
      final result = await repo.applyQuizRewards(
        studentId: 'student-4',
        score: 1,
        totalQuestions: 5,
        timeTaken: const Duration(minutes: 10),
        context: QuizContext.voluntary,
        isComeback: false,
      );
      expect(result.xpEarned, 10);
      expect(result.didLevelUp, false);
      expect(result.newLevel, isNull);
    });
  });
}
