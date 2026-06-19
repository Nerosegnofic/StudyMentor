// test/bloc/student_profile_bloc_test.dart
//
// Unit tests for StudentProfileBloc.

import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:studymentor/src/bloc/student_profile/student_profile_bloc.dart';
import 'package:studymentor/src/bloc/student_profile/student_profile_event.dart';
import 'package:studymentor/src/bloc/student_profile/student_profile_state.dart';
import 'package:studymentor/src/domain/models/student_model.dart';

// Reuse the full-featured fake defined in auth_bloc_test by importing directly
// from the auth_repository abstraction — or define a minimal one here.
import 'auth_bloc_test.dart' show FakeAuthRepository;

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

StudentModel _updatedStudent({
  String uid = 'uid-student',
  String fullName = 'Updated Name',
  String email = 'student@test.com',
}) =>
    StudentModel(uid: uid, fullName: fullName, email: email);

FakeAuthRepository _repoOk() => FakeAuthRepository();
FakeAuthRepository _repoThrows(String msg) => FakeAuthRepository(
      shouldThrow: true,
      errorMessage: msg,
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('StudentProfileBloc', () {
    // ── UpdateStudentProfileRequested ────────────────────────────────────────

    group('UpdateStudentProfileRequested', () {
      blocTest<StudentProfileBloc, StudentProfileState>(
        'emits [StudentProfileLoading, StudentProfileUpdateSuccess] on success',
        build: () => StudentProfileBloc(repository: _repoOk()),
        act: (bloc) => bloc.add(
          const UpdateStudentProfileRequested(
            studentUid: 'uid-student',
            studentEmail: 'student@test.com',
            newFullName: 'Updated Name',
          ),
        ),
        expect: () => [
          isA<StudentProfileLoading>(),
          isA<StudentProfileUpdateSuccess>().having(
            (s) => s.updatedStudent.uid,
            'uid',
            'uid-student',
          ),
        ],
      );

      blocTest<StudentProfileBloc, StudentProfileState>(
        'emits [StudentProfileLoading, StudentProfileError] with '
        '"Current password is incorrect." on wrong-password',
        build: () => StudentProfileBloc(
          repository: _repoThrows('wrong-password'),
        ),
        act: (bloc) => bloc.add(
          const UpdateStudentProfileRequested(
            studentUid: 'uid-student',
            studentEmail: 'student@test.com',
            currentPassword: 'bad',
            newPassword: 'newpass123',
          ),
        ),
        expect: () => [
          isA<StudentProfileLoading>(),
          isA<StudentProfileError>().having(
            (s) => s.message,
            'message',
            'Current password is incorrect.',
          ),
        ],
      );

      blocTest<StudentProfileBloc, StudentProfileState>(
        'emits error with "weak" message on weak-password',
        build: () => StudentProfileBloc(
          repository: _repoThrows('weak-password'),
        ),
        act: (bloc) => bloc.add(
          const UpdateStudentProfileRequested(
            studentUid: 'uid-student',
            studentEmail: 'student@test.com',
            newPassword: '123',
          ),
        ),
        expect: () => [
          isA<StudentProfileLoading>(),
          isA<StudentProfileError>().having(
            (s) => s.message,
            'message',
            contains('weak'),
          ),
        ],
      );

      blocTest<StudentProfileBloc, StudentProfileState>(
        'emits error with network message on network failure',
        build: () => StudentProfileBloc(
          repository: _repoThrows('network-request-failed'),
        ),
        act: (bloc) => bloc.add(
          const UpdateStudentProfileRequested(
            studentUid: 'uid-student',
            studentEmail: 'student@test.com',
          ),
        ),
        expect: () => [
          isA<StudentProfileLoading>(),
          isA<StudentProfileError>().having(
            (s) => s.message,
            'message',
            contains('Network error'),
          ),
        ],
      );

      blocTest<StudentProfileBloc, StudentProfileState>(
        'emits error with email-in-use message',
        build: () => StudentProfileBloc(
          repository: _repoThrows('email-already-in-use'),
        ),
        act: (bloc) => bloc.add(
          const UpdateStudentProfileRequested(
            studentUid: 'uid-student',
            studentEmail: 'student@test.com',
            newEmail: 'taken@test.com',
          ),
        ),
        expect: () => [
          isA<StudentProfileLoading>(),
          isA<StudentProfileError>().having(
            (s) => s.message,
            'message',
            contains('already in use'),
          ),
        ],
      );

      blocTest<StudentProfileBloc, StudentProfileState>(
        'emits generic error message for unknown exceptions',
        build: () => StudentProfileBloc(
          repository: _repoThrows('some-unknown-firebase-error'),
        ),
        act: (bloc) => bloc.add(
          const UpdateStudentProfileRequested(
            studentUid: 'uid-student',
            studentEmail: 'student@test.com',
          ),
        ),
        expect: () => [
          isA<StudentProfileLoading>(),
          isA<StudentProfileError>().having(
            (s) => s.message,
            'message',
            'Update failed. Please try again.',
          ),
        ],
      );
    });
  });
}
