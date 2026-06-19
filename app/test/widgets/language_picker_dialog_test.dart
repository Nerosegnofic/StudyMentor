// test/widgets/language_picker_dialog_test.dart
//
// Widget tests for showLanguagePickerDialog — options, checkmark, callbacks.

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:studymentor/l10n/app_localizations.dart';
import 'package:studymentor/src/bloc/locale/locale_cubit.dart';
import 'package:studymentor/src/presentation/widgets/language_picker_dialog.dart';

class MockLocaleCubit extends MockCubit<Locale> implements LocaleCubit {}

Widget _wrapWithButton(LocaleCubit cubit) => MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: BlocProvider<LocaleCubit>.value(
          value: cubit,
          child: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => showLanguagePickerDialog(ctx),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    registerFallbackValue(const Locale('en'));
  });

  late MockLocaleCubit mockCubit;

  setUp(() {
    mockCubit = MockLocaleCubit();
    when(() => mockCubit.state).thenReturn(const Locale('en'));
  });

  Future<void> openDialog(WidgetTester tester) async {
    await tester.pumpWidget(_wrapWithButton(mockCubit));
    await tester.pump();
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  group('showLanguagePickerDialog', () {
    testWidgets('dialog opens without throwing', (tester) async {
      await openDialog(tester);
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('shows English option', (tester) async {
      await openDialog(tester);
      expect(find.text('English'), findsOneWidget);
    });

    testWidgets('shows Arabic option', (tester) async {
      await openDialog(tester);
      expect(find.text('Arabic'), findsOneWidget);
    });

    testWidgets('shows Cancel button', (tester) async {
      await openDialog(tester);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('English option shows checkmark when locale is "en"',
        (tester) async {
      when(() => mockCubit.state).thenReturn(const Locale('en'));
      await openDialog(tester);
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('Arabic option shows checkmark when locale is "ar"',
        (tester) async {
      when(() => mockCubit.state).thenReturn(const Locale('ar'));
      await openDialog(tester);
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('tapping English calls setLocale with Locale("en")',
        (tester) async {
      when(() => mockCubit.setLocale(any())).thenAnswer((_) async {});
      await openDialog(tester);
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();
      verify(() => mockCubit.setLocale(const Locale('en'))).called(1);
    });

    testWidgets('tapping Arabic calls setLocale with Locale("ar")',
        (tester) async {
      when(() => mockCubit.setLocale(any())).thenAnswer((_) async {});
      await openDialog(tester);
      await tester.tap(find.text('Arabic'));
      await tester.pumpAndSettle();
      verify(() => mockCubit.setLocale(const Locale('ar'))).called(1);
    });

    testWidgets('tapping English closes the dialog', (tester) async {
      when(() => mockCubit.setLocale(any())).thenAnswer((_) async {});
      await openDialog(tester);
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('tapping Cancel closes the dialog without calling setLocale',
        (tester) async {
      await openDialog(tester);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      verifyNever(() => mockCubit.setLocale(any()));
    });
  });
}
