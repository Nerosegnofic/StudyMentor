// test/bloc/parent_profile_bloc_test.dart
//
// Unit tests for ParentProfileBloc.

import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:studymentor/src/bloc/parent_profile/parent_profile_bloc.dart';
import 'package:studymentor/src/bloc/parent_profile/parent_profile_event.dart';
import 'package:studymentor/src/bloc/parent_profile/parent_profile_state.dart';

import 'auth_bloc_test.dart' show FakeAuthRepository;

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

FakeAuthRepository _repoOk() => FakeAuthRepository();
FakeAuthRepository _repoThrows(String msg) =>
    FakeAuthRepository(shouldThrow: true, errorMessage: msg);

const _parentUid = 'uid-parent';

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('ParentProfileBloc', () {
    // ── UpdateParentProfileRequested ─────────────────────────────────────────

    group('UpdateParentProfileRequested', () {
      blocTest<ParentProfileBloc, ParentProfileState>(
        'emits [ParentProfileLoading, ParentProfileUpdateSuccess] on success',
        build: () => ParentProfileBloc(repository: _repoOk()),
        act: (bloc) => bloc.add(
          const UpdateParentProfileRequested(
            parentUid: _parentUid,
            newFullName: 'New Parent Name',
          ),
        ),
        expect: () => [
          isA<ParentProfileLoading>(),
          isA<ParentProfileUpdateSuccess>(),
        ],
      );

      blocTest<ParentProfileBloc, ParentProfileState>(
        'emits error with "Current password is incorrect." on wrong-password',
        build: () => ParentProfileBloc(
          repository: _repoThrows('wrong-password'),
        ),
        act: (bloc) => bloc.add(
          const UpdateParentProfileRequested(
            parentUid: _parentUid,
            currentPassword: 'bad',
            newPassword: 'newpass',
          ),
        ),
        expect: () => [
          isA<ParentProfileLoading>(),
          isA<ParentProfileError>().having(
            (s) => s.message,
            'message',
            'Current password is incorrect.',
          ),
        ],
      );

      blocTest<ParentProfileBloc, ParentProfileState>(
        'emits error with "weak" message on weak-password',
        build: () => ParentProfileBloc(
          repository: _repoThrows('weak-password'),
        ),
        act: (bloc) => bloc.add(
          const UpdateParentProfileRequested(
            parentUid: _parentUid,
            newPassword: '123',
          ),
        ),
        expect: () => [
          isA<ParentProfileLoading>(),
          isA<ParentProfileError>().having(
            (s) => s.message,
            'message',
            contains('weak'),
          ),
        ],
      );

      blocTest<ParentProfileBloc, ParentProfileState>(
        'emits error with network message on network failure',
        build: () => ParentProfileBloc(
          repository: _repoThrows('network-request-failed'),
        ),
        act: (bloc) => bloc.add(
          const UpdateParentProfileRequested(parentUid: _parentUid),
        ),
        expect: () => [
          isA<ParentProfileLoading>(),
          isA<ParentProfileError>().having(
            (s) => s.message,
            'message',
            contains('Network error'),
          ),
        ],
      );

      blocTest<ParentProfileBloc, ParentProfileState>(
        'emits error with email-in-use message',
        build: () => ParentProfileBloc(
          repository: _repoThrows('email-already-in-use'),
        ),
        act: (bloc) => bloc.add(
          const UpdateParentProfileRequested(
            parentUid: _parentUid,
            newEmail: 'taken@test.com',
          ),
        ),
        expect: () => [
          isA<ParentProfileLoading>(),
          isA<ParentProfileError>().having(
            (s) => s.message,
            'message',
            contains('already in use'),
          ),
        ],
      );

      blocTest<ParentProfileBloc, ParentProfileState>(
        'emits generic error for unknown exceptions',
        build: () => ParentProfileBloc(
          repository: _repoThrows('some-unknown-error'),
        ),
        act: (bloc) => bloc.add(
          const UpdateParentProfileRequested(parentUid: _parentUid),
        ),
        expect: () => [
          isA<ParentProfileLoading>(),
          isA<ParentProfileError>().having(
            (s) => s.message,
            'message',
            'Update failed. Please try again.',
          ),
        ],
      );
    });

    // ── DeleteParentAccountRequested ─────────────────────────────────────────

    group('DeleteParentAccountRequested', () {
      blocTest<ParentProfileBloc, ParentProfileState>(
        'emits [ParentProfileLoading, ParentAccountDeleted] on success',
        build: () => ParentProfileBloc(repository: _repoOk()),
        act: (bloc) => bloc.add(
          const DeleteParentAccountRequested(
            parentUid: _parentUid,
            currentPassword: 'correct',
          ),
        ),
        expect: () => [
          isA<ParentProfileLoading>(),
          isA<ParentAccountDeleted>(),
        ],
      );

      blocTest<ParentProfileBloc, ParentProfileState>(
        'emits [ParentProfileLoading, ParentProfileError] on wrong password',
        build: () => ParentProfileBloc(
          repository: _repoThrows('wrong-password'),
        ),
        act: (bloc) => bloc.add(
          const DeleteParentAccountRequested(
            parentUid: _parentUid,
            currentPassword: 'wrong',
          ),
        ),
        expect: () => [
          isA<ParentProfileLoading>(),
          isA<ParentProfileError>().having(
            (s) => s.message,
            'message',
            'Current password is incorrect.',
          ),
        ],
      );

      blocTest<ParentProfileBloc, ParentProfileState>(
        'emits error with network message on network failure',
        build: () => ParentProfileBloc(
          repository: _repoThrows('network-request-failed'),
        ),
        act: (bloc) => bloc.add(
          const DeleteParentAccountRequested(
            parentUid: _parentUid,
            currentPassword: 'pass',
          ),
        ),
        expect: () => [
          isA<ParentProfileLoading>(),
          isA<ParentProfileError>().having(
            (s) => s.message,
            'message',
            contains('Network error'),
          ),
        ],
      );
    });
  });
}
