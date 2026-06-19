// test/models/skill_progress_model_test.dart
//
// Unit tests for SkillProgressModel — computed properties and copyWith.

import 'package:flutter_test/flutter_test.dart';
import 'package:studymentor/src/domain/models/skill_progress_model.dart';

void main() {
  // ---------------------------------------------------------------------------
  // masteryPercent
  // ---------------------------------------------------------------------------

  group('masteryPercent', () {
    test('returns 0 when totalAttempts is 0', () {
      final model = SkillProgressModel.empty(
        studentUid: 'uid',
        subjectKey: 'math',
        skillKey: 'algebra',
      );

      expect(model.masteryPercent, 0.0);
    });

    test('returns 100 when all answers are correct', () {
      final model = SkillProgressModel(
        studentUid: 'uid',
        subjectKey: 'math',
        skillKey: 'algebra',
        correctAnswers: 10,
        wrongAnswers: 0,
        totalAttempts: 10,
      );

      expect(model.masteryPercent, 100.0);
    });

    test('returns 50 when half the answers are correct', () {
      final model = SkillProgressModel(
        studentUid: 'uid',
        subjectKey: 'math',
        skillKey: 'algebra',
        correctAnswers: 5,
        wrongAnswers: 5,
        totalAttempts: 10,
      );

      expect(model.masteryPercent, 50.0);
    });

    test('returns 0 when no answers are correct', () {
      final model = SkillProgressModel(
        studentUid: 'uid',
        subjectKey: 'math',
        skillKey: 'algebra',
        correctAnswers: 0,
        wrongAnswers: 8,
        totalAttempts: 8,
      );

      expect(model.masteryPercent, 0.0);
    });

    test('calculates fractional mastery correctly', () {
      final model = SkillProgressModel(
        studentUid: 'uid',
        subjectKey: 'math',
        skillKey: 'algebra',
        correctAnswers: 1,
        wrongAnswers: 2,
        totalAttempts: 3,
      );

      expect(model.masteryPercent, closeTo(33.33, 0.01));
    });
  });

  // ---------------------------------------------------------------------------
  // isStrong / isWeak
  // ---------------------------------------------------------------------------

  group('isStrong', () {
    test('returns true when mastery >= 75%', () {
      final model = SkillProgressModel(
        studentUid: 'uid',
        subjectKey: 'math',
        skillKey: 'algebra',
        correctAnswers: 8,
        wrongAnswers: 2,
        totalAttempts: 10,
      );

      expect(model.isStrong, isTrue);
    });

    test('returns false when mastery < 75%', () {
      final model = SkillProgressModel(
        studentUid: 'uid',
        subjectKey: 'math',
        skillKey: 'algebra',
        correctAnswers: 7,
        wrongAnswers: 3,
        totalAttempts: 10,
      );

      expect(model.isStrong, isFalse);
    });

    test('returns true at exactly 75% mastery (boundary)', () {
      final model = SkillProgressModel(
        studentUid: 'uid',
        subjectKey: 'math',
        skillKey: 'algebra',
        correctAnswers: 3,
        wrongAnswers: 1,
        totalAttempts: 4,
      );

      expect(model.masteryPercent, 75.0);
      expect(model.isStrong, isTrue);
    });
  });

  group('isWeak', () {
    test('returns true when attempted and mastery < 50%', () {
      final model = SkillProgressModel(
        studentUid: 'uid',
        subjectKey: 'math',
        skillKey: 'algebra',
        correctAnswers: 3,
        wrongAnswers: 7,
        totalAttempts: 10,
      );

      expect(model.isWeak, isTrue);
    });

    test('returns false when not yet attempted', () {
      final model = SkillProgressModel.empty(
        studentUid: 'uid',
        subjectKey: 'math',
        skillKey: 'algebra',
      );

      expect(model.isWeak, isFalse);
    });

    test('returns false when mastery >= 50%', () {
      final model = SkillProgressModel(
        studentUid: 'uid',
        subjectKey: 'math',
        skillKey: 'algebra',
        correctAnswers: 5,
        wrongAnswers: 5,
        totalAttempts: 10,
      );

      expect(model.isWeak, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // copyWith
  // ---------------------------------------------------------------------------

  group('copyWith', () {
    final base = SkillProgressModel(
      studentUid: 'uid',
      subjectKey: 'math',
      skillKey: 'algebra',
      correctAnswers: 5,
      wrongAnswers: 3,
      totalAttempts: 8,
    );

    test('updates correctAnswers while preserving other fields', () {
      final updated = base.copyWith(correctAnswers: 7, totalAttempts: 10);

      expect(updated.correctAnswers, 7);
      expect(updated.totalAttempts, 10);
      expect(updated.skillKey, 'algebra');
      expect(updated.subjectKey, 'math');
    });

    test('returns equivalent model when no args provided', () {
      final copy = base.copyWith();

      expect(copy.correctAnswers, base.correctAnswers);
      expect(copy.wrongAnswers, base.wrongAnswers);
      expect(copy.totalAttempts, base.totalAttempts);
    });
  });

  // ---------------------------------------------------------------------------
  // SkillProgressModel.empty factory
  // ---------------------------------------------------------------------------

  group('SkillProgressModel.empty', () {
    test('creates model with all-zero counters and no lastPracticedAt', () {
      final empty = SkillProgressModel.empty(
        studentUid: 'uid',
        subjectKey: 'science',
        skillKey: 'cells',
      );

      expect(empty.correctAnswers, 0);
      expect(empty.wrongAnswers, 0);
      expect(empty.totalAttempts, 0);
      expect(empty.lastPracticedAt, isNull);
      expect(empty.masteryPercent, 0.0);
    });
  });
}
