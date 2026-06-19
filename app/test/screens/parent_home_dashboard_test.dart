// test/screens/parent_home_dashboard_test.dart
//
// Widget tests for ParentHomeDashboard.

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
import 'package:studymentor/src/bloc/students/students_bloc.dart';
import 'package:studymentor/src/bloc/students/students_event.dart';
import 'package:studymentor/src/bloc/students/students_state.dart';
import 'package:studymentor/src/bloc/snapshot/snapshot_bloc.dart';
import 'package:studymentor/src/bloc/snapshot/snapshot_event.dart';
import 'package:studymentor/src/bloc/snapshot/snapshot_state.dart';
import 'package:studymentor/src/bloc/reports/reports_bloc.dart';
import 'package:studymentor/src/bloc/reports/reports_event.dart';
import 'package:studymentor/src/bloc/reports/reports_state.dart';
import 'package:studymentor/src/bloc/ai_summary/ai_summary_bloc.dart';
import 'package:studymentor/src/bloc/ai_summary/ai_summary_event.dart';
import 'package:studymentor/src/bloc/ai_summary/ai_summary_state.dart';
import 'package:studymentor/src/bloc/notifications/notifications_bloc.dart';
import 'package:studymentor/src/bloc/notifications/notifications_event.dart';
import 'package:studymentor/src/bloc/notifications/notifications_state.dart';
import 'package:studymentor/src/domain/models/student_model.dart';
import 'package:studymentor/src/presentation/screens/parent/parent_home_dashboard.dart';

class MockStudentsBloc extends MockBloc<StudentsEvent, StudentsState>
    implements StudentsBloc {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockSnapshotBloc extends MockBloc<SnapshotEvent, SnapshotState>
    implements SnapshotBloc {}

class MockReportsBloc extends MockBloc<ReportsEvent, ReportsState>
    implements ReportsBloc {}

class MockAiSummaryBloc extends MockBloc<AiSummaryEvent, AiSummaryState>
    implements AiSummaryBloc {}

class MockNotificationsBloc
    extends MockBloc<NotificationsEvent, NotificationsState>
    implements NotificationsBloc {}

final _testStudent = StudentModel(
  uid: 'student_uid_1',
  fullName: 'Nour',
  email: 'nour@example.com',
  gradeLevel: 5,
  isEmailVerified: true,
);

Widget _wrap({
  required Widget child,
  required StudentsBloc studentsBloc,
  required AuthBloc authBloc,
  required SnapshotBloc snapshotBloc,
  required ReportsBloc reportsBloc,
  required AiSummaryBloc aiSummaryBloc,
  required NotificationsBloc notificationsBloc,
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
          BlocProvider<StudentsBloc>.value(value: studentsBloc),
          BlocProvider<AuthBloc>.value(value: authBloc),
          BlocProvider<SnapshotBloc>.value(value: snapshotBloc),
          BlocProvider<ReportsBloc>.value(value: reportsBloc),
          BlocProvider<AiSummaryBloc>.value(value: aiSummaryBloc),
          BlocProvider<NotificationsBloc>.value(value: notificationsBloc),
        ],
        child: child,
      ),
    );

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    registerFallbackValue(
        const LoadStudentsRequested(parentUid: ''));
  });

  late MockStudentsBloc mockStudentsBloc;
  late MockAuthBloc mockAuthBloc;
  late MockSnapshotBloc mockSnapshotBloc;
  late MockReportsBloc mockReportsBloc;
  late MockAiSummaryBloc mockAiSummaryBloc;
  late MockNotificationsBloc mockNotificationsBloc;

  setUp(() {
    mockStudentsBloc = MockStudentsBloc();
    mockAuthBloc = MockAuthBloc();
    mockSnapshotBloc = MockSnapshotBloc();
    mockReportsBloc = MockReportsBloc();
    mockAiSummaryBloc = MockAiSummaryBloc();
    mockNotificationsBloc = MockNotificationsBloc();

    when(() => mockStudentsBloc.state)
        .thenReturn(StudentsLoaded(const []));
    when(() => mockAuthBloc.state).thenReturn(AuthInitial());
    when(() => mockSnapshotBloc.state).thenReturn(SnapshotInitial());
    when(() => mockReportsBloc.state).thenReturn(const ReportsState());
    when(() => mockAiSummaryBloc.state).thenReturn(AiSummaryInitial());
    when(() => mockNotificationsBloc.state).thenReturn(NotificationsInitial());
  });

  Widget _buildDashboard() => _wrap(
        child: ParentHomeDashboard(
          parentUid: 'parent_uid',
          fullName: 'Sara',
          onAddStudentPressed: () {},
        ),
        studentsBloc: mockStudentsBloc,
        authBloc: mockAuthBloc,
        snapshotBloc: mockSnapshotBloc,
        reportsBloc: mockReportsBloc,
        aiSummaryBloc: mockAiSummaryBloc,
        notificationsBloc: mockNotificationsBloc,
      );

  group('ParentHomeDashboard', () {
    testWidgets('renders without throwing in empty state', (tester) async {
      await tester.pumpWidget(_buildDashboard());
      await tester.pump();

      expect(find.byType(ParentHomeDashboard), findsOneWidget);
    });

    testWidgets('has a CustomScrollView', (tester) async {
      await tester.pumpWidget(_buildDashboard());
      await tester.pump();

      expect(find.byType(CustomScrollView), findsOneWidget);
    });

    testWidgets('contains a Scaffold', (tester) async {
      await tester.pumpWidget(_buildDashboard());
      await tester.pump();

      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('renders without crashing in StudentsLoading state',
        (tester) async {
      when(() => mockStudentsBloc.state).thenReturn(StudentsLoading());

      await tester.pumpWidget(_buildDashboard());
      await tester.pump();

      expect(find.byType(ParentHomeDashboard), findsOneWidget);
    });

    testWidgets('renders without crashing when students are loaded',
        (tester) async {
      when(() => mockStudentsBloc.state)
          .thenReturn(StudentsLoaded([_testStudent]));

      await tester.pumpWidget(_buildDashboard());
      await tester.pump();

      expect(find.byType(ParentHomeDashboard), findsOneWidget);
    });
  });
}
