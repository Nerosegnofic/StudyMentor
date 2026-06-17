// test/gamification_test.dart
//
// Unit tests for the gamification domain models and level system.
//
// NOTE: XP/Coin calculations have moved to the Python backend
// (ai_engine/app/services/gamification/gamification_service.py).
// Tests for those calculations now live in the backend test suite.

import 'package:flutter_test/flutter_test.dart';
import 'package:studymentor/src/domain/models/gamification_models.dart';
import 'package:studymentor/src/data/constants/gamification_levels.dart';

void main() {
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

}
