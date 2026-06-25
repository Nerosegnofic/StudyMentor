// test/utils/student_rank_utils_test.dart
//
// Unit tests for StudentRankUtils — level computation.

import 'package:flutter_test/flutter_test.dart';
import 'package:studymentor/src/utils/student_rank_utils.dart';
import 'package:studymentor/src/data/constants/gamification_levels.dart';

void main() {
  group('StudentRankUtils.levelFromXp', () {
    test('0 XP → level 1', () {
      expect(StudentRankUtils.levelFromXp(0), 1);
    });

    test('149 XP → still level 1 (just below Sprout threshold)', () {
      expect(StudentRankUtils.levelFromXp(149), 1);
    });

    test('150 XP → level 2 (Sprout boundary)', () {
      expect(StudentRankUtils.levelFromXp(150), 2);
    });

    test('349 XP → still level 2', () {
      expect(StudentRankUtils.levelFromXp(349), 2);
    });

    test('350 XP → level 3', () {
      expect(StudentRankUtils.levelFromXp(350), 3);
    });

    test('650 XP → level 4', () {
      expect(StudentRankUtils.levelFromXp(650), 4);
    });

    test('1050 XP → level 5', () {
      expect(StudentRankUtils.levelFromXp(1050), 5);
    });

    test('1600 XP → level 6', () {
      expect(StudentRankUtils.levelFromXp(1600), 6);
    });

    test('2300 XP → level 7', () {
      expect(StudentRankUtils.levelFromXp(2300), 7);
    });

    test('3200 XP → level 8', () {
      expect(StudentRankUtils.levelFromXp(3200), 8);
    });

    test('4500 XP → level 9', () {
      expect(StudentRankUtils.levelFromXp(4500), 9);
    });

    test('6000 XP → level 10 (max)', () {
      expect(StudentRankUtils.levelFromXp(6000), 10);
    });

    test('very large XP (10 000) → level 10 (max level)', () {
      expect(StudentRankUtils.levelFromXp(10000), 10);
    });

    test('levelFromXp returns a value within valid level range', () {
      for (final xp in [0, 100, 500, 1000, 5000, 9999]) {
        final level = StudentRankUtils.levelFromXp(xp);
        expect(level, greaterThanOrEqualTo(1));
        expect(level, lessThanOrEqualTo(kGamificationLevels.length));
      }
    });
  });
}
