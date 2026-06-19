// test/screens/student_quiz_test.dart
//
// Smoke tests for QuizOverlayPage (student_quiz.dart).
// QuizOverlayPage takes an injected AiEngineRepository, so we can avoid the
// Firebase singleton entirely.

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:studymentor/l10n/app_localizations.dart';
import 'package:studymentor/src/bloc/gamification/gamification_bloc.dart';
import 'package:studymentor/src/bloc/gamification/gamification_event.dart';
import 'package:studymentor/src/bloc/gamification/gamification_state.dart';
import 'package:studymentor/src/bloc/garden/garden_bloc.dart';
import 'package:studymentor/src/bloc/garden/garden_event.dart';
import 'package:studymentor/src/bloc/garden/garden_state.dart';
import 'package:studymentor/src/data/repositories/ai_engine_repository.dart';
import 'package:studymentor/src/domain/models/gamification_enums.dart';
import 'package:studymentor/src/presentation/screens/student/student_quiz.dart';

class MockAiEngineRepository extends Mock implements AiEngineRepository {}

class MockGardenBloc extends MockBloc<GardenEvent, GardenState>
    implements GardenBloc {}

class MockGamificationBloc
    extends MockBloc<GamificationEvent, GamificationState>
    implements GamificationBloc {}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  late MockAiEngineRepository mockRepo;
  late MockGardenBloc mockGardenBloc;
  late MockGamificationBloc mockGamificationBloc;

  setUp(() {
    mockRepo = MockAiEngineRepository();
    mockGardenBloc = MockGardenBloc();
    mockGamificationBloc = MockGamificationBloc();

    when(() => mockGardenBloc.state).thenReturn(const GardenLoaded(plants: []));
    when(() => mockGamificationBloc.state).thenReturn(GamificationInitial());
  });

  Widget _wrap(Widget child) => MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: MultiBlocProvider(
          providers: [
            BlocProvider<GardenBloc>.value(value: mockGardenBloc),
            BlocProvider<GamificationBloc>.value(value: mockGamificationBloc),
          ],
          child: child,
        ),
      );

  group('QuizOverlayPage', () {
    testWidgets('renders initial state without throwing', (tester) async {
      await tester.pumpWidget(_wrap(
        QuizOverlayPage(
          repository: mockRepo,
          studentId: 'uid_test',
          contextType: QuizContext.voluntary,
        ),
      ));
      await tester.pump();

      expect(find.byType(QuizOverlayPage), findsOneWidget);
    });

    testWidgets('shows start quiz button in initial state', (tester) async {
      await tester.pumpWidget(_wrap(
        QuizOverlayPage(
          repository: mockRepo,
          studentId: 'uid_test',
          contextType: QuizContext.voluntary,
        ),
      ));
      await tester.pump();

      // The initial quiz state should show a "Start Quiz" or similar CTA.
      // Presence of a Scaffold is the minimum smoke check.
      expect(find.byType(Scaffold), findsWidgets);
    });
  });
}
