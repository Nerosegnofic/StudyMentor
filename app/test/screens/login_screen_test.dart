// test/screens/login_screen_test.dart
//
// Widget tests for LoginScreen — form validation, loading state, error banner.

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:studymentor/src/bloc/auth/auth_bloc.dart';
import 'package:studymentor/src/bloc/auth/auth_event.dart';
import 'package:studymentor/src/bloc/auth/auth_state.dart';
import 'package:studymentor/src/presentation/screens/auth/login_screen.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

Widget _wrap(Widget child, AuthBloc bloc) => MaterialApp(
      routes: {
        '/register': (_) => const Scaffold(body: Text('Register')),
        '/forgot-password': (_) => const Scaffold(body: Text('ForgotPassword')),
      },
      home: BlocProvider<AuthBloc>.value(value: bloc, child: child),
    );

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    registerFallbackValue(LoginRequested(email: '', password: ''));
  });

  late MockAuthBloc mockBloc;

  setUp(() {
    mockBloc = MockAuthBloc();
    when(() => mockBloc.state).thenReturn(AuthInitial());
  });

  group('LoginScreen', () {
    testWidgets('renders email field, password field and Sign In button',
        (tester) async {
      await tester.pumpWidget(_wrap(const LoginScreen(), mockBloc));
      await tester.pump();

      expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets('submitting empty form shows validation errors', (tester) async {
      await tester.pumpWidget(_wrap(const LoginScreen(), mockBloc));
      await tester.pump();

      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(find.text('Please enter a valid email address.'), findsOneWidget);
      expect(find.text('Password is required.'), findsOneWidget);
    });

    testWidgets('invalid email format shows field error', (tester) async {
      await tester.pumpWidget(_wrap(const LoginScreen(), mockBloc));
      await tester.pump();

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'), 'notanemail');
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(find.text('Please enter a valid email address.'), findsOneWidget);
    });

    testWidgets('loading state shows CircularProgressIndicator in button',
        (tester) async {
      when(() => mockBloc.state).thenReturn(AuthLoading());
      await tester.pumpWidget(_wrap(const LoginScreen(), mockBloc));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('AuthError state shows error banner', (tester) async {
      // Start in initial then emit error so the listener fires.
      whenListen(
        mockBloc,
        Stream.fromIterable([AuthError('Wrong password')]),
        initialState: AuthInitial(),
      );
      await tester.pumpWidget(_wrap(const LoginScreen(), mockBloc));
      await tester.pump();

      expect(find.text('Wrong password'), findsOneWidget);
    });

    testWidgets('Forgot Password? link is visible', (tester) async {
      await tester.pumpWidget(_wrap(const LoginScreen(), mockBloc));
      await tester.pump();

      expect(find.text('Forgot Password?'), findsOneWidget);
    });

    testWidgets('Register link is visible', (tester) async {
      await tester.pumpWidget(_wrap(const LoginScreen(), mockBloc));
      await tester.pump();

      expect(
        find.text('Not registered yet? Register as a Parent'),
        findsOneWidget,
      );
    });
  });
}
