// test/utils/student_rank_utils_test.dart
//
// Unit tests for StudentRankUtils — level/rank computation and online check.

import 'package:flutter_test/flutter_test.dart';
import 'package:studymentor/src/utils/student_rank_utils.dart';
import 'package:studymentor/src/data/constants/gamification_levels.dart';

void main() {
  // ---------------------------------------------------------------------------
  // levelFromXp
  // ---------------------------------------------------------------------------

  group('StudentRankUtils.levelFromXp', () {
    test('0 XP → level 1 (Seedling)', () {
      expect(StudentRankUtils.levelFromXp(0), 1);
    });

    test('149 XP → still level 1 (just below Sprout threshold)', () {
      expect(StudentRankUtils.levelFromXp(149), 1);
    });

    test('150 XP → level 2 (Sprout boundary)', () {
      expect(StudentRankUtils.levelFromXp(150), 2);
    });

    test('349 XP → still level 2 (just below Explorer threshold)', () {
      expect(StudentRankUtils.levelFromXp(349), 2);
    });

    test('350 XP → level 3 (Explorer boundary)', () {
      expect(StudentRankUtils.levelFromXp(350), 3);
    });

    test('650 XP → level 4 (Curious Mind boundary)', () {
      expect(StudentRankUtils.levelFromXp(650), 4);
    });

    test('1050 XP → level 5 (Scholar boundary)', () {
      expect(StudentRankUtils.levelFromXp(1050), 5);
    });

    test('1600 XP → level 6 (Achiever boundary)', () {
      expect(StudentRankUtils.levelFromXp(1600), 6);
    });

    test('2300 XP → level 7 (Champion boundary)', () {
      expect(StudentRankUtils.levelFromXp(2300), 7);
    });

    test('3200 XP → level 8 (Sage boundary)', () {
      expect(StudentRankUtils.levelFromXp(3200), 8);
    });

    test('4500 XP → level 9 (Luminary boundary)', () {
      expect(StudentRankUtils.levelFromXp(4500), 9);
    });

    test('6000 XP → level 10 (Master boundary)', () {
      expect(StudentRankUtils.levelFromXp(6000), 10);
    });

    test('very large XP (10 000) → level 10 (max level)', () {
      expect(StudentRankUtils.levelFromXp(10000), 10);
    });
  });

  // ---------------------------------------------------------------------------
  // rankFromLevel
  // ---------------------------------------------------------------------------

  group('StudentRankUtils.rankFromLevel', () {
    test('level 1 → Seedling', () {
      expect(StudentRankUtils.rankFromLevel(1), 'Seedling');
    });

    test('level 2 → Sprout', () {
      expect(StudentRankUtils.rankFromLevel(2), 'Sprout');
    });

    test('level 3 → Explorer', () {
      expect(StudentRankUtils.rankFromLevel(3), 'Explorer');
    });

    test('level 4 → Curious Mind', () {
      expect(StudentRankUtils.rankFromLevel(4), 'Curious Mind');
    });

    test('level 5 → Scholar', () {
      expect(StudentRankUtils.rankFromLevel(5), 'Scholar');
    });

    test('level 10 → Master', () {
      expect(StudentRankUtils.rankFromLevel(10), 'Master');
    });

    test('level 0 or negative → Seedling (< 1 fallback)', () {
      expect(StudentRankUtils.rankFromLevel(0), 'Seedling');
      expect(StudentRankUtils.rankFromLevel(-5), 'Seedling');
    });

    test('level above max (11) → Legend', () {
      expect(StudentRankUtils.rankFromLevel(11), 'Legend');
      expect(StudentRankUtils.rankFromLevel(100), 'Legend');
    });

    test('every level maps to a non-empty rank name', () {
      for (int level = 1; level <= kGamificationLevels.length; level++) {
        expect(
          StudentRankUtils.rankFromLevel(level),
          isNotEmpty,
          reason: 'Level $level should have a non-empty rank name',
        );
      }
    });
  });

  // ---------------------------------------------------------------------------
  // rankFromXp
  // ---------------------------------------------------------------------------

  group('StudentRankUtils.rankFromXp', () {
    test('0 XP → Seedling', () {
      expect(StudentRankUtils.rankFromXp(0), 'Seedling');
    });

    test('150 XP → Sprout', () {
      expect(StudentRankUtils.rankFromXp(150), 'Sprout');
    });

    test('6000 XP → Master', () {
      expect(StudentRankUtils.rankFromXp(6000), 'Master');
    });

    test('rank derived from XP matches rank derived from level', () {
      const xp = 1200;
      final level = StudentRankUtils.levelFromXp(xp);
      expect(
        StudentRankUtils.rankFromXp(xp),
        StudentRankUtils.rankFromLevel(level),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // isOnline
  // ---------------------------------------------------------------------------

  group('StudentRankUtils.isOnline', () {
    test('returns false when lastActiveAt is null', () {
      expect(StudentRankUtils.isOnline(null), isFalse);
    });

    test('returns true when last active 1 minute ago', () {
      final oneMinuteAgo =
          DateTime.now().toUtc().subtract(const Duration(minutes: 1));
      expect(StudentRankUtils.isOnline(oneMinuteAgo), isTrue);
    });

    test('returns false when last active 10 minutes ago (default threshold is 5)', () {
      final tenMinutesAgo =
          DateTime.now().toUtc().subtract(const Duration(minutes: 10));
      expect(StudentRankUtils.isOnline(tenMinutesAgo), isFalse);
    });

    test('returns true when last active 4 minutes ago (just within threshold)', () {
      final fourMinutesAgo =
          DateTime.now().toUtc().subtract(const Duration(minutes: 4));
      expect(StudentRankUtils.isOnline(fourMinutesAgo), isTrue);
    });

    test('returns true within custom threshold', () {
      final nineMinutesAgo =
          DateTime.now().toUtc().subtract(const Duration(minutes: 9));
      expect(
        StudentRankUtils.isOnline(nineMinutesAgo, thresholdMinutes: 10),
        isTrue,
      );
    });

    test('returns false outside custom threshold', () {
      final elevenMinutesAgo =
          DateTime.now().toUtc().subtract(const Duration(minutes: 11));
      expect(
        StudentRankUtils.isOnline(elevenMinutesAgo, thresholdMinutes: 10),
        isFalse,
      );
    });
  });
}
