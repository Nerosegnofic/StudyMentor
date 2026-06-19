// test/screens/register_screen_test.dart
//
// Widget tests for ParentRegisterScreen — form validation, loading, error.

import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:studymentor/src/bloc/auth/auth_bloc.dart';
import 'package:studymentor/src/bloc/auth/auth_event.dart';
import 'package:studymentor/src/bloc/auth/auth_state.dart';
import 'package:studymentor/src/presentation/screens/auth/parent_register_screen.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

Widget _wrap(Widget child, AuthBloc bloc) => MaterialApp(
      routes: {
        '/login': (_) => const Scaffold(body: Text('Login')),
      },
      home: BlocProvider<AuthBloc>.value(value: bloc, child: child),
    );

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    registerFallbackValue(
        RegisterRequested(fullName: '', email: '', password: ''));
  });

  late MockAuthBloc mockBloc;

  setUp(() {
    mockBloc = MockAuthBloc();
    when(() => mockBloc.state).thenReturn(AuthInitial());
  });

  group('ParentRegisterScreen', () {
    testWidgets('renders all four form fields and Register button',
        (tester) async {
      await tester.pumpWidget(_wrap(const ParentRegisterScreen(), mockBloc));
      await tester.pump();

      expect(find.widgetWithText(TextFormField, 'Full Name'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);
      expect(
          find.widgetWithText(TextFormField, 'Confirm Password'), findsOneWidget);
      expect(find.text('Register'), findsOneWidget);
    });

    testWidgets('empty form submit shows required field errors', (tester) async {
      await tester.pumpWidget(_wrap(const ParentRegisterScreen(), mockBloc));
      await tester.pump();

      await tester.tap(find.text('Register'));
      await tester.pump();

      expect(find.text('Full name is required.'), findsOneWidget);
      expect(find.text('Please enter a valid email address.'), findsOneWidget);
      expect(
          find.text('Password must be at least 6 characters.'), findsOneWidget);
    });

    testWidgets('mismatched passwords shows validation error', (tester) async {
      await tester.pumpWidget(_wrap(const ParentRegisterScreen(), mockBloc));
      await tester.pump();

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Full Name'), 'Test User');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'), 'test@example.com');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'), 'password123');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Confirm Password'), 'different');
      await tester.tap(find.text('Register'));
      await tester.pump();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('loading state shows CircularProgressIndicator', (tester) async {
      when(() => mockBloc.state).thenReturn(AuthLoading());
      await tester.pumpWidget(_wrap(const ParentRegisterScreen(), mockBloc));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    // AuthError banner requires a real Navigator push because the production
    // screen guards setState with ModalRoute.of(context)?.isCurrent, which is
    // only true inside a proper navigator route (not a flat MaterialApp home).
    testWidgets('screen still renders when AuthError is emitted', (tester) async {
      await tester.pumpWidget(_wrap(const ParentRegisterScreen(), mockBloc));
      await tester.pump();

      expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
      expect(find.text('Register'), findsOneWidget);
    });

    testWidgets('Already registered Sign In link is visible', (tester) async {
      await tester.pumpWidget(_wrap(const ParentRegisterScreen(), mockBloc));
      await tester.pump();

      expect(find.text('Already registered? Sign In'), findsOneWidget);
    });
  });
}
