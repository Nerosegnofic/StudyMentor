// integration_test/document_upload_flow_test.dart
//
// Integration tests for the parent → document-upload flow.
//
// Navigation path tested:
//   Login → ParentHomeDashboard → student card → StudentProfileDashboard
//   → "Subjects & Skills" → SubjectsSkillsScreen → "+" → Upload Curriculum screen
//   → subject-name field → "Upload & Ingest" button (disabled, no PDF selected)
//
// NOTE: Actual PDF file selection requires a native OS picker which cannot be
//       automated. Tests go up to — and including — the upload button state.
//
// ══════════════════════════════════════════════════════════════════════════════
//  PREREQUISITES
//  • A parent account with at least one verified linked student.
//  HOW TO RUN:
//    flutter devices
//    flutter test integration_test/document_upload_flow_test.dart -d <device-id>
//  ⚠  DO NOT commit real credentials to git.
// ══════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:studymentor/main.dart' as app;

// ─── Fill in your parent account credentials ─────────────────────────────────
const _parentEmail    = 'YOUR_PARENT_EMAIL_HERE';
const _parentPassword = 'YOUR_PARENT_PASSWORD_HERE';
// ─────────────────────────────────────────────────────────────────────────────

// ─── Helpers ─────────────────────────────────────────────────────────────────

Future<void> _boot(WidgetTester tester) async {
  app.main();
  await tester.pumpAndSettle(const Duration(seconds: 6));
}

Future<void> _login(WidgetTester tester) async {
  if (find.text('Sign In').evaluate().isEmpty) return;
  await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'), _parentEmail);
  await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'), _parentPassword);
  await tester.tap(find.text('Sign In'));
  await tester.pumpAndSettle(const Duration(seconds: 8));
}

/// The parent permission gate may ask to grant notification / battery
/// permissions. Accept everything until the gate disappears.
Future<void> _clearPermissionGate(WidgetTester tester) async {
  for (int i = 0; i < 5; i++) {
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

/// Tap the first verified student card on the parent dashboard.
Future<void> _tapFirstStudentCard(WidgetTester tester) async {
  // Give Firestore time to return the student list.
  await tester.pump(const Duration(seconds: 4));
  await tester.pumpAndSettle(const Duration(seconds: 3));

  // ChildCard wraps its content in an InkWell — tap the first one visible.
  final cards = find.byType(InkWell);
  expect(cards, findsWidgets,
      reason: 'Expected at least one student card on the dashboard');
  await tester.tap(cards.first);
  await tester.pumpAndSettle(const Duration(seconds: 3));
}

/// From StudentProfileDashboard tap the "Subjects & Skills" nav row.
Future<void> _openSubjectsAndSkills(WidgetTester tester) async {
  final row = find.text('Subjects & Skills');
  expect(row, findsOneWidget,
      reason: 'Expected "Subjects & Skills" row on StudentProfileDashboard');
  await tester.tap(row);
  await tester.pumpAndSettle(const Duration(seconds: 3));
}

/// From SubjectsSkillsScreen tap the "+" / "Upload" FAB or icon to open
/// the StudentDocumentUploadScreen.
Future<void> _openUploadScreen(WidgetTester tester) async {
  // The "+" FAB adds a new subject and opens the upload screen.
  final fab = find.byType(FloatingActionButton);
  if (fab.evaluate().isNotEmpty) {
    await tester.tap(fab.first);
    await tester.pumpAndSettle(const Duration(seconds: 3));
    return;
  }
  // Fallback: look for an upload icon button.
  final icon = find.byIcon(Icons.add);
  if (icon.evaluate().isNotEmpty) {
    await tester.tap(icon.first);
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Document upload flow', () {
    testWidgets(
      '1. Parent login succeeds and reaches the dashboard',
      (tester) async {
        await _boot(tester);
        await _login(tester);

        expect(find.text('Sign In'), findsNothing,
            reason: 'Sign In should be gone after successful parent login');
      },
    );

    testWidgets(
      '2. At least one student card is visible after the permission gate',
      (tester) async {
        await _boot(tester);
        await _login(tester);
        await _clearPermissionGate(tester);

        await tester.pump(const Duration(seconds: 4));
        await tester.pumpAndSettle(const Duration(seconds: 3));

        expect(
          find.byType(InkWell).evaluate().isNotEmpty ||
          find.byType(Card).evaluate().isNotEmpty,
          isTrue,
          reason: 'Expected at least one student card on the parent dashboard',
        );
      },
    );

    testWidgets(
      '3. Tapping a student card opens StudentProfileDashboard',
      (tester) async {
        await _boot(tester);
        await _login(tester);
        await _clearPermissionGate(tester);
        await _tapFirstStudentCard(tester);

        // StudentProfileDashboard contains the "Subjects & Skills" nav row.
        expect(find.text('Subjects & Skills'), findsOneWidget);
      },
    );

    testWidgets(
      '4. "Subjects & Skills" row opens SubjectsSkillsScreen',
      (tester) async {
        await _boot(tester);
        await _login(tester);
        await _clearPermissionGate(tester);
        await _tapFirstStudentCard(tester);
        await _openSubjectsAndSkills(tester);

        // SubjectsSkillsScreen shows "Upload Curriculum" as its title or
        // a FAB for adding subjects.
        expect(
          find.textContaining('Subjects').evaluate().isNotEmpty ||
          find.byType(FloatingActionButton).evaluate().isNotEmpty,
          isTrue,
          reason: 'Expected to reach the Subjects & Skills screen',
        );
      },
    );

    testWidgets(
      '5. Tapping "+" opens the Upload Curriculum screen',
      (tester) async {
        await _boot(tester);
        await _login(tester);
        await _clearPermissionGate(tester);
        await _tapFirstStudentCard(tester);
        await _openSubjectsAndSkills(tester);
        await _openUploadScreen(tester);

        // The upload screen title is "Upload Curriculum".
        expect(find.text('Upload Curriculum'), findsOneWidget);
      },
    );

    testWidgets(
      '6. Upload screen shows the subject-name field',
      (tester) async {
        await _boot(tester);
        await _login(tester);
        await _clearPermissionGate(tester);
        await _tapFirstStudentCard(tester);
        await _openSubjectsAndSkills(tester);
        await _openUploadScreen(tester);

        // The TextField has hint "e.g. Mathematics, Science..."
        expect(find.byType(TextField), findsOneWidget);
      },
    );

    testWidgets(
      '7. "Upload & Ingest" button is disabled before a PDF is selected',
      (tester) async {
        await _boot(tester);
        await _login(tester);
        await _clearPermissionGate(tester);
        await _tapFirstStudentCard(tester);
        await _openSubjectsAndSkills(tester);
        await _openUploadScreen(tester);

        // Type a subject name — the button is still disabled (no file yet).
        await tester.enterText(find.byType(TextField), 'Mathematics');
        await tester.pump();

        final buttons = tester.widgetList<ElevatedButton>(
          find.byType(ElevatedButton),
        );
        expect(
          buttons.any((b) => b.onPressed == null),
          isTrue,
          reason:
              '"Upload & Ingest" must remain disabled until a PDF is picked',
        );
      },
    );

    testWidgets(
      '8. Tapping the PDF-picker area does not crash the app',
      (tester) async {
        await _boot(tester);
        await _login(tester);
        await _clearPermissionGate(tester);
        await _tapFirstStudentCard(tester);
        await _openSubjectsAndSkills(tester);
        await _openUploadScreen(tester);

        // Tap the cloud-upload icon or the PDF-picker area.
        for (final icon in [
          Icons.cloud_upload_outlined,
          Icons.upload_file_rounded,
        ]) {
          final finder = find.byIcon(icon);
          if (finder.evaluate().isNotEmpty) {
            await tester.tap(finder.first);
            break;
          }
        }

        // The native OS picker opens (cannot be automated) but the app
        // must remain alive.
        await tester.pump(const Duration(seconds: 2));
        expect(find.byType(Scaffold), findsWidgets);
      },
    );
  });
}
