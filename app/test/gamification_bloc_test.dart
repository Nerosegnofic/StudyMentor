// test/gamification_bloc_test.dart
//
// Unit tests for GamificationBloc — uses a MockAiEngineRepository injected
// into GamificationRepositoryImpl so Firebase is never touched.

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:studymentor/src/bloc/gamification/gamification_bloc.dart';
import 'package:studymentor/src/bloc/gamification/gamification_event.dart';
import 'package:studymentor/src/bloc/gamification/gamification_state.dart';
import 'package:studymentor/src/data/repositories/ai_engine_repository.dart';
import 'package:studymentor/src/data/repositories/gamification_repository_impl.dart';
import 'package:studymentor/src/domain/models/gamification_enums.dart';

class MockAiEngineRepository extends Mock implements AiEngineRepository {}

void main() {
  late MockAiEngineRepository mockApi;
  late GamificationRepositoryImpl repository;
  late GamificationBloc bloc;

  setUp(() {
    mockApi = MockAiEngineRepository();

    // Default: return an empty profile for any student.
    when(() => mockApi.getGamificationProfile(any()))
        .thenAnswer((_) async => {
              'xp_total': 0,
              'coins_total': 0,
              'current_level': 1,
              'current_streak': 0,
              'longest_streak': 0,
            });

    // Default: no daily login reward.
    when(() => mockApi.checkDailyLogin(any()))
        .thenAnswer((_) async => {'awarded': false});

    // 'existing-student' already has XP from a previous quiz.
    when(() => mockApi.getGamificationProfile('existing-student'))
        .thenAnswer((_) async => {
              'xp_total': 50,
              'coins_total': 5,
              'current_level': 1,
              'current_streak': 0,
              'longest_streak': 0,
            });

    // First daily login of the day for 'daily-student-1'.
    when(() => mockApi.checkDailyLogin('daily-student-1'))
        .thenAnswer((_) async => {'awarded': true, 'coins_earned': 3});
    when(() => mockApi.getGamificationProfile('daily-student-1'))
        .thenAnswer((_) async => {
              'xp_total': 0,
              'coins_total': 3,
              'current_level': 1,
              'current_streak': 0,
              'longest_streak': 0,
            });

    repository = GamificationRepositoryImpl(api: mockApi);
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
        // Pre-populate the store — applyQuizRewards re-fetches from the API.
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
          rewards: {
            'xp_earned': 30,
            'coins_earned': 5,
            'xp_total': 30,
            'coins_total': 5,
            'new_level': 1,
            'did_level_up': false,
          },
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
          rewards: {
            'xp_earned': 150,
            'coins_earned': 20,
            'xp_total': 150,
            'coins_total': 20,
            'new_level': 2,
            'did_level_up': true,
          },
        ),
      ),
      expect: () => [
        isA<GamificationRewardProcessed>()
            .having((s) => s.leveledUpTo, 'leveledUpTo', 2),
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
          rewards: {
            'xp_earned': 50,
            'coins_earned': 10,
            'xp_total': 50,
            'coins_total': 10,
            'new_level': 1,
            'did_level_up': false,
          },
        ),
      ),
      expect: () => [
        isA<GamificationRewardProcessed>(),
        isA<GamificationLoaded>().having(
          (s) => s.profile.coinsTotal,
          'coinsTotal',
          10,
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
