// test/repositories/ai_engine_repository_test.dart
//
// Unit tests for AiEngineRepository using an injectable http.Client mock and a
// FirebaseAuth mock, so no Firebase singleton is touched.

import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:studymentor/src/data/repositories/ai_engine_repository.dart';

// ── Mocks ─────────────────────────────────────────────────────────────────────

class MockHttpClient extends Mock implements http.Client {}

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

// ── Helpers ───────────────────────────────────────────────────────────────────

const _kBase = 'http://localhost:8000';

AiEngineRepository _makeRepo({
  required http.Client client,
  required FirebaseAuth auth,
}) =>
    AiEngineRepository(baseUrl: _kBase, auth: auth, client: client);

void main() {
  late MockHttpClient mockClient;
  late MockFirebaseAuth mockAuth;
  late MockUser mockUser;

  setUpAll(() {
    registerFallbackValue(Uri.parse('http://localhost'));
    registerFallbackValue(<String, String>{});
  });

  setUp(() {
    mockClient = MockHttpClient();
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser();

    // Every test: auth returns a valid user with a token.
    when(() => mockAuth.currentUser).thenReturn(mockUser);
    when(() => mockUser.getIdToken(any())).thenAnswer((_) async => 'fake_token');
  });

  group('AiEngineRepository', () {
    group('getGarden', () {
      test('returns list of GardenPlantModel on 200', () async {
        final body = jsonEncode([
          {
            'subject_id': 1,
            'subject_name': 'Math',
            'mastery_percent': 35.0,
          },
        ]);
        when(() => mockClient.get(any(), headers: any(named: 'headers')))
            .thenAnswer((_) async => http.Response(body, 200));

        final repo = _makeRepo(client: mockClient, auth: mockAuth);
        final plants = await repo.getGarden();

        expect(plants.length, 1);
        expect(plants.first.subjectName, 'Math');
      });

      test('throws when server returns non-200', () async {
        when(() => mockClient.get(any(), headers: any(named: 'headers')))
            .thenAnswer((_) async => http.Response('Internal Error', 500));

        final repo = _makeRepo(client: mockClient, auth: mockAuth);

        expect(repo.getGarden(), throwsException);
      });
    });

    group('getSubjectSkills', () {
      test('returns skills list on 200', () async {
        final body = jsonEncode([
          {
            'skill_id': 10,
            'name': 'Algebra',
            'mastery_percent': 70.0,
            'is_mastered': false,
            'attempts': 3,
          },
        ]);
        when(() => mockClient.get(any(), headers: any(named: 'headers')))
            .thenAnswer((_) async => http.Response(body, 200));

        final repo = _makeRepo(client: mockClient, auth: mockAuth);
        final skills = await repo.getSubjectSkills(1);

        expect(skills.length, 1);
        expect(skills.first.name, 'Algebra');
      });

      test('throws on 404', () async {
        when(() => mockClient.get(any(), headers: any(named: 'headers')))
            .thenAnswer((_) async => http.Response('not found', 404));

        final repo = _makeRepo(client: mockClient, auth: mockAuth);

        expect(repo.getSubjectSkills(999), throwsException);
      });
    });

    group('generateQuiz', () {
      test('throws when user not authenticated', () async {
        when(() => mockAuth.currentUser).thenReturn(null);

        final repo = _makeRepo(client: mockClient, auth: mockAuth);
        final request = const GenerateQuizRequest(totalQuestions: 5);

        expect(repo.generateQuiz(request), throwsException);
      });

      test('throws SubjectStillProcessingException on 409', () async {
        when(() => mockClient.post(
              any(),
              headers: any(named: 'headers'),
              body: any(named: 'body'),
            )).thenAnswer((_) async => http.Response('still processing', 409));

        final repo = _makeRepo(client: mockClient, auth: mockAuth);
        final request = const GenerateQuizRequest(totalQuestions: 5);

        expect(
          repo.generateQuiz(request),
          throwsA(isA<SubjectStillProcessingException>()),
        );
      });
    });

    group('getSubjectsStatus', () {
      test('returns list of SubjectStatus on 200', () async {
        final body = jsonEncode({
          'subjects': [
            {
              'subject_id': 2,
              'subject_name': 'Science',
              'state': 'ready',
              'stage': null,
              'has_skills': true,
            },
          ],
        });
        when(() => mockClient.get(any(), headers: any(named: 'headers')))
            .thenAnswer((_) async => http.Response(body, 200));

        final repo = _makeRepo(client: mockClient, auth: mockAuth);
        final statuses = await repo.getSubjectsStatus();

        expect(statuses.length, 1);
        expect(statuses.first.state, 'ready');
      });
    });
  });
}
