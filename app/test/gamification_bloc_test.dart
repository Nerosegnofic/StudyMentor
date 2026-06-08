// test/gamification_bloc_test.dart
//
// Unit tests for Sprint 1.3 GamificationBloc.

import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:studymentor/src/domain/models/gamification_enums.dart';
import 'package:studymentor/src/domain/models/gamification_models.dart';
import 'package:studymentor/src/bloc/gamification/gamification_bloc.dart';
import 'package:studymentor/src/bloc/gamification/gamification_event.dart';
import 'package:studymentor/src/bloc/gamification/gamification_state.dart';
import 'package:studymentor/src/data/repositories/gamification_repository_impl.dart';

void main() {
  late GamificationRepositoryImpl repository;
  late GamificationBloc bloc;

  setUp(() {
    repository = GamificationRepositoryImpl();
    bloc = GamificationBloc(repository: repository);
  });

  tearDown(() {
    bloc.close();
  });

  // ═══════════════════════════════════════════════════════════════════════
  //  LoadGamificationDataRequested
  // ═══════════════════════════════════════════════════════════════════════

  group('LoadGamificationDataRequested', () {
    blocTest<GamificationBloc, GamificationState>(
      'emits [Loading, Loaded] with a fresh profile for a new student',
      build: () => GamificationBloc(repository: repository),
      act: (bloc) => bloc.add(
        const LoadGamificationDataRequested(studentId: 'new-student'),
      ),
      expect: () => [
        isA<GamificationLoading>(),
        isA<GamificationLoaded>().having(
          (s) => s.profile.xpTotal,
          'xpTotal',
          0,
        ),
      ],
    );

    blocTest<GamificationBloc, GamificationState>(
      'returns correct data after rewards were previously applied',
      build: () => GamificationBloc(repository: repository),
      seed: () => GamificationInitial(),
      setUp: () async {
        // Pre-populate the store
        await repository.applyQuizRewards(
          studentId: 'existing-student',
          score: 5,
          totalQuestions: 5,
          timeTaken: const Duration(minutes: 3),
          context: QuizContext.voluntary,
          isComeback: false,
        );
      },
      act: (bloc) => bloc.add(
        const LoadGamificationDataRequested(studentId: 'existing-student'),
      ),
      expect: () => [
        isA<GamificationLoading>(),
        isA<GamificationLoaded>().having(
          (s) => s.profile.xpTotal,
          'xpTotal',
          greaterThan(0),
        ),
      ],
    );
  });

  // ═══════════════════════════════════════════════════════════════════════
  //  ProcessQuizRewardsRequested
  // ═══════════════════════════════════════════════════════════════════════

  group('ProcessQuizRewardsRequested', () {
    blocTest<GamificationBloc, GamificationState>(
      'emits [RewardProcessed, Loaded] after a quiz',
      build: () => GamificationBloc(repository: repository),
      wait: const Duration(seconds: 1),
      act: (bloc) => bloc.add(
        const ProcessQuizRewardsRequested(
          studentId: 'student-bloc-1',
          score: 3,
          totalQuestions: 5,
          timeTaken: Duration(minutes: 10),
          context: QuizContext.voluntary,
          isComeback: false,
        ),
      ),
      expect: () => [
        isA<GamificationRewardProcessed>()
            .having((s) => s.xpEarned, 'xpEarned', 30)
            .having((s) => s.coinsEarned, 'coinsEarned', 5)
            .having((s) => s.leveledUpTo, 'leveledUpTo', isNull),
        isA<GamificationLoaded>().having(
          (s) => s.profile.xpTotal,
          'xpTotal',
          30,
        ),
      ],
    );

    blocTest<GamificationBloc, GamificationState>(
      'detects level-up and includes LevelModel in RewardProcessed',
      build: () => GamificationBloc(repository: repository),
      wait: const Duration(seconds: 1),
      act: (bloc) => bloc.add(
        const ProcessQuizRewardsRequested(
          studentId: 'student-bloc-2',
          score: 10,
          totalQuestions: 10,
          timeTaken: Duration(minutes: 5),
          context: QuizContext.voluntary,
          isComeback: false,
        ),
      ),
      expect: () => [
        isA<GamificationRewardProcessed>()
            .having((s) => s.leveledUpTo, 'leveledUpTo', isNotNull)
            .having(
              (s) => s.leveledUpTo!.levelName,
              'levelName',
              'Sprout',
            ),
        isA<GamificationLoaded>(),
      ],
    );

    blocTest<GamificationBloc, GamificationState>(
      'final GamificationLoaded state has the updated profile totals',
      build: () => GamificationBloc(repository: repository),
      wait: const Duration(seconds: 1),
      act: (bloc) => bloc.add(
        const ProcessQuizRewardsRequested(
          studentId: 'student-bloc-3',
          score: 5,
          totalQuestions: 5,
          timeTaken: Duration(minutes: 3),
          context: QuizContext.forced,
          isComeback: true,
        ),
      ),
      expect: () => [
        isA<GamificationRewardProcessed>(),
        isA<GamificationLoaded>().having(
          (s) => s.profile.coinsTotal,
          'coinsTotal',
          10, // 5 base + 5 freedom
        ),
      ],
    );
  });

  group('CheckDailyLoginRewardRequested', () {
    blocTest<GamificationBloc, GamificationState>(
      'emits [RewardProcessed, Loaded] on first check of the day',
      build: () => GamificationBloc(repository: repository),
      act: (bloc) => bloc.add(
        const CheckDailyLoginRewardRequested(studentId: 'daily-student-1'),
      ),
      expect: () => [
        isA<GamificationRewardProcessed>()
            .having((s) => s.xpEarned, 'xpEarned', 0)
            .having((s) => s.coinsEarned, 'coinsEarned', 3),
        isA<GamificationLoaded>().having(
          (s) => s.profile.coinsTotal,
          'coinsTotal',
          3,
        ),
      ],
    );

    blocTest<GamificationBloc, GamificationState>(
      'does not emit anything on subsequent checks of the same day',
      build: () => GamificationBloc(repository: repository),
      setUp: () async {
        await repository.checkAndAwardDailyLogin('daily-student-2');
      },
      act: (bloc) => bloc.add(
        const CheckDailyLoginRewardRequested(studentId: 'daily-student-2'),
      ),
      expect: () => <GamificationState>[],
    );
  });
}
