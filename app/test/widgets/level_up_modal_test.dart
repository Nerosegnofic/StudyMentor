// test/widgets/level_up_modal_test.dart
//
// Widget tests for LevelUpCelebrationScreen.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:studymentor/l10n/app_localizations.dart';
import 'package:studymentor/src/domain/models/gamification_models.dart';
import 'package:studymentor/src/presentation/widgets/gamification/level_up_modal.dart';

const _testLevel = LevelModel(
  levelNumber: 5,
  xpRequired: 1050,
);

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('LevelUpCelebrationScreen', () {
    testWidgets('shows the level number in the glow ring', (tester) async {
      await tester.pumpWidget(
          _wrap(LevelUpCelebrationScreen(newLevel: _testLevel)));
      await tester.pump(const Duration(milliseconds: 700));

      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('shows the level name pill', (tester) async {
      await tester.pumpWidget(
          _wrap(LevelUpCelebrationScreen(newLevel: _testLevel)));
      await tester.pump(const Duration(milliseconds: 700));

      expect(find.text('Scholar'), findsOneWidget);
    });

    testWidgets('shows the Level Up title', (tester) async {
      await tester.pumpWidget(
          _wrap(LevelUpCelebrationScreen(newLevel: _testLevel)));
      await tester.pump(const Duration(milliseconds: 700));

      expect(find.text('🎉 Level Up!'), findsOneWidget);
    });

    testWidgets('shows subtitle with level number', (tester) async {
      await tester.pumpWidget(
          _wrap(LevelUpCelebrationScreen(newLevel: _testLevel)));
      await tester.pump(const Duration(milliseconds: 700));

      expect(find.textContaining('You reached Level 5!'), findsOneWidget);
    });

    testWidgets('Awesome! button is present', (tester) async {
      await tester.pumpWidget(
          _wrap(LevelUpCelebrationScreen(newLevel: _testLevel)));
      await tester.pump(const Duration(milliseconds: 700));

      expect(find.text('Awesome!'), findsOneWidget);
    });

    testWidgets('tapping Awesome! pops the screen', (tester) async {
      // Push via Navigator so pop() actually works.
      final navigatorKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(MaterialApp(
        navigatorKey: navigatorKey,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(builder: (ctx) {
          return ElevatedButton(
            onPressed: () => LevelUpCelebrationScreen.show(ctx, _testLevel),
            child: const Text('Open'),
          );
        }),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle(const Duration(milliseconds: 700));

      expect(find.text('Awesome!'), findsOneWidget);

      await tester.tap(find.text('Awesome!'));
      await tester.pumpAndSettle();

      expect(find.text('Open'), findsOneWidget);
    });
  });
}
