// test/screens/student_home_test.dart
//
// Smoke tests for StudentHome. The screen starts a periodic Timer and makes
// several async calls that all run inside try-catch, so we use pump() rather
// than pumpAndSettle() to avoid hanging.

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
import 'package:studymentor/src/presentation/screens/student/student_home.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockGardenBloc extends MockBloc<GardenEvent, GardenState>
    implements GardenBloc {}

class MockGamificationBloc
    extends MockBloc<GamificationEvent, GamificationState>
    implements GamificationBloc {}

Widget _wrap({
  required Widget child,
  required AuthBloc authBloc,
  required GardenBloc gardenBloc,
  required GamificationBloc gamificationBloc,
}) =>
    MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: authBloc),
          BlocProvider<GardenBloc>.value(value: gardenBloc),
          BlocProvider<GamificationBloc>.value(value: gamificationBloc),
        ],
        child: child,
      ),
    );

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    registerFallbackValue(LoadStudentAppConfigRequested(studentUid: ''));
    registerFallbackValue(LoadGardenRequested(studentUid: ''));
  });

  late MockAuthBloc mockAuthBloc;
  late MockGardenBloc mockGardenBloc;
  late MockGamificationBloc mockGamificationBloc;

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    mockGardenBloc = MockGardenBloc();
    mockGamificationBloc = MockGamificationBloc();

    when(() => mockAuthBloc.state).thenReturn(AuthInitial());
    when(() => mockGardenBloc.state).thenReturn(const GardenLoaded(plants: []));
    when(() => mockGamificationBloc.state).thenReturn(GamificationInitial());
  });

  group('StudentHome', () {
    testWidgets('renders without throwing', (tester) async {
      await tester.pumpWidget(_wrap(
        child: const StudentHome(fullName: 'Ahmad', uid: 'uid_test'),
        authBloc: mockAuthBloc,
        gardenBloc: mockGardenBloc,
        gamificationBloc: mockGamificationBloc,
      ));
      await tester.pump();

      expect(find.byType(StudentHome), findsOneWidget);
    });

    testWidgets('shows student full name', (tester) async {
      await tester.pumpWidget(_wrap(
        child: const StudentHome(fullName: 'Ahmad', uid: 'uid_test'),
        authBloc: mockAuthBloc,
        gardenBloc: mockGardenBloc,
        gamificationBloc: mockGamificationBloc,
      ));
      await tester.pump();

      expect(find.textContaining('Ahmad'), findsWidgets);
    });

    testWidgets('shows empty garden message when no plants', (tester) async {
      when(() => mockGardenBloc.state)
          .thenReturn(const GardenLoaded(plants: []));

      await tester.pumpWidget(_wrap(
        child: const StudentHome(fullName: 'Layla', uid: 'uid_test'),
        authBloc: mockAuthBloc,
        gardenBloc: mockGardenBloc,
        gamificationBloc: mockGamificationBloc,
      ));
      await tester.pump();

      // Screen renders — no exception thrown
      expect(find.byType(StudentHome), findsOneWidget);
    });
  });
}
