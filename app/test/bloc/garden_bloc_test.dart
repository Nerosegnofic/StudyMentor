// test/bloc/garden_bloc_test.dart
//
// Unit tests for GardenBloc.
// AiEngineRepository is injected so no Firebase or HTTP is needed.

import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:studymentor/src/bloc/garden/garden_bloc.dart';
import 'package:studymentor/src/bloc/garden/garden_event.dart';
import 'package:studymentor/src/bloc/garden/garden_state.dart';
import 'package:studymentor/src/data/repositories/ai_engine_repository.dart';
import 'package:studymentor/src/domain/models/garden_plant_model.dart';

// ---------------------------------------------------------------------------
// Mock
// ---------------------------------------------------------------------------

class MockAiEngineRepository extends Mock implements AiEngineRepository {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

List<GardenPlantModel> _fakePlants() => [
      const GardenPlantModel(
        subjectId: 1,
        subjectName: 'Math',
        masteryPercent: 65.0,
      ),
      const GardenPlantModel(
        subjectId: 2,
        subjectName: 'Science',
        masteryPercent: 30.0,
      ),
    ];

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockAiEngineRepository mockRepo;

  setUp(() {
    mockRepo = MockAiEngineRepository();
  });

  group('GardenBloc', () {
    // ── LoadGardenRequested ──────────────────────────────────────────────────

    group('LoadGardenRequested', () {
      blocTest<GardenBloc, GardenState>(
        'emits [GardenLoading, GardenLoaded] with plants on success',
        build: () => GardenBloc(repo: mockRepo),
        setUp: () {
          when(() => mockRepo.getGarden())
              .thenAnswer((_) async => _fakePlants());
        },
        act: (bloc) => bloc.add(
          const LoadGardenRequested(studentUid: 'uid-student'),
        ),
        expect: () => [
          isA<GardenLoading>(),
          isA<GardenLoaded>().having(
            (s) => s.plants.length,
            'plants.length',
            2,
          ),
        ],
      );

      blocTest<GardenBloc, GardenState>(
        'emits [GardenLoading, GardenLoaded] with correct subject names',
        build: () => GardenBloc(repo: mockRepo),
        setUp: () {
          when(() => mockRepo.getGarden())
              .thenAnswer((_) async => _fakePlants());
        },
        act: (bloc) => bloc.add(
          const LoadGardenRequested(studentUid: 'uid-student'),
        ),
        expect: () => [
          isA<GardenLoading>(),
          isA<GardenLoaded>().having(
            (s) => s.plants.map((p) => p.subjectName).toList(),
            'subjectNames',
            ['Math', 'Science'],
          ),
        ],
      );

      blocTest<GardenBloc, GardenState>(
        'emits [GardenLoading, GardenLoaded] with empty list when no subjects',
        build: () => GardenBloc(repo: mockRepo),
        setUp: () {
          when(() => mockRepo.getGarden()).thenAnswer((_) async => []);
        },
        act: (bloc) => bloc.add(
          const LoadGardenRequested(studentUid: 'uid-student'),
        ),
        expect: () => [
          isA<GardenLoading>(),
          isA<GardenLoaded>().having(
            (s) => s.plants,
            'plants',
            isEmpty,
          ),
        ],
      );

      blocTest<GardenBloc, GardenState>(
        'emits [GardenLoading, GardenError] when repository throws',
        build: () => GardenBloc(repo: mockRepo),
        setUp: () {
          when(() => mockRepo.getGarden())
              .thenThrow(Exception('Network error'));
        },
        act: (bloc) => bloc.add(
          const LoadGardenRequested(studentUid: 'uid-student'),
        ),
        expect: () => [
          isA<GardenLoading>(),
          isA<GardenError>().having(
            (s) => s.message,
            'message',
            contains('Network error'),
          ),
        ],
      );

      blocTest<GardenBloc, GardenState>(
        'emits correct mastery percent on loaded plants',
        build: () => GardenBloc(repo: mockRepo),
        setUp: () {
          when(() => mockRepo.getGarden())
              .thenAnswer((_) async => _fakePlants());
        },
        act: (bloc) => bloc.add(
          const LoadGardenRequested(studentUid: 'uid-student'),
        ),
        verify: (bloc) {
          final loaded = bloc.state as GardenLoaded;
          expect(loaded.plants[0].masteryPercent, 65.0);
          expect(loaded.plants[1].masteryPercent, 30.0);
        },
      );
    });
  });
}
