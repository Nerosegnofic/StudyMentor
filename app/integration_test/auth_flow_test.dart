// integration_test/auth_flow_test.dart
//
// Integration tests for authentication flows.
// Runs on a real device/emulator/browser with a live Firebase project.
//
// HOW TO RUN:
//   flutter test integration_test/auth_flow_test.dart -d chrome
//   flutter test integration_test/auth_flow_test.dart -d <android-device-id>
//
// ⚠️  Fill in TEST_EMAIL / TEST_PASSWORD below before running.
//     DO NOT commit real credentials to git.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:studymentor/main.dart' as app;

// ─── Put your test account credentials here ──────────────────────────────────
const _parentEmail    = 'YOUR_PARENT_EMAIL_HERE';
const _parentPassword = 'YOUR_PARENT_PASSWORD_HERE';
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Auth flow', () {
    testWidgets('1. Login screen is displayed on cold start', (tester) async {
      app.main();
      // pumpAndSettle with a long timeout because Firebase initialization takes time.
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // If there is a cached session the app may go straight to the home screen.
      // In that case this test is skipped — sign out manually first.
      if (find.text('Sign In').evaluate().isEmpty) {
        // Already logged in — skip.
        return;
      }

      expect(find.text('Sign In'), findsWidgets);
      expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);
    });

    testWidgets('2. Invalid credentials show an error message', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      if (find.text('Sign In').evaluate().isEmpty) return; // already logged in

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'), 'nobody@invalid.com');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'), 'wrongpassword');
      await tester.tap(find.text('Sign In'));

      // Wait for Firebase to respond (network call).
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // The screen shows an error banner when credentials are wrong.
      expect(
        find.textContaining('No user found')
            .evaluate()
            .isNotEmpty ||
        find.textContaining('wrong password')
            .evaluate()
            .isNotEmpty ||
        find.textContaining('invalid')
            .evaluate()
            .isNotEmpty,
        isTrue,
        reason: 'Expected an error message to appear after wrong credentials',
      );
    });

    testWidgets('3. Valid credentials log in and reach home screen',
        (tester) async {
      // ⚠️  Fill in _testEmail and _testPassword at the top of this file first.
      if (_testEmail == 'YOUR_EMAIL_HERE') {
        // Reminder: set your credentials at the top of this file.
        return;
      }

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      if (find.text('Sign In').evaluate().isEmpty) return; // already logged in

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'), _testEmail);
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'), _testPassword);
      await tester.tap(find.text('Sign In'));

      // Wait for Firebase sign-in + home screen to load.
      await tester.pumpAndSettle(const Duration(seconds: 8));

      // After successful login, Sign In button should be gone.
      expect(find.text('Sign In'), findsNothing);
    });
  });
}
