// test/models/skill_progress_model_test.dart
//
// Unit tests for SkillProgressModel — computed properties.

import 'package:flutter_test/flutter_test.dart';
import 'package:studymentor/src/domain/models/skill_progress_model.dart';

void main() {
  // ---------------------------------------------------------------------------
  // masteryPercent
  // ---------------------------------------------------------------------------

  group('masteryPercent', () {
    test('returns 0 when totalAttempts is 0', () {
      const model = SkillProgressModel(
        skillKey: 'algebra',
        correctAnswers: 0,
        totalAttempts: 0,
      );

      expect(model.masteryPercent, 0.0);
    });

    test('returns 100 when all answers are correct', () {
      const model = SkillProgressModel(
        skillKey: 'algebra',
        correctAnswers: 10,
        totalAttempts: 10,
      );

      expect(model.masteryPercent, 100.0);
    });

    test('returns 50 when half the answers are correct', () {
      const model = SkillProgressModel(
        skillKey: 'algebra',
        correctAnswers: 5,
        totalAttempts: 10,
      );

      expect(model.masteryPercent, 50.0);
    });

    test('returns 0 when no answers are correct', () {
      const model = SkillProgressModel(
        skillKey: 'algebra',
        correctAnswers: 0,
        totalAttempts: 8,
      );

      expect(model.masteryPercent, 0.0);
    });

    test('calculates fractional mastery correctly', () {
      const model = SkillProgressModel(
        skillKey: 'algebra',
        correctAnswers: 1,
        totalAttempts: 3,
      );

      expect(model.masteryPercent, closeTo(33.33, 0.01));
    });
  });

  // ---------------------------------------------------------------------------
  // isStrong / isWeak
  // ---------------------------------------------------------------------------

  group('isStrong', () {
    test('returns > 0 for non-zero mastery', () {
      const model = SkillProgressModel(
        skillKey: 'algebra',
        correctAnswers: 8,
        totalAttempts: 10,
      );

      expect(model.masteryPercent, greaterThan(0));
    });
  });
}
