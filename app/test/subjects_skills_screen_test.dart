import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:studymentor/l10n/app_localizations.dart';
import 'package:studymentor/src/bloc/subject/subject_bloc.dart';
import 'package:studymentor/src/bloc/subject_status/subject_status_cubit.dart';
import 'package:studymentor/src/data/repositories/ai_engine_repository.dart';
import 'package:studymentor/src/domain/models/student_model.dart';
import 'package:studymentor/src/domain/models/subject_summary_model.dart';
import 'package:studymentor/src/domain/repositories/auth_repository.dart';
import 'package:studymentor/src/presentation/screens/parent/subjects_skills_screen.dart';

class MockAiEngineRepository extends Mock implements AiEngineRepository {}

class FakeAuthRepository implements AuthRepository {
  final List<SubjectSummaryModel> subjects = [
    const SubjectSummaryModel(
      subjectKey: 'mathematics',
      colorHex: '#2E7D32',
      skillsCount: 12,
      masteryPercent: 85,
      quizzesCompleted: 12,
      totalTimeSpent: Duration(hours: 4),
      accuracyPercent: 85,
    ),
    const SubjectSummaryModel(
      subjectKey: 'science',
      colorHex: '#AD1457',
      skillsCount: 8,
      masteryPercent: 60,
      quizzesCompleted: 8,
      totalTimeSpent: Duration(hours: 2),
      accuracyPercent: 60,
    ),
    const SubjectSummaryModel(
      subjectKey: 'english',
      colorHex: '#6A1B9A',
      skillsCount: 15,
      masteryPercent: 92,
      quizzesCompleted: 20,
      totalTimeSpent: Duration(hours: 7),
      accuracyPercent: 92,
    ),
  ];

  @override
  Future<List<SubjectSummaryModel>> getSubjectsByStudent(String studentUid) async {
    return subjects;
  }

  @override
  Future<void> removeSubject({required String studentUid, required String subjectKey}) async {
    subjects.removeWhere((s) => s.subjectKey == subjectKey);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('SubjectsSkillsScreen dynamic removal and dialog test', (WidgetTester tester) async {
    final student = StudentModel(
      uid: 'test_uid',
      fullName: 'John Doe',
      email: 'john@example.com',
    );

    final fakeRepo = FakeAuthRepository();
    final fakeBloc = SubjectBloc(authRepository: fakeRepo);

    // Inject a no-op AiEngineRepository so SubjectStatusCubit never touches Firebase.
    final mockAiRepo = MockAiEngineRepository();
    when(() => mockAiRepo.getSubjectsStatus(studentUid: any(named: 'studentUid')))
        .thenAnswer((_) async => []);
    final statusCubit = SubjectStatusCubit(
      studentUid: student.uid,
      repository: mockAiRepo,
      pollInterval: const Duration(days: 1),
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BlocProvider<SubjectBloc>.value(
            value: fakeBloc,
            child: SubjectsSkillsScreen(student: student, statusCubit: statusCubit),
          ),
        ),
      ),
    );

    // Allow async load to complete and UI to rebuild with loaded subjects
    await tester.pumpAndSettle();

    // Verify initial subjects are rendered
    expect(find.text('Mathematics'), findsOneWidget);
    expect(find.text('Science'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);

    // Verify progress bars are displayed
    expect(find.text('85%'), findsOneWidget);
    expect(find.text('60%'), findsOneWidget);
    expect(find.text('92%'), findsOneWidget);

    // Find the delete icon for Mathematics (first widget)
    final deleteIcon = find.byIcon(Icons.delete_outline).first;
    await tester.tap(deleteIcon);
    await tester.pumpAndSettle();

    // Verify styled deletion confirmation dialog is shown
    expect(find.text('Remove mathematics?'), findsOneWidget);
    expect(
      find.text('This permanently deletes the subject and all its data.'),
      findsOneWidget,
    );

    // Tap "Cancel" on the dialog
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // Verify modal is dismissed and subject is NOT removed
    expect(find.text('Remove mathematics?'), findsNothing);
    expect(find.text('Mathematics'), findsOneWidget);

    // Tap the delete icon again to proceed with removal
    await tester.tap(deleteIcon);
    await tester.pumpAndSettle();

    // Tap "Remove" on the dialog
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle(); // This will trigger remove -> state listener -> LoadSubjectsRequested -> rebuild
    await tester.pumpAndSettle();

    // Verify modal is dismissed and Mathematics is removed, others remain
    expect(find.text('Remove mathematics?'), findsNothing);
    expect(find.text('Mathematics'), findsNothing);
    expect(find.text('Science'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);

    await statusCubit.close();
  });
}
