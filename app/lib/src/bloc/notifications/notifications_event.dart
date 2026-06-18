import 'package:equatable/equatable.dart';

abstract class NotificationsEvent extends Equatable {
  const NotificationsEvent();

  @override
  List<Object?> get props => [];
}

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

class MarkAllNotificationsReadRequested extends NotificationsEvent {
  final String parentUid;

  const MarkAllNotificationsReadRequested(this.parentUid);

  @override
  List<Object?> get props => [parentUid];
}
