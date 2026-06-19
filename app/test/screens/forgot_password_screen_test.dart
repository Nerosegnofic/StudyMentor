// test/screens/forgot_password_screen_test.dart
//
// Widget tests for ForgotPasswordScreen.

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
import 'package:studymentor/src/presentation/screens/auth/forgot_password_screen.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

Widget _wrap(Widget child, AuthBloc bloc) => MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: BlocProvider<AuthBloc>.value(value: bloc, child: child),
    );

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    registerFallbackValue(PasswordResetRequested(email: ''));
  });

  late MockAuthBloc mockBloc;

  setUp(() {
    mockBloc = MockAuthBloc();
    when(() => mockBloc.state).thenReturn(AuthInitial());
  });

  group('ForgotPasswordScreen', () {
    testWidgets('renders email field and send button', (tester) async {
      await tester.pumpWidget(_wrap(const ForgotPasswordScreen(), mockBloc));
      await tester.pump();

      expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
      expect(find.text('Send Reset Link'), findsOneWidget);
    });

    testWidgets('empty email shows validation error', (tester) async {
      await tester.pumpWidget(_wrap(const ForgotPasswordScreen(), mockBloc));
      await tester.pump();

      await tester.tap(find.text('Send Reset Link'));
      await tester.pump();

      expect(find.text('Please enter a valid email address.'), findsOneWidget);
    });

    testWidgets('AuthError state shows error message', (tester) async {
      whenListen(
        mockBloc,
        Stream.fromIterable([AuthError('No user found')]),
        initialState: AuthInitial(),
      );
      await tester.pumpWidget(_wrap(const ForgotPasswordScreen(), mockBloc));
      await tester.pump();

      expect(find.text('No user found'), findsOneWidget);
    });

    testWidgets(
        'valid email dispatches PasswordResetRequested and shows no error',
        (tester) async {
      await tester.pumpWidget(_wrap(const ForgotPasswordScreen(), mockBloc));
      await tester.pump();

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'), 'user@example.com');
      await tester.tap(find.text('Send Reset Link'));
      await tester.pump();

      verify(() =>
              mockBloc.add(PasswordResetRequested(email: 'user@example.com')))
          .called(1);
    });
  });
}
