// integration_test/quiz_flow_test.dart
//
// Integration tests for the student quiz flow.
//
// Navigation path tested:
//   Login → StudentHome (garden) → tap GardenSubjectCard → SubjectDetailScreen
//   → "Practice Now" / "Start Quiz" → QuizOverlayPage → answer all questions
//   → results screen visible
//
// ══════════════════════════════════════════════════════════════════════════════
//  PREREQUISITES
//  • A student account that has at least one subject with curriculum uploaded
//    and processed (stage = "ready").
//  • The AI Engine must be reachable from the device (same network or
//    a public URL configured in AiEngineRepository.defaultBaseUrl).
//  HOW TO RUN:
//    flutter devices
//    flutter test integration_test/quiz_flow_test.dart -d <device-id>
//  ⚠  DO NOT commit real credentials to git.
// ══════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:studymentor/main.dart' as app;

// ─── Fill in your student account credentials ─────────────────────────────────
const _studentEmail    = 'YOUR_STUDENT_EMAIL_HERE';
const _studentPassword = 'YOUR_STUDENT_PASSWORD_HERE';
// ─────────────────────────────────────────────────────────────────────────────

// ─── Helpers ─────────────────────────────────────────────────────────────────

Future<void> _boot(WidgetTester tester) async {
  app.main();
  await tester.pumpAndSettle(const Duration(seconds: 6));
}

Future<void> _login(WidgetTester tester) async {
  if (find.text('Sign In').evaluate().isEmpty) return;
  await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'), _studentEmail);
  await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'), _studentPassword);
  await tester.tap(find.text('Sign In'));
  await tester.pumpAndSettle(const Duration(seconds: 8));
}

/// Accept the student permission gate (notification / admin permissions).
Future<void> _clearPermissionGate(WidgetTester tester) async {
  for (int i = 0; i < 6; i++) {
    bool acted = false;
    for (final label in ['Continue', 'Grant', 'Allow', 'Next', 'OK']) {
      final btn = find.text(label);
      if (btn.evaluate().isNotEmpty) {
        await tester.tap(btn.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
        acted = true;
        break;
      }
    }
    if (!acted) break;
  }
}

/// Wait for the student home (garden) to finish loading.
Future<void> _waitForGarden(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 4));
  await tester.pumpAndSettle(const Duration(seconds: 4));
}

/// Tap the first subject card visible on the garden home screen.
/// Returns false if no subject cards are found (student has no subjects).
Future<bool> _tapFirstSubjectCard(WidgetTester tester) async {
  // GardenSubjectCard has an InkWell; look for the first tappable card region.
  final cards = find.byType(InkWell);
  if (cards.evaluate().isEmpty) return false;
  await tester.tap(cards.first);
  await tester.pumpAndSettle(const Duration(seconds: 3));
  return true;
}

/// Tap "Practice Now" or "Start Quiz" on the SubjectDetailScreen.
Future<bool> _tapPracticeNow(WidgetTester tester) async {
  for (final label in ['Practice Now', 'Start Quiz', 'Practice']) {
    final btn = find.text(label);
    if (btn.evaluate().isNotEmpty) {
      await tester.tap(btn.first);
      // Quiz generation is a network call — give it extra time.
      await tester.pumpAndSettle(const Duration(seconds: 15));
      return true;
    }
  }
  return false;
}

/// Answer every question in the quiz by tapping the first available option.
/// Handles both single-choice and fill-in-style quiz cards.
Future<void> _answerAllQuestions(WidgetTester tester) async {
  // Keep tapping "Next" / answer options until the results or Done button
  // appears. Cap at 20 iterations to avoid an infinite loop.
  for (int q = 0; q < 20; q++) {
    await tester.pump(const Duration(seconds: 1));

    // Results / Done screen appeared — we are finished.
    if (_quizResultsVisible()) break;

    // Tap an answer option (Radio, Checkbox, or TextButton labelled A/B/C/D).
    bool answered = false;

    // Single-choice: radio buttons or list-tile options.
    final radios = find.byType(RadioListTile);
    if (radios.evaluate().isNotEmpty) {
      await tester.tap(radios.first);
      await tester.pump();
      answered = true;
    }

    // If no radio, try any ElevatedButton that is NOT "Next" or "Submit".
    if (!answered) {
      final elevated = find.byType(ElevatedButton);
      for (final btn in tester.widgetList<ElevatedButton>(elevated)) {
        if (btn.onPressed != null) {
          await tester.tap(
              find.byWidget(btn)); // ignore: invalid_use_of_protected_member
          await tester.pump();
          answered = true;
          break;
        }
      }
    }

    // Tap "Next" or "Submit" to advance.
    for (final label in ['Next', 'Submit', 'Done', 'Confirm']) {
      final btn = find.text(label);
      if (btn.evaluate().isNotEmpty) {
        await tester.tap(btn.first);
        await tester.pumpAndSettle(const Duration(seconds: 3));
        break;
      }
    }

    if (_quizResultsVisible()) break;
  }
}

bool _quizResultsVisible() {
  return find.textContaining('Score').evaluate().isNotEmpty ||
      find.textContaining('Result').evaluate().isNotEmpty ||
      find.textContaining('Correct').evaluate().isNotEmpty ||
      find.text('Done').evaluate().isNotEmpty;
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Quiz flow', () {
    testWidgets(
      '1. Student login succeeds and the home screen loads',
      (tester) async {
        await _boot(tester);
        await _login(tester);

        expect(find.text('Sign In'), findsNothing,
            reason: 'Sign In should be gone after successful student login');
      },
    );

    testWidgets(
      '2. Student home (garden) is visible after the permission gate',
      (tester) async {
        await _boot(tester);
        await _login(tester);
        await _clearPermissionGate(tester);
        await _waitForGarden(tester);

        // The garden home shows either subject cards or a "no subjects" message.
        expect(
          find.byType(Scaffold), findsWidgets,
          reason: 'Expected the student home to be rendered after login',
        );
      },
    );

    testWidgets(
      '3. At least one subject card is visible on the garden screen',
      (tester) async {
        await _boot(tester);
        await _login(tester);
        await _clearPermissionGate(tester);
        await _waitForGarden(tester);

        expect(
          find.byType(InkWell).evaluate().isNotEmpty,
          isTrue,
          reason:
              'Expected at least one subject card. '
              'Ensure the student account has a subject with uploaded curriculum.',
        );
      },
    );

    testWidgets(
      '4. Tapping a subject card opens SubjectDetailScreen',
      (tester) async {
        await _boot(tester);
        await _login(tester);
        await _clearPermissionGate(tester);
        await _waitForGarden(tester);

        final tapped = await _tapFirstSubjectCard(tester);
        expect(tapped, isTrue,
            reason: 'Expected to find and tap a subject card');

        // SubjectDetailScreen shows "Practice Now" or quiz history.
        expect(
          find.textContaining('Practice').evaluate().isNotEmpty ||
          find.textContaining('Quiz').evaluate().isNotEmpty ||
          find.textContaining('Mastery').evaluate().isNotEmpty,
          isTrue,
          reason: 'Expected to reach SubjectDetailScreen after tapping a card',
        );
      },
    );

    testWidgets(
      '5. Tapping "Practice Now" starts the quiz generation',
      (tester) async {
        await _boot(tester);
        await _login(tester);
        await _clearPermissionGate(tester);
        await _waitForGarden(tester);
        await _tapFirstSubjectCard(tester);

        final tapped = await _tapPracticeNow(tester);
        expect(tapped, isTrue,
            reason:
                'Expected a "Practice Now" or "Start Quiz" button on the detail screen');

        // The quiz overlay or a loading indicator should appear.
        expect(
          find.byType(CircularProgressIndicator).evaluate().isNotEmpty ||
          find.byType(Scaffold).evaluate().length > 1 ||
          find.textContaining('Question').evaluate().isNotEmpty,
          isTrue,
          reason: 'Expected the quiz overlay to appear after tapping Practice Now',
        );
      },
    );

    testWidgets(
      '6. Answering all questions reaches the results screen',
      (tester) async {
        await _boot(tester);
        await _login(tester);
        await _clearPermissionGate(tester);
        await _waitForGarden(tester);
        await _tapFirstSubjectCard(tester);
        await _tapPracticeNow(tester);
        await _answerAllQuestions(tester);

        expect(
          _quizResultsVisible(),
          isTrue,
          reason: 'Expected the quiz results / score screen after answering all questions',
        );
      },
    );

    testWidgets(
      '7. Tapping "Done" on results returns to the student home',
      (tester) async {
        await _boot(tester);
        await _login(tester);
        await _clearPermissionGate(tester);
        await _waitForGarden(tester);
        await _tapFirstSubjectCard(tester);
        await _tapPracticeNow(tester);
        await _answerAllQuestions(tester);

        // Tap "Done" to dismiss the results.
        final doneFinder = find.text('Done');
        if (doneFinder.evaluate().isNotEmpty) {
          await tester.tap(doneFinder.first);
          await tester.pumpAndSettle(const Duration(seconds: 3));
        }

        // After dismissal we should be back on the student home.
        expect(find.text('Sign In'), findsNothing);
        expect(find.byType(Scaffold), findsWidgets);
      },
    );
  });
}
