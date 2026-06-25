// test/screens/subject_detail_screen_test.dart
//
// Widget tests for SubjectDetailScreen.
// The screen's `repository` parameter allows injecting a mock to avoid
// the Firebase singleton (AiEngineRepository.instance).

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:studymentor/l10n/app_localizations.dart';
import 'package:studymentor/src/bloc/auth/auth_bloc.dart';
import 'package:studymentor/src/bloc/auth/auth_event.dart';
import 'package:studymentor/src/bloc/auth/auth_state.dart';
import 'package:studymentor/src/bloc/garden/garden_bloc.dart';
import 'package:studymentor/src/bloc/garden/garden_event.dart';
import 'package:studymentor/src/bloc/garden/garden_state.dart';
import 'package:studymentor/src/bloc/gamification/gamification_bloc.dart';
import 'package:studymentor/src/bloc/gamification/gamification_event.dart';
import 'package:studymentor/src/bloc/gamification/gamification_state.dart';
import 'package:studymentor/src/data/repositories/ai_engine_repository.dart';
import 'package:studymentor/src/data/catalog/document_models.dart';
import 'package:studymentor/src/domain/models/skill_detail_model.dart';
import 'package:studymentor/src/presentation/screens/student/subject_detail_screen.dart';

class MockAiEngineRepository extends Mock implements AiEngineRepository {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

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
  late MockAuthBloc mockAuthBloc;
  late MockGardenBloc mockGardenBloc;
  late MockGamificationBloc mockGamificationBloc;

  setUp(() {
    mockRepo = MockAiEngineRepository();
    mockAuthBloc = MockAuthBloc();
    mockGardenBloc = MockGardenBloc();
    mockGamificationBloc = MockGamificationBloc();

    when(() => mockAuthBloc.state).thenReturn(AuthInitial());
    when(() => mockGardenBloc.state).thenReturn(const GardenLoaded(plants: []));
    when(() => mockGamificationBloc.state).thenReturn(GamificationInitial());

    // Return empty skills list by default.
    when(() => mockRepo.getSubjectSkills(any()))
        .thenAnswer((_) async => <SkillDetailModel>[]);
    // getSubjectsStatus is also called; return empty list.
    when(() => mockRepo.getSubjectsStatus())
        .thenAnswer((_) async => <SubjectStatus>[]);
  });

  Widget wrap(Widget child) => MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: mockAuthBloc),
            BlocProvider<GardenBloc>.value(value: mockGardenBloc),
            BlocProvider<GamificationBloc>.value(value: mockGamificationBloc),
          ],
          child: child,
        ),
      );

  group('SubjectDetailScreen', () {
    testWidgets('renders without throwing', (tester) async {
      await tester.pumpWidget(wrap(
        SubjectDetailScreen(
          studentUid: 'uid_test',
          subjectId: 1,
          subjectName: 'Math',
          masteryPercent: 0.65,
          repository: mockRepo,
        ),
      ));
      await tester.pump();

      expect(find.byType(SubjectDetailScreen), findsOneWidget);
    });

    testWidgets('shows subject name in the screen', (tester) async {
      await tester.pumpWidget(wrap(
        SubjectDetailScreen(
          studentUid: 'uid_test',
          subjectId: 2,
          subjectName: 'Science',
          masteryPercent: 0.40,
          repository: mockRepo,
        ),
      ));
      await tester.pump();

      expect(find.textContaining('Science'), findsWidgets);
    });

    testWidgets('calls getSubjectSkills with correct subjectId', (tester) async {
      await tester.pumpWidget(wrap(
        SubjectDetailScreen(
          studentUid: 'uid_test',
          subjectId: 42,
          subjectName: 'English',
          masteryPercent: 0.80,
          repository: mockRepo,
        ),
      ));
      await tester.pump();

      verify(() => mockRepo.getSubjectSkills(42)).called(1);
    });
  });
}
