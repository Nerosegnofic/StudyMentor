import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/auth_repository.dart';
import 'notifications_event.dart';
import 'notifications_state.dart';

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final AuthRepository repository;

  NotificationsBloc({required this.repository}) : super(NotificationsInitial()) {
    on<LoadNotificationsRequested>(_onLoadNotifications);
    on<MarkAllNotificationsReadRequested>(_onMarkAllNotificationsRead);
  }

  Future<void> _onLoadNotifications(
    LoadNotificationsRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(NotificationsLoading());
    try {
      final notifications = await repository.getNotificationsForParent(event.parentUid);
      emit(NotificationsLoaded(notifications));
    } catch (e) {
      emit(NotificationsError('Failed to load notifications: $e'));
    }
  }

  Future<void> _onMarkAllNotificationsRead(
    MarkAllNotificationsReadRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    if (state is NotificationsLoaded) {
      final currentState = state as NotificationsLoaded;
      try {
        await repository.markAllNotificationsRead(event.parentUid);
        final updatedList = currentState.notifications.map((n) {
          return n.copyWith(isRead: true);
        }).toList();
        emit(NotificationsLoaded(updatedList));
      } catch (e) {
        // Fallback to error or retain state, but for this demo just show error
        emit(NotificationsError('Failed to mark all as read: $e'));
      }
    }
  }
}
