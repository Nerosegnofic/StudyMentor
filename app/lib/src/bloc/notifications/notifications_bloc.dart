import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/auth_repository.dart';
import 'notifications_event.dart';
import 'notifications_state.dart';

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final AuthRepository repository;

  NotificationsBloc({required this.repository}) : super(NotificationsInitial()) {
    on<LoadNotificationsRequested>(_onLoadNotifications);
    on<LoadStudentNotificationsRequested>(_onLoadStudentNotifications);
    on<RefreshParentNotificationsRequested>(_onRefreshParentNotifications);
    on<RefreshStudentNotificationsRequested>(_onRefreshStudentNotifications);
    on<MarkAllNotificationsReadRequested>(_onMarkAllParentRead);
    on<MarkAllStudentNotificationsReadRequested>(_onMarkAllStudentRead);
    on<ToggleParentNotificationReadRequested>(_onToggleParentRead);
    on<ToggleStudentNotificationReadRequested>(_onToggleStudentRead);
    on<DeleteParentNotificationRequested>(_onDeleteParent);
    on<DeleteStudentNotificationRequested>(_onDeleteStudent);
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

  Future<void> _onLoadStudentNotifications(
    LoadStudentNotificationsRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(NotificationsLoading());
    try {
      final notifications = await repository.getNotificationsForStudent(event.studentUid);
      emit(NotificationsLoaded(notifications));
    } catch (e) {
      emit(NotificationsError('Failed to load notifications: $e'));
    }
  }

  Future<void> _onRefreshParentNotifications(
    RefreshParentNotificationsRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    try {
      final notifications = await repository.getNotificationsForParent(event.parentUid);
      emit(NotificationsLoaded(notifications));
    } catch (_) {
      // Keep current state on failure — silent refresh never clears the list.
    }
  }

  Future<void> _onRefreshStudentNotifications(
    RefreshStudentNotificationsRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    try {
      final notifications = await repository.getNotificationsForStudent(event.studentUid);
      emit(NotificationsLoaded(notifications));
    } catch (_) {
      // Keep current state on failure — silent refresh never clears the list.
    }
  }

  Future<void> _onMarkAllParentRead(
    MarkAllNotificationsReadRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    if (state is! NotificationsLoaded) return;
    final current = (state as NotificationsLoaded).notifications;
    // Optimistic update — flip isRead immediately.
    emit(NotificationsLoaded(current.map((n) => n.copyWith(isRead: true)).toList()));
    try {
      await repository.markAllNotificationsRead(event.parentUid);
    } catch (_) {
      // Revert on failure.
      emit(NotificationsLoaded(current));
    }
  }

  Future<void> _onMarkAllStudentRead(
    MarkAllStudentNotificationsReadRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    if (state is! NotificationsLoaded) return;
    final current = (state as NotificationsLoaded).notifications;
    emit(NotificationsLoaded(current.map((n) => n.copyWith(isRead: true)).toList()));
    try {
      await repository.markAllStudentNotificationsRead(event.studentUid);
    } catch (_) {
      emit(NotificationsLoaded(current));
    }
  }

  Future<void> _onToggleParentRead(
    ToggleParentNotificationReadRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    if (state is! NotificationsLoaded) return;
    final current = (state as NotificationsLoaded).notifications;
    // Optimistic update.
    emit(NotificationsLoaded(current.map((n) {
      return n.id == event.id ? n.copyWith(isRead: event.isRead) : n;
    }).toList()));
    try {
      await repository.toggleParentNotificationRead(event.id, isRead: event.isRead);
    } catch (_) {
      emit(NotificationsLoaded(current));
    }
  }

  Future<void> _onToggleStudentRead(
    ToggleStudentNotificationReadRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    if (state is! NotificationsLoaded) return;
    final current = (state as NotificationsLoaded).notifications;
    emit(NotificationsLoaded(current.map((n) {
      return n.id == event.id ? n.copyWith(isRead: event.isRead) : n;
    }).toList()));
    try {
      await repository.toggleStudentNotificationRead(event.id, isRead: event.isRead);
    } catch (_) {
      emit(NotificationsLoaded(current));
    }
  }

  Future<void> _onDeleteParent(
    DeleteParentNotificationRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    if (state is! NotificationsLoaded) return;
    final current = (state as NotificationsLoaded).notifications;
    // Optimistic removal.
    emit(NotificationsLoaded(current.where((n) => n.id != event.id).toList()));
    try {
      await repository.deleteParentNotification(event.id);
    } catch (_) {
      emit(NotificationsLoaded(current));
    }
  }

  Future<void> _onDeleteStudent(
    DeleteStudentNotificationRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    if (state is! NotificationsLoaded) return;
    final current = (state as NotificationsLoaded).notifications;
    emit(NotificationsLoaded(current.where((n) => n.id != event.id).toList()));
    try {
      await repository.deleteStudentNotification(event.id);
    } catch (_) {
      emit(NotificationsLoaded(current));
    }
  }
}
