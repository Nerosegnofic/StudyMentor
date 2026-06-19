// test/screens/confirm_email_screen_test.dart

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:studymentor/l10n/app_localizations.dart';
import 'package:studymentor/src/bloc/auth/auth_bloc.dart';
import 'package:studymentor/src/bloc/auth/auth_event.dart';
import 'package:studymentor/src/bloc/auth/auth_state.dart';
import 'package:studymentor/src/presentation/screens/auth/confirm_email_screen.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

Widget _wrap(AuthBloc bloc) => MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: BlocProvider<AuthBloc>.value(
        value: bloc,
        child: const ConfirmEmailScreen(),
      ),
    );

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    registerFallbackValue(SendEmailVerificationRequested());
    registerFallbackValue(CheckEmailVerificationRequested());
    registerFallbackValue(LogoutRequested());
  });

  late MockAuthBloc mockBloc;

  setUp(() {
    mockBloc = MockAuthBloc();
    when(() => mockBloc.state).thenReturn(AuthInitial());
  });

  group('ConfirmEmailScreen', () {
    testWidgets('renders without throwing in initial state', (tester) async {
      await tester.pumpWidget(_wrap(mockBloc));
      await tester.pump();
      expect(find.byType(ConfirmEmailScreen), findsOneWidget);
    });

    testWidgets('shows "Send Email Verification Link" button', (tester) async {
      await tester.pumpWidget(_wrap(mockBloc));
      await tester.pump();
      expect(find.text('Send Email Verification Link'), findsOneWidget);
    });

    testWidgets('shows "I\'ve Verified My Email" button', (tester) async {
      await tester.pumpWidget(_wrap(mockBloc));
      await tester.pump();
      expect(find.text("I've Verified My Email"), findsOneWidget);
    });

    testWidgets('shows "Log Out" link', (tester) async {
      await tester.pumpWidget(_wrap(mockBloc));
      await tester.pump();
      expect(find.text('Log Out'), findsOneWidget);
    });

    testWidgets('loading state shows CircularProgressIndicator', (tester) async {
      when(() => mockBloc.state).thenReturn(AuthLoading());
      await tester.pumpWidget(_wrap(mockBloc));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // Buttons are hidden while loading.
      expect(find.text('Send Email Verification Link'), findsNothing);
    });

    testWidgets('tapping "Send Email Verification Link" dispatches event',
        (tester) async {
      await tester.pumpWidget(_wrap(mockBloc));
      await tester.pump();
      await tester.tap(find.text('Send Email Verification Link'));
      await tester.pump();
      verify(() => mockBloc.add(any(that: isA<SendEmailVerificationRequested>())))
          .called(1);
    });

    testWidgets("tapping \"I've Verified My Email\" dispatches event",
        (tester) async {
      await tester.pumpWidget(_wrap(mockBloc));
      await tester.pump();
      await tester.tap(find.text("I've Verified My Email"));
      await tester.pump();
      verify(() =>
              mockBloc.add(any(that: isA<CheckEmailVerificationRequested>())))
          .called(1);
    });

    testWidgets('tapping "Log Out" dispatches LogoutRequested', (tester) async {
      await tester.pumpWidget(_wrap(mockBloc));
      await tester.pump();
      await tester.tap(find.text('Log Out'));
      await tester.pump();
      verify(() => mockBloc.add(any(that: isA<LogoutRequested>()))).called(1);
    });
  });
}
