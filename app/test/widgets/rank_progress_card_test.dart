// test/widgets/rank_progress_card_test.dart
//
// Widget tests for RankProgressCard — pure display widget, no blocs.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:studymentor/src/data/constants/gamification_levels.dart';
import 'package:studymentor/src/presentation/widgets/student_home/rank_progress_card.dart';

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: Center(child: child)));

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('RankProgressCard', () {
    testWidgets('renders without throwing', (tester) async {
      await tester.pumpWidget(
        _wrap(const RankProgressCard(xpTotal: 0, currentLevel: 1)),
      );
      await tester.pump();
      expect(find.byType(RankProgressCard), findsOneWidget);
    });

    testWidgets('shows current level as a rank badge', (tester) async {
      await tester.pumpWidget(
        _wrap(const RankProgressCard(xpTotal: 0, currentLevel: 1)),
      );
      await tester.pump();
      expect(find.text('Lv. 1'), findsOneWidget);
    });

    testWidgets('shows "Lv. X" badge', (tester) async {
      await tester.pumpWidget(
        _wrap(const RankProgressCard(xpTotal: 200, currentLevel: 2)),
      );
      await tester.pump();
      expect(find.text('Lv. 2'), findsOneWidget);
    });

    testWidgets('shows "Next:" label when not at max level', (tester) async {
      await tester.pumpWidget(
        _wrap(const RankProgressCard(xpTotal: 0, currentLevel: 1)),
      );
      await tester.pump();
      expect(find.textContaining('Next:'), findsOneWidget);
    });

    testWidgets('shows XP progress text (xpTotal / nextXp)', (tester) async {
      final nextXp = kGamificationLevels[1].xpRequired;
      await tester.pumpWidget(
        _wrap(RankProgressCard(xpTotal: 100, currentLevel: 1)),
      );
      await tester.pump();
      expect(find.text('100 / $nextXp XP'), findsOneWidget);
    });

    testWidgets('shows LinearProgressIndicator', (tester) async {
      await tester.pumpWidget(
        _wrap(const RankProgressCard(xpTotal: 100, currentLevel: 1)),
      );
      await tester.pump();
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('progress value is between 0 and 1', (tester) async {
      await tester.pumpWidget(
        _wrap(const RankProgressCard(xpTotal: 100, currentLevel: 1)),
      );
      await tester.pump();
      final bar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(bar.value, greaterThanOrEqualTo(0.0));
      expect(bar.value, lessThanOrEqualTo(1.0));
    });

    testWidgets('max level shows "Top rank" subtitle', (tester) async {
      final maxLevel = kGamificationLevels.length;
      await tester.pumpWidget(
        _wrap(RankProgressCard(xpTotal: 9999, currentLevel: maxLevel)),
      );
      await tester.pump();
      expect(find.text('Top rank'), findsOneWidget);
    });

    testWidgets('max level shows "You reached the top" text', (tester) async {
      final maxLevel = kGamificationLevels.length;
      await tester.pumpWidget(
        _wrap(RankProgressCard(xpTotal: 9999, currentLevel: maxLevel)),
      );
      await tester.pump();
      expect(find.text('You reached the top — amazing!'), findsOneWidget);
    });

    testWidgets('max level shows trophy icon', (tester) async {
      final maxLevel = kGamificationLevels.length;
      await tester.pumpWidget(
        _wrap(RankProgressCard(xpTotal: 9999, currentLevel: maxLevel)),
      );
      await tester.pump();
      expect(find.byIcon(Icons.emoji_events_rounded), findsOneWidget);
    });

    testWidgets('non-max level shows auto_awesome icon', (tester) async {
      await tester.pumpWidget(
        _wrap(const RankProgressCard(xpTotal: 0, currentLevel: 1)),
      );
      await tester.pump();
      expect(find.byIcon(Icons.auto_awesome_rounded), findsOneWidget);
    });

    testWidgets('renders all valid levels without throwing', (tester) async {
      for (int level = 1; level <= kGamificationLevels.length; level++) {
        await tester.pumpWidget(
          _wrap(RankProgressCard(xpTotal: 0, currentLevel: level)),
        );
        await tester.pump();
        expect(find.byType(RankProgressCard), findsOneWidget);
      }
    });
  });
}
