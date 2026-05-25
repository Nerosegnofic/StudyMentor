import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:studymentor/src/domain/models/student_model.dart';
import 'package:studymentor/src/presentation/screens/parent/subjects_skills_screen.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('SubjectsSkillsScreen dynamic removal and dialog test', (WidgetTester tester) async {
    final student = StudentModel(
      uid: 'test_uid',
      fullName: 'John Doe',
      email: 'john@example.com',
      username: 'johndoe',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SubjectsSkillsScreen(student: student),
        ),
      ),
    );

    // Verify initial subjects are rendered
    expect(find.text('Mathematics'), findsOneWidget);
    expect(find.text('Science'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);

    // Verify progress bars are displayed
    expect(find.text('85%'), findsOneWidget);
    expect(find.text('60%'), findsOneWidget);
    expect(find.text('92%'), findsOneWidget);

    // Find the three-dots menu icon for Mathematics (first widget)
    final threeDots = find.byIcon(Icons.more_vert).first;
    await tester.tap(threeDots);
    await tester.pumpAndSettle();

    // Verify the "Remove Subject" dropdown item option appears
    expect(find.text('Remove Subject'), findsOneWidget);

    // Tap "Remove Subject" from dropdown
    await tester.tap(find.text('Remove Subject'));
    await tester.pumpAndSettle();

    // Verify styled deletion confirmation dialog is shown
    expect(find.text('Remove Mathematics?'), findsOneWidget);
    expect(
      find.text('Are you sure you want to stop tracking this subject? This will remove it from your dashboard.'),
      findsOneWidget,
    );

    // Tap "Cancel" on the dialog
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // Verify modal is dismissed and subject is NOT removed
    expect(find.text('Remove Mathematics?'), findsNothing);
    expect(find.text('Mathematics'), findsOneWidget);

    // Open menu again to proceed with removal
    await tester.tap(threeDots);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove Subject'));
    await tester.pumpAndSettle();

    // Tap "Remove" on the dialog
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();

    // Verify modal is dismissed and Mathematics is removed, others remain
    expect(find.text('Remove Mathematics?'), findsNothing);
    expect(find.text('Mathematics'), findsNothing);
    expect(find.text('Science'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
  });
}
