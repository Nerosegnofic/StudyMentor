// test/repositories/auth_repository_impl_test.dart
//
// Unit tests for AuthRepositoryImpl. FirebaseAuthProvider and
// DataConnectProvider are mocked via Mocktail's `implements` (no Firebase
// singleton is created).

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:studymentor/src/data/providers/dataconnect_provider.dart';
import 'package:studymentor/src/data/providers/firebase_auth_provider.dart';
import 'package:studymentor/src/data/repositories/auth_repository_impl.dart';
import 'package:studymentor/src/domain/models/user_model.dart';

class MockFirebaseAuthProvider extends Mock implements FirebaseAuthProvider {}

class MockDataConnectProvider extends Mock implements DataConnectProvider {}

class MockUser extends Mock implements User {}

void main() {
  late MockFirebaseAuthProvider mockFirebase;
  late MockDataConnectProvider mockDataConnect;
  late AuthRepositoryImpl repo;

  final fakeUserJson = {
    'uid': 'uid_123',
    'email': 'parent@example.com',
    'full_name': 'Sara Ali',
    'role': 'Parent',
    'is_active': true,
    'created_at': '2025-01-01T00:00:00.000Z',
  };

  setUp(() {
    mockFirebase = MockFirebaseAuthProvider();
    mockDataConnect = MockDataConnectProvider();
    repo = AuthRepositoryImpl(
      firebase: mockFirebase,
      dataConnect: mockDataConnect,
    );
  });

  group('AuthRepositoryImpl', () {
    group('signOut', () {
      test('delegates to FirebaseAuthProvider.signOut', () async {
        when(() => mockFirebase.signOut()).thenAnswer((_) async {});

        await repo.signOut();

        verify(() => mockFirebase.signOut()).called(1);
      });
    });

    group('sendPasswordReset', () {
      test('delegates to FirebaseAuthProvider', () async {
        when(() => mockFirebase.sendPasswordReset(any()))
            .thenAnswer((_) async {});

        await repo.sendPasswordReset('user@example.com');

        verify(() => mockFirebase.sendPasswordReset('user@example.com'))
            .called(1);
      });
    });

    group('isEmailVerified', () {
      test('returns true when firebase user is verified', () async {
        final mockUser = MockUser();
        when(() => mockUser.emailVerified).thenReturn(true);
        when(() => mockFirebase.reloadUser()).thenAnswer((_) async {});
        when(() => mockFirebase.currentUser).thenReturn(mockUser);

        final result = await repo.isEmailVerified();

        expect(result, isTrue);
      });

      test('returns false when no user is signed in', () async {
        when(() => mockFirebase.reloadUser()).thenAnswer((_) async {});
        when(() => mockFirebase.currentUser).thenReturn(null);

        final result = await repo.isEmailVerified();

        expect(result, isFalse);
      });
    });

    group('getUserProfile', () {
      test('returns null when no user is signed in', () async {
        when(() => mockFirebase.currentUser).thenReturn(null);

        final result = await repo.getUserProfile();

        expect(result, isNull);
      });

      test('returns UserModel when profile exists', () async {
        final mockUser = MockUser();
        when(() => mockUser.uid).thenReturn('uid_123');
        when(() => mockFirebase.currentUser).thenReturn(mockUser);
        when(() => mockDataConnect.getUserProfile('uid_123'))
            .thenAnswer((_) async => fakeUserJson);

        final result = await repo.getUserProfile();

        expect(result, isA<UserModel>());
        expect(result?.fullName, 'Sara Ali');
        expect(result?.email, 'parent@example.com');
      });
    });
  });
}
