import 'package:equatable/equatable.dart';
import '../../domain/models/notification_model.dart';

abstract class NotificationsState extends Equatable {
  const NotificationsState();

  @override
  List<Object?> get props => [];
}

class NotificationsInitial extends NotificationsState {}

class NotificationsLoaded extends NotificationsState {
  final List<NotificationModel> notifications;

  const NotificationsLoaded(this.notifications);

  @override
  List<Object?> get props => [notifications];
}

