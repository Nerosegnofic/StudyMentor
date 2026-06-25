// test/bloc/notifications_bloc_test.dart
//
// Unit tests for NotificationsBloc — covers all three event handlers.

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:studymentor/src/bloc/notifications/notifications_bloc.dart';
import 'package:studymentor/src/bloc/notifications/notifications_event.dart';
import 'package:studymentor/src/bloc/notifications/notifications_state.dart';
import 'package:studymentor/src/domain/models/notification_model.dart';
import 'package:studymentor/src/domain/repositories/auth_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

NotificationModel _fakeNotif({bool isRead = false}) => NotificationModel(
      id: 'n1',
      parentUid: 'parent1',
      studentUid: 'student1',
      type: NotificationType.streakAchieved,
      title: 'Great job!',
      subtitle: 'Your child hit a 7-day streak.',
      createdAt: DateTime(2026, 6, 1),
      isRead: isRead,
    );

void main() {
  late MockAuthRepository mockRepo;

  setUp(() {
    mockRepo = MockAuthRepository();
  });

  group('LoadNotificationsRequested', () {
    blocTest<NotificationsBloc, NotificationsState>(
      'emits [Loaded] on success',
      build: () {
        when(() => mockRepo.getNotificationsForParent('parent1'))
            .thenAnswer((_) async => [_fakeNotif()]);
        return NotificationsBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(const LoadNotificationsRequested('parent1')),
      expect: () => [
        isA<NotificationsLoaded>().having(
          (s) => s.notifications.length,
          'notifications count',
          1,
        ),
      ],
    );

    blocTest<NotificationsBloc, NotificationsState>(
      'emits nothing when repository throws (silent failure)',
      build: () {
        when(() => mockRepo.getNotificationsForParent(any()))
            .thenThrow(Exception('network error'));
        return NotificationsBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(const LoadNotificationsRequested('parent1')),
      expect: () => <NotificationsState>[],
    );

    blocTest<NotificationsBloc, NotificationsState>(
      'emits Loaded with empty list when there are no notifications',
      build: () {
        when(() => mockRepo.getNotificationsForParent(any()))
            .thenAnswer((_) async => []);
        return NotificationsBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(const LoadNotificationsRequested('parent1')),
      expect: () => [NotificationsLoaded(const [])],
    );
  });

  group('LoadStudentNotificationsRequested', () {
    blocTest<NotificationsBloc, NotificationsState>(
      'emits [Loaded] on success',
      build: () {
        when(() => mockRepo.getNotificationsForStudent('student1'))
            .thenAnswer((_) async => [_fakeNotif()]);
        return NotificationsBloc(repository: mockRepo);
      },
      act: (bloc) =>
          bloc.add(const LoadStudentNotificationsRequested('student1')),
      expect: () => [isA<NotificationsLoaded>()],
    );

    blocTest<NotificationsBloc, NotificationsState>(
      'emits nothing when repository throws (silent failure)',
      build: () {
        when(() => mockRepo.getNotificationsForStudent(any()))
            .thenThrow(Exception('timeout'));
        return NotificationsBloc(repository: mockRepo);
      },
      act: (bloc) =>
          bloc.add(const LoadStudentNotificationsRequested('student1')),
      expect: () => <NotificationsState>[],
    );
  });

  group('MarkAllNotificationsReadRequested', () {
    blocTest<NotificationsBloc, NotificationsState>(
      'marks all notifications as read when state is NotificationsLoaded',
      build: () {
        when(() => mockRepo.markAllNotificationsRead('parent1'))
            .thenAnswer((_) async {});
        return NotificationsBloc(repository: mockRepo);
      },
      seed: () => NotificationsLoaded([_fakeNotif(isRead: false)]),
      act: (bloc) =>
          bloc.add(const MarkAllNotificationsReadRequested('parent1')),
      expect: () => [
        isA<NotificationsLoaded>().having(
          (s) => s.notifications.every((n) => n.isRead),
          'all isRead',
          isTrue,
        ),
      ],
    );

    blocTest<NotificationsBloc, NotificationsState>(
      'reverts optimistic update when markAllNotificationsRead throws',
      build: () {
        when(() => mockRepo.markAllNotificationsRead(any()))
            .thenThrow(Exception('server error'));
        return NotificationsBloc(repository: mockRepo);
      },
      seed: () => NotificationsLoaded([_fakeNotif(isRead: false)]),
      act: (bloc) =>
          bloc.add(const MarkAllNotificationsReadRequested('parent1')),
      expect: () => [
        // optimistic update (all read)
        isA<NotificationsLoaded>().having(
          (s) => s.notifications.every((n) => n.isRead),
          'optimistically all read',
          isTrue,
        ),
        // revert (back to unread)
        isA<NotificationsLoaded>().having(
          (s) => s.notifications.every((n) => !n.isRead),
          'reverted to unread',
          isTrue,
        ),
      ],
    );

    blocTest<NotificationsBloc, NotificationsState>(
      'does nothing when state is not NotificationsLoaded',
      build: () => NotificationsBloc(repository: mockRepo),
      act: (bloc) =>
          bloc.add(const MarkAllNotificationsReadRequested('parent1')),
      expect: () => <NotificationsState>[],
      verify: (_) {
        verifyNever(() => mockRepo.markAllNotificationsRead(any()));
      },
    );
  });
}
