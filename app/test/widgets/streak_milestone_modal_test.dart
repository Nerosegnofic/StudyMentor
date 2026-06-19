// test/widgets/streak_milestone_modal_test.dart
//
// Widget tests for StreakMilestoneModal.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:studymentor/l10n/app_localizations.dart';
import 'package:studymentor/src/presentation/widgets/gamification/streak_milestone_modal.dart';

Widget _wrapWithNav({required Widget Function(BuildContext) builder}) =>
    MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(builder: builder),
    );

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<void> openModal(
    WidgetTester tester, {
    required int milestoneDays,
    required int coinReward,
    required int currentStreak,
  }) async {
    await tester.pumpWidget(_wrapWithNav(builder: (ctx) {
      return ElevatedButton(
        onPressed: () => StreakMilestoneModal.show(
          ctx,
          milestoneDays: milestoneDays,
          coinReward: coinReward,
          currentStreak: currentStreak,
        ),
        child: const Text('Open'),
      );
    }));
    await tester.tap(find.text('Open'));
    await tester.pump(const Duration(milliseconds: 600));
  }

  group('StreakMilestoneModal', () {
    testWidgets('3-day milestone shows "On a Roll!"', (tester) async {
      await openModal(tester,
          milestoneDays: 3, coinReward: 50, currentStreak: 3);
      expect(find.text('On a Roll!'), findsOneWidget);
    });

    testWidgets('7-day milestone shows "Week Warrior!"', (tester) async {
      await openModal(tester,
          milestoneDays: 7, coinReward: 100, currentStreak: 7);
      expect(find.text('Week Warrior!'), findsOneWidget);
    });

    testWidgets('30-day milestone shows "Monthly Master!"', (tester) async {
      await openModal(tester,
          milestoneDays: 30, coinReward: 300, currentStreak: 30);
      expect(find.text('Monthly Master!'), findsOneWidget);
    });

    testWidgets('shows coin reward amount', (tester) async {
      await openModal(tester,
          milestoneDays: 7, coinReward: 100, currentStreak: 7);
      expect(find.text('+100 Coins'), findsOneWidget);
    });

    testWidgets('shows streak description text', (tester) async {
      await openModal(tester,
          milestoneDays: 7, coinReward: 100, currentStreak: 7);
      expect(
        find.textContaining('You hit a 7-day learning streak!'),
        findsOneWidget,
      );
    });

    testWidgets('Awesome! button is present', (tester) async {
      await openModal(tester,
          milestoneDays: 3, coinReward: 50, currentStreak: 3);
      expect(find.text('Awesome!'), findsOneWidget);
    });

    testWidgets('tapping Awesome! closes the dialog', (tester) async {
      // Use a tall viewport so the dialog fits without overflow.
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await openModal(tester,
          milestoneDays: 3, coinReward: 50, currentStreak: 3);
      expect(find.text('Awesome!'), findsOneWidget);

      await tester.tap(find.text('Awesome!'));
      await tester.pumpAndSettle();

      expect(find.text('Awesome!'), findsNothing);
      expect(find.text('Open'), findsOneWidget);
    });

    testWidgets('unknown milestone days shows "Streak Milestone!"',
        (tester) async {
      await openModal(tester,
          milestoneDays: 100, coinReward: 1000, currentStreak: 100);
      expect(find.text('Streak Milestone!'), findsOneWidget);
    });
  });
}
