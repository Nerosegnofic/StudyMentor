import 'package:equatable/equatable.dart';

abstract class NotificationsEvent extends Equatable {
  const NotificationsEvent();

  @override
  List<Object?> get props => [];
}

// ── Load ────────────────────────────────────────────────────────────────────

class LoadNotificationsRequested extends NotificationsEvent {
  final String parentUid;

  const LoadNotificationsRequested(this.parentUid);

  @override
  List<Object?> get props => [parentUid];
}

class LoadStudentNotificationsRequested extends NotificationsEvent {
  final String studentUid;

  const LoadStudentNotificationsRequested(this.studentUid);

  @override
  List<Object?> get props => [studentUid];
}

// ── Mark all read ────────────────────────────────────────────────────────────

class MarkAllNotificationsReadRequested extends NotificationsEvent {
  final String parentUid;

  const MarkAllNotificationsReadRequested(this.parentUid);

  @override
  List<Object?> get props => [parentUid];
}

class MarkAllStudentNotificationsReadRequested extends NotificationsEvent {
  final String studentUid;

  const MarkAllStudentNotificationsReadRequested(this.studentUid);

  @override
  List<Object?> get props => [studentUid];
}

// ── Toggle read ──────────────────────────────────────────────────────────────

class ToggleParentNotificationReadRequested extends NotificationsEvent {
  final String id;
  final bool isRead;

  const ToggleParentNotificationReadRequested(this.id, {required this.isRead});

  @override
  List<Object?> get props => [id, isRead];
}

class ToggleStudentNotificationReadRequested extends NotificationsEvent {
  final String id;
  final bool isRead;

  const ToggleStudentNotificationReadRequested(this.id, {required this.isRead});

  @override
  List<Object?> get props => [id, isRead];
}

// ── Delete ───────────────────────────────────────────────────────────────────

class DeleteParentNotificationRequested extends NotificationsEvent {
  final String id;

  const DeleteParentNotificationRequested(this.id);

  @override
  List<Object?> get props => [id];
}

class DeleteStudentNotificationRequested extends NotificationsEvent {
  final String id;

  const DeleteStudentNotificationRequested(this.id);

  @override
  List<Object?> get props => [id];
}
