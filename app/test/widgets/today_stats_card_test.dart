// test/widgets/today_stats_card_test.dart
//
// Widget tests for TodayStatsCard — pure display widget, no blocs.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:studymentor/l10n/app_localizations.dart';
import 'package:studymentor/src/domain/models/report_models.dart';
import 'package:studymentor/src/presentation/widgets/student_home/today_stats_card.dart';

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  const emptySegments = <SubjectQuestionCount>[];

  group('TodayStatsCard', () {
    testWidgets('renders without throwing', (tester) async {
      await tester.pumpWidget(_wrap(TodayStatsCard(
        questionsBySubject: emptySegments,
        studyTime: Duration.zero,
        streak: 0,
        accuracyPercent: 0,
      )));
      await tester.pump();
      expect(find.byType(TodayStatsCard), findsOneWidget);
    });

    testWidgets('shows "Today" heading', (tester) async {
      await tester.pumpWidget(_wrap(TodayStatsCard(
        questionsBySubject: emptySegments,
        studyTime: Duration.zero,
        streak: 5,
        accuracyPercent: 75,
      )));
      await tester.pump();
      expect(find.text('Today'), findsOneWidget);
    });

    testWidgets('shows streak count', (tester) async {
      await tester.pumpWidget(_wrap(TodayStatsCard(
        questionsBySubject: emptySegments,
        studyTime: Duration.zero,
        streak: 7,
        accuracyPercent: 80,
      )));
      await tester.pump();
      expect(find.text('7'), findsOneWidget);
    });

    testWidgets('shows accuracy percentage', (tester) async {
      await tester.pumpWidget(_wrap(TodayStatsCard(
        questionsBySubject: emptySegments,
        studyTime: Duration.zero,
        streak: 0,
        accuracyPercent: 85,
      )));
      await tester.pump();
      expect(find.text('85%'), findsOneWidget);
    });

    testWidgets('shows "Studied" label', (tester) async {
      await tester.pumpWidget(_wrap(TodayStatsCard(
        questionsBySubject: emptySegments,
        studyTime: const Duration(minutes: 30),
        streak: 0,
        accuracyPercent: 0,
      )));
      await tester.pump();
      expect(find.text('Studied'), findsOneWidget);
    });

    testWidgets('formats study time under 60 minutes as "Xm"', (tester) async {
      await tester.pumpWidget(_wrap(TodayStatsCard(
        questionsBySubject: emptySegments,
        studyTime: const Duration(minutes: 25),
        streak: 0,
        accuracyPercent: 0,
      )));
      await tester.pump();
      expect(find.text('25m'), findsOneWidget);
    });

    testWidgets('formats study time ≥ 60 minutes as "Xh Ym"', (tester) async {
      await tester.pumpWidget(_wrap(TodayStatsCard(
        questionsBySubject: emptySegments,
        studyTime: const Duration(minutes: 65),
        streak: 0,
        accuracyPercent: 0,
      )));
      await tester.pump();
      expect(find.text('1h 5m'), findsOneWidget);
    });

    testWidgets('formats exact hours as "Xh" (no minutes part)', (tester) async {
      await tester.pumpWidget(_wrap(TodayStatsCard(
        questionsBySubject: emptySegments,
        studyTime: const Duration(hours: 2),
        streak: 0,
        accuracyPercent: 0,
      )));
      await tester.pump();
      expect(find.text('2h'), findsOneWidget);
    });

    testWidgets('formats zero study time as "0m"', (tester) async {
      await tester.pumpWidget(_wrap(TodayStatsCard(
        questionsBySubject: emptySegments,
        studyTime: Duration.zero,
        streak: 0,
        accuracyPercent: 0,
      )));
      await tester.pump();
      expect(find.text('0m'), findsOneWidget);
    });

    testWidgets('shows "Day streak" and "Accuracy" labels', (tester) async {
      await tester.pumpWidget(_wrap(TodayStatsCard(
        questionsBySubject: emptySegments,
        studyTime: Duration.zero,
        streak: 3,
        accuracyPercent: 60,
      )));
      await tester.pump();
      expect(find.text('Day Streak'), findsOneWidget);
      expect(find.text('Accuracy'), findsOneWidget);
    });

    testWidgets('renders with subject segments without throwing', (tester) async {
      await tester.pumpWidget(_wrap(TodayStatsCard(
        questionsBySubject: const [
          SubjectQuestionCount(subjectName: 'Math', questions: 5),
          SubjectQuestionCount(subjectName: 'English', questions: 3),
        ],
        studyTime: const Duration(minutes: 40),
        streak: 4,
        accuracyPercent: 70,
      )));
      await tester.pump();
      expect(find.byType(TodayStatsCard), findsOneWidget);
    });
  });
}
