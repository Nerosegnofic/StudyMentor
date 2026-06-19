// test/widgets/quiz_history_card_test.dart
//
// Widget tests for QuizHistoryCard — collapsed/expanded state, pass/fail icon,
// question circles. Does NOT test the question-detail bottom sheet since that
// requires SubjectDetailBloc state with cached question data.

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:studymentor/l10n/app_localizations.dart';
import 'package:studymentor/src/bloc/subject_detail/subject_detail_bloc.dart';
import 'package:studymentor/src/bloc/subject_detail/subject_detail_event.dart';
import 'package:studymentor/src/bloc/subject_detail/subject_detail_state.dart';
import 'package:studymentor/src/presentation/widgets/quiz_history_card.dart';

class MockSubjectDetailBloc
    extends MockBloc<SubjectDetailEvent, SubjectDetailState>
    implements SubjectDetailBloc {}

Widget _wrap(Widget child, SubjectDetailBloc bloc) => MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: BlocProvider<SubjectDetailBloc>.value(
          value: bloc,
          child: child,
        ),
      ),
    );

QuizHistoryCard _passedCard() => const QuizHistoryCard(
      quizAttemptId: 'attempt1',
      time: 'Today at 10:00 AM',
      tag: 'Math',
      score: '8/10',
      duration: '12 min',
      passed: true,
      totalQuestions: 10,
      correctAnswers: [1, 2, 3, 4, 5, 6, 7, 8],
    );

QuizHistoryCard _failedCard() => const QuizHistoryCard(
      quizAttemptId: 'attempt2',
      time: 'Yesterday at 3:00 PM',
      tag: 'English',
      score: '3/10',
      duration: '8 min',
      passed: false,
      totalQuestions: 10,
      correctAnswers: [1, 2, 3],
    );

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  late MockSubjectDetailBloc mockBloc;

  setUp(() {
    mockBloc = MockSubjectDetailBloc();
    when(() => mockBloc.state).thenReturn(SubjectDetailInitial());
  });

  group('QuizHistoryCard — collapsed', () {
    testWidgets('renders without throwing', (tester) async {
      await tester.pumpWidget(_wrap(_passedCard(), mockBloc));
      await tester.pump();
      expect(find.byType(QuizHistoryCard), findsOneWidget);
    });

    testWidgets('shows time and score in collapsed state', (tester) async {
      await tester.pumpWidget(_wrap(_passedCard(), mockBloc));
      await tester.pump();
      expect(find.text('Today at 10:00 AM'), findsOneWidget);
      expect(find.text('8/10'), findsOneWidget);
    });

    testWidgets('shows duration in collapsed state', (tester) async {
      await tester.pumpWidget(_wrap(_passedCard(), mockBloc));
      await tester.pump();
      expect(find.text('12 min'), findsOneWidget);
    });

    testWidgets('passed quiz shows check_circle icon', (tester) async {
      await tester.pumpWidget(_wrap(_passedCard(), mockBloc));
      await tester.pump();
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('failed quiz shows cancel icon', (tester) async {
      await tester.pumpWidget(_wrap(_failedCard(), mockBloc));
      await tester.pump();
      expect(find.byIcon(Icons.cancel), findsOneWidget);
    });

    testWidgets('collapsed state shows expand_more chevron', (tester) async {
      await tester.pumpWidget(_wrap(_passedCard(), mockBloc));
      await tester.pump();
      expect(find.byIcon(Icons.expand_more), findsOneWidget);
    });
  });

  group('QuizHistoryCard — expanded', () {
    testWidgets('tapping card header toggles to expanded', (tester) async {
      await tester.pumpWidget(_wrap(_passedCard(), mockBloc));
      await tester.pump();

      // Tap the time text to expand.
      await tester.tap(find.text('Today at 10:00 AM'));
      await tester.pump();

      // Chevron flips to expand_less.
      expect(find.byIcon(Icons.expand_less), findsOneWidget);
    });

    testWidgets('expanded state shows question number circles', (tester) async {
      await tester.pumpWidget(_wrap(_passedCard(), mockBloc));
      await tester.pump();

      await tester.tap(find.text('Today at 10:00 AM'));
      await tester.pump();

      // 10 total questions → 10 numbered circles (each shows its number).
      expect(find.text('1'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
    });

    testWidgets('correct answers show green circles, wrong show red',
        (tester) async {
      // correctAnswers: [1, 2, 3] — questions 4–10 are wrong.
      await tester.pumpWidget(_wrap(_failedCard(), mockBloc));
      await tester.pump();

      await tester.tap(find.text('Yesterday at 3:00 PM'));
      await tester.pump();

      final circles = tester.widgetList<Container>(
        find.descendant(
          of: find.byType(Wrap),
          matching: find.byType(Container),
        ),
      );

      // Verify there are exactly 10 circles (one per question).
      expect(circles.length, 10);
    });

    testWidgets('tapping expanded header collapses back', (tester) async {
      await tester.pumpWidget(_wrap(_passedCard(), mockBloc));
      await tester.pump();

      // Expand.
      await tester.tap(find.text('Today at 10:00 AM'));
      await tester.pump();
      expect(find.byIcon(Icons.expand_less), findsOneWidget);

      // Collapse.
      await tester.tap(find.text('Today at 10:00 AM'));
      await tester.pump();
      expect(find.byIcon(Icons.expand_more), findsOneWidget);
    });
  });
}
