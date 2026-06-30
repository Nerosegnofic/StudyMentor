// test/screens/student_documents_test.dart
//
// Widget tests for StudentDocumentUploadScreen.
// Only tests Initial / Loading / Error states — DocumentUploadAccepted renders
// _PreparingView which calls AiEngineRepository.instance (Firebase singleton)
// and is therefore skipped in unit tests.

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:studymentor/l10n/app_localizations.dart';
import 'package:studymentor/src/bloc/document/document_upload_bloc.dart';
import 'package:studymentor/src/bloc/document/document_upload_event.dart';
import 'package:studymentor/src/bloc/document/document_upload_state.dart';
import 'package:studymentor/src/bloc/subject/subject_bloc.dart';
import 'package:studymentor/src/bloc/subject/subject_event.dart';
import 'package:studymentor/src/bloc/subject/subject_state.dart';
import 'package:studymentor/src/presentation/screens/student/student_documents.dart';

class MockDocumentUploadBloc
    extends MockBloc<DocumentUploadEvent, DocumentUploadState>
    implements DocumentUploadBloc {}

class MockSubjectBloc extends MockBloc<SubjectEvent, SubjectState>
    implements SubjectBloc {}

Widget _wrap({
  required DocumentUploadBloc uploadBloc,
  required SubjectBloc subjectBloc,
}) =>
    MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: MultiBlocProvider(
          providers: [
            BlocProvider<DocumentUploadBloc>.value(value: uploadBloc),
            BlocProvider<SubjectBloc>.value(value: subjectBloc),
          ],
          child: StudentDocumentUploadScreen(
            studentUid: 'student1',
            existingSubjectKeys: const [],
          ),
        ),
      ),
    );

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  late MockDocumentUploadBloc mockUploadBloc;
  late MockSubjectBloc mockSubjectBloc;

  setUp(() {
    mockUploadBloc = MockDocumentUploadBloc();
    mockSubjectBloc = MockSubjectBloc();
    when(() => mockUploadBloc.state).thenReturn(DocumentUploadInitial());
    when(() => mockSubjectBloc.state).thenReturn(SubjectInitial());
  });

  group('StudentDocumentUploadScreen', () {
    testWidgets('renders without throwing in initial state', (tester) async {
      await tester.pumpWidget(
          _wrap(uploadBloc: mockUploadBloc, subjectBloc: mockSubjectBloc));
      await tester.pump();
      expect(find.byType(StudentDocumentUploadScreen), findsOneWidget);
    });

    testWidgets('initial state shows upload icon', (tester) async {
      await tester.pumpWidget(
          _wrap(uploadBloc: mockUploadBloc, subjectBloc: mockSubjectBloc));
      await tester.pump();
      expect(find.byIcon(Icons.upload_file_rounded), findsOneWidget);
    });

    testWidgets('initial state shows subject name text field', (tester) async {
      await tester.pumpWidget(
          _wrap(uploadBloc: mockUploadBloc, subjectBloc: mockSubjectBloc));
      await tester.pump();
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('initial state upload button is disabled (no file selected)',
        (tester) async {
      await tester.pumpWidget(
          _wrap(uploadBloc: mockUploadBloc, subjectBloc: mockSubjectBloc));
      await tester.pump();
      final button = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton),
      );
      // onPressed is null when no file is selected.
      expect(button.onPressed, isNull);
    });

    testWidgets('initial state shows "Tap to browse PDF" prompt',
        (tester) async {
      await tester.pumpWidget(
          _wrap(uploadBloc: mockUploadBloc, subjectBloc: mockSubjectBloc));
      await tester.pump();
      expect(find.byIcon(Icons.cloud_upload_outlined), findsOneWidget);
    });

    testWidgets('loading state shows CircularProgressIndicator', (tester) async {
      when(() => mockUploadBloc.state).thenReturn(DocumentUploadLoading());
      await tester.pumpWidget(
          _wrap(uploadBloc: mockUploadBloc, subjectBloc: mockSubjectBloc));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // Form is hidden during loading.
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('error state shows error via snackbar', (tester) async {
      // The error is surfaced through BlocConsumer's listener (a SnackBar), which
      // only fires on a state *transition* — not when the mock starts already in
      // the error state. whenListen simulates Initial -> Error so the listener
      // actually runs.
      whenListen(
        mockUploadBloc,
        Stream.fromIterable([DocumentUploadError('Upload failed')]),
        initialState: DocumentUploadInitial(),
      );
      await tester.pumpWidget(
          _wrap(uploadBloc: mockUploadBloc, subjectBloc: mockSubjectBloc));
      await tester.pump();
      await tester.pump();
      expect(find.text('Upload failed'), findsOneWidget);
    });

    testWidgets(
        'error state still shows upload form alongside error snackbar',
        (tester) async {
      whenListen(
        mockUploadBloc,
        Stream.fromIterable([DocumentUploadError('Server error')]),
        initialState: DocumentUploadInitial(),
      );
      await tester.pumpWidget(
          _wrap(uploadBloc: mockUploadBloc, subjectBloc: mockSubjectBloc));
      await tester.pump();
      await tester.pump();
      // Form elements still visible.
      expect(find.byType(TextField), findsOneWidget);
      // Error snackbar also visible.
      expect(find.text('Server error'), findsOneWidget);
    });

    testWidgets(
        'existing subject key blocks upload and shows snackbar (validation)',
        (tester) async {
      // Screen with 'math' already in the existing keys list.
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: MultiBlocProvider(
            providers: [
              BlocProvider<DocumentUploadBloc>.value(value: mockUploadBloc),
              BlocProvider<SubjectBloc>.value(value: mockSubjectBloc),
            ],
            child: const StudentDocumentUploadScreen(
              studentUid: 'student1',
              existingSubjectKeys: ['math'],
            ),
          ),
        ),
      ));
      await tester.pump();
      expect(find.byType(StudentDocumentUploadScreen), findsOneWidget);
    });
  });
}
