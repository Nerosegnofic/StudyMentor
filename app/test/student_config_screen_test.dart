import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:studymentor/src/bloc/auth/auth_bloc.dart';
import 'package:studymentor/src/bloc/app_config/app_config_bloc.dart';
import 'package:studymentor/src/domain/models/student_model.dart';
import 'package:studymentor/src/domain/models/app_config_model.dart';
import 'package:studymentor/src/domain/models/installed_app_model.dart';
import 'package:studymentor/src/domain/repositories/auth_repository.dart';
import 'package:studymentor/src/presentation/screens/parent/student_config_screen.dart';

class FakeAuthRepository implements AuthRepository {
  @override
  Future<({StudentConfigModel? config, List<AppRuleModel> rules})>
  getAppConfigForStudent(String studentUid) async {
    return (
      config: const StudentConfigModel(usageHours: 0, usageMinutes: 1),
      rules: const <AppRuleModel>[],
    );
  }

  @override
  Future<List<InstalledAppModel>> getInstalledAppsForStudent(String studentUid) async {
    return const [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAuthBloc extends AuthBloc {
  FakeAuthBloc() : super(repository: FakeAuthRepository());
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('StudentConfigScreen reward time editing and bottom sheet test', (WidgetTester tester) async {
    final student = StudentModel(
      uid: 'test_student_uid',
      fullName: 'Ahmed Doe',
      email: 'ahmed@example.com',
      username: 'ahmeddoe',
    );

    final fakeRepo = FakeAuthRepository();
    final fakeAuthBloc = FakeAuthBloc();
    final fakeAppConfigBloc = AppConfigBloc(authRepository: fakeRepo);

    await tester.pumpWidget(
      MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: fakeAuthBloc),
            BlocProvider<AppConfigBloc>.value(value: fakeAppConfigBloc),
          ],
          child: StudentConfigScreen(student: student),
        ),
      ),
    );

    // Let the initial loading events process
    await tester.pumpAndSettle();

    // Verify initial time reward text is shown (00 : 01)
    expect(find.text('00 : 01'), findsOneWidget);

    // Verify Edit icon exists next to it
    expect(find.byIcon(Icons.edit), findsOneWidget);

    // Tap on the container holding the time text to open the Bottom Sheet
    await tester.tap(find.text('00 : 01'));
    await tester.pumpAndSettle();

    // Verify Bottom Sheet is open
    expect(find.text('Set Reward Time'), findsOneWidget);

    // Verify Presets are displayed
    expect(find.text('10 mins'), findsOneWidget);
    expect(find.text('15 mins'), findsOneWidget);
    expect(find.text('30 mins'), findsOneWidget);
    expect(find.text('1 hour'), findsOneWidget);

    // Tap the '15 mins' preset chip
    await tester.tap(find.text('15 mins'));
    await tester.pumpAndSettle();

    // Tap the 'Save Time' button in the sticky footer
    await tester.tap(find.text('Save Time'));
    await tester.pumpAndSettle();

    // Verify bottom sheet is dismissed
    expect(find.text('Set Reward Time'), findsNothing);

    // Verify the new time is displayed on the main screen (00 : 15)
    expect(find.text('00 : 15'), findsOneWidget);
  });
}
