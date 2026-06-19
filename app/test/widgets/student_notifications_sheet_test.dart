// test/widgets/student_notifications_sheet_test.dart
//
// Widget tests for StudentNotificationsSheet.

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:studymentor/l10n/app_localizations.dart';
import 'package:studymentor/src/bloc/notifications/notifications_bloc.dart';
import 'package:studymentor/src/bloc/notifications/notifications_event.dart';
import 'package:studymentor/src/bloc/notifications/notifications_state.dart';
import 'package:studymentor/src/domain/models/notification_model.dart';
import 'package:studymentor/src/presentation/widgets/student_home/student_notifications_sheet.dart';

class MockNotificationsBloc
    extends MockBloc<NotificationsEvent, NotificationsState>
    implements NotificationsBloc {}

Widget _wrap(Widget child, NotificationsBloc bloc) => MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: BlocProvider<NotificationsBloc>.value(
          value: bloc,
          child: child,
        ),
      ),
    );

NotificationModel _fakeNotif({
  String id = 'n1',
  NotificationType type = NotificationType.streakAchieved,
  bool isRead = false,
}) =>
    NotificationModel(
      id: id,
      parentUid: 'parent1',
      studentUid: 'student1',
      type: type,
      title: 'Test Title',
      subtitle: 'Test subtitle text.',
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      isRead: isRead,
    );

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    registerFallbackValue(const MarkAllNotificationsReadRequested(''));
  });

  late MockNotificationsBloc mockBloc;

  setUp(() {
    mockBloc = MockNotificationsBloc();
  });

  group('StudentNotificationsSheet', () {
    testWidgets('renders without throwing in initial state', (tester) async {
      when(() => mockBloc.state).thenReturn(NotificationsInitial());
      await tester.pumpWidget(
        _wrap(
          const StudentNotificationsSheet(studentUid: 'student1'),
          mockBloc,
        ),
      );
      await tester.pump();
      expect(find.byType(StudentNotificationsSheet), findsOneWidget);
    });

    testWidgets('shows "You\'re All Caught Up" when notification list is empty',
        (tester) async {
      when(() => mockBloc.state).thenReturn(NotificationsLoaded(const []));
      await tester.pumpWidget(
        _wrap(
          const StudentNotificationsSheet(studentUid: 'student1'),
          mockBloc,
        ),
      );
      await tester.pump();
      expect(find.text("You're All Caught Up"), findsOneWidget);
    });

    testWidgets('shows notification title when list has items', (tester) async {
      when(() => mockBloc.state).thenReturn(
        NotificationsLoaded([_fakeNotif()]),
      );
      await tester.pumpWidget(
        _wrap(
          const StudentNotificationsSheet(studentUid: 'student1'),
          mockBloc,
        ),
      );
      await tester.pump();
      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Test subtitle text.'), findsOneWidget);
    });

    testWidgets('shows multiple notifications', (tester) async {
      when(() => mockBloc.state).thenReturn(
        NotificationsLoaded([
          _fakeNotif(id: 'n1'),
          _fakeNotif(id: 'n2', type: NotificationType.needsWork),
        ]),
      );
      await tester.pumpWidget(
        _wrap(
          const StudentNotificationsSheet(studentUid: 'student1'),
          mockBloc,
        ),
      );
      await tester.pump();
      expect(find.text('Test Title'), findsNWidgets(2));
    });

    testWidgets(
        'tapping "Mark all as read" dispatches MarkAllNotificationsReadRequested',
        (tester) async {
      when(() => mockBloc.state).thenReturn(
        NotificationsLoaded([_fakeNotif(isRead: false)]),
      );
      await tester.pumpWidget(
        _wrap(
          const StudentNotificationsSheet(studentUid: 'student1'),
          mockBloc,
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Mark all as read'));
      await tester.pump();

      verify(() => mockBloc.add(const MarkAllNotificationsReadRequested('student1')))
          .called(1);
    });

    testWidgets('shows time label for recent notifications', (tester) async {
      when(() => mockBloc.state).thenReturn(
        NotificationsLoaded([_fakeNotif()]),
      );
      await tester.pumpWidget(
        _wrap(
          const StudentNotificationsSheet(studentUid: 'student1'),
          mockBloc,
        ),
      );
      await tester.pump();
      // Notification was created 5 minutes ago — should show "5m ago".
      expect(find.textContaining('m ago'), findsOneWidget);
    });
  });
}
