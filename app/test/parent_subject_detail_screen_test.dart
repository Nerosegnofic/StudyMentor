import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:studymentor/src/presentation/screens/parent/parent_subject_detail_screen.dart';
import 'package:studymentor/src/presentation/screens/parent/all_skills_screen.dart';
import 'package:studymentor/src/presentation/screens/parent/all_quizzes_screen.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('ParentSubjectDetailScreen layout, content, sorting, navigation and interactive dots test', (WidgetTester tester) async {
    // Set a larger physical size to fit all content on screen
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: ParentSubjectDetailScreen(
          subjectName: 'Mathematics',
          color: Colors.blue,
        ),
      ),
    );

    // Verify Title
    expect(find.text('Mathematics'), findsOneWidget);

    // Verify Top Overview Stats
    expect(find.text('Accuracy'), findsOneWidget);
    expect(find.text('88%'), findsOneWidget);
    expect(find.text('Quizzes Done'), findsOneWidget);
    expect(find.text('42'), findsOneWidget);
    expect(find.text('Time Spent'), findsOneWidget);
    expect(find.text('5h 10m'), findsOneWidget);

    // Verify Overall Mastery Level and status badge
    expect(find.text('Overall Mastery Level'), findsOneWidget);
    expect(find.text('82%'), findsOneWidget);
    expect(find.text('Proficient'), findsOneWidget);

    // Verify Weekly Timeframe Labels below spline chart
    expect(find.text('Week 1'), findsOneWidget);
    expect(find.text('Week 2'), findsOneWidget);
    expect(find.text('Week 3'), findsOneWidget);
    expect(find.text('This Week'), findsOneWidget);

    // Verify Skills Progress card content
    expect(find.text('Skills Progress'), findsOneWidget);
    expect(find.text('See All'), findsNWidgets(2)); // One in Skills, one in Quiz History

    // Verify Arabic Skill row names
    expect(find.text('الكسور'), findsOneWidget);
    expect(find.text('الأعداد العشرية'), findsOneWidget);
    expect(find.text('الهندسة'), findsOneWidget);

    // Verify Skill row badges/scores
    expect(find.text('Strong'), findsOneWidget);
    expect(find.text('Needs Work'), findsOneWidget);
    expect(find.text('85%'), findsOneWidget);
    expect(find.text('45%'), findsOneWidget);
    expect(find.text('70%'), findsOneWidget);

    // Verify Navigation to AllSkillsScreen via "See All" (first button)
    await tester.tap(find.text('See All').first);
    await tester.pumpAndSettle();

    // Verify AllSkillsScreen is shown
    expect(find.byType(AllSkillsScreen), findsOneWidget);
    expect(find.text('All Skills'), findsOneWidget);
    expect(find.text('All Skills List Placeholder'), findsOneWidget);

    // Go back to the Subject Detail screen
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    // Scroll to the bottom to ensure Quiz History is fully in view
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();

    // Verify Quiz History card header and sort icon
    expect(find.text('Quiz History'), findsOneWidget);
    expect(find.byIcon(Icons.sort), findsOneWidget);

    // Verify Navigation to AllQuizzesScreen via "See All" (last button)
    await tester.tap(find.text('See All').last);
    await tester.pumpAndSettle();

    // Verify AllQuizzesScreen is shown
    expect(find.byType(AllQuizzesScreen), findsOneWidget);
    expect(find.text('All Quizzes'), findsOneWidget);
    expect(find.text('All Quizzes List Placeholder'), findsOneWidget);

    // Go back to the Subject Detail screen
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    // Scroll down again to ensure Quiz History is in viewport
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();

    // Verify Default sorting (Date: Newest to Oldest)
    // "Today, 10:30 AM" is newest, "Yesterday, 2:15 PM" is oldest.
    final Finder todayFinder = find.text('Today, 10:30 AM');
    final Finder yesterdayFinder = find.text('Yesterday, 2:15 PM');
    expect(todayFinder, findsOneWidget);
    expect(yesterdayFinder, findsOneWidget);
    expect(tester.getTopLeft(todayFinder).dy < tester.getTopLeft(yesterdayFinder).dy, isTrue);

    // Tap the sort button to open the sorting modal
    await tester.tap(find.byIcon(Icons.sort));
    await tester.pumpAndSettle();

    // Verify Sort Modal is displayed
    expect(find.text('Sort Quizzes'), findsOneWidget);
    expect(find.text('Date: Newest to Oldest'), findsOneWidget);
    expect(find.text('Date: Oldest to Newest'), findsOneWidget);
    expect(find.text('Score: Highest to Lowest'), findsOneWidget);
    expect(find.text('Score: Lowest to Highest'), findsOneWidget);

    // Tap "Score: Lowest to Highest" (3/10 is lowest, so "Yesterday, 2:15 PM" should be first)
    await tester.tap(find.text('Score: Lowest to Highest'));
    await tester.pumpAndSettle();

    // Verify the list is resorted (Yesterday is now above Today)
    expect(tester.getTopLeft(yesterdayFinder).dy < tester.getTopLeft(todayFinder).dy, isTrue);

    // Tap sort button again to restore default
    await tester.tap(find.byIcon(Icons.sort));
    await tester.pumpAndSettle();

    // Select "Date: Newest to Oldest"
    await tester.tap(find.text('Date: Newest to Oldest'));
    await tester.pumpAndSettle();

    // Verify original order is restored
    expect(tester.getTopLeft(todayFinder).dy < tester.getTopLeft(yesterdayFinder).dy, isTrue);

    // Tap on the card "Today, 10:30 AM" to expand it
    await tester.tap(todayFinder);
    await tester.pumpAndSettle();

    // Find the dot for question 7 (incorrect question for first card)
    final Finder dot7 = find.text('7');
    expect(dot7, findsOneWidget);

    // Tap on the dot to open the Question Detail bottom sheet
    await tester.tap(dot7);
    await tester.pumpAndSettle();

    // Verify the bottom sheet content
    expect(find.text('Question 7'), findsOneWidget);
    expect(find.text('Incorrect'), findsOneWidget);
    expect(find.text('ما هو الكوكب الأقرب إلى الشمس؟'), findsOneWidget);
    
    // Verify options list
    expect(find.text('عطارد'), findsOneWidget);
    expect(find.text('الزهرة'), findsOneWidget);
    expect(find.text('الأرض'), findsOneWidget);
    expect(find.text('المريخ'), findsOneWidget);

    // Tap "Close" button to close the bottom sheet
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    // Verify the bottom sheet is closed
    expect(find.text('Question 7'), findsNothing);
  });
}
