import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/auth_repository.dart';
import 'parent_profile_event.dart';
import 'parent_profile_state.dart';

class ParentProfileBloc extends Bloc<ParentProfileEvent, ParentProfileState> {
  final AuthRepository repository;

  ParentProfileBloc({required this.repository}) : super(ParentProfileInitial()) {
    on<UpdateParentProfileRequested>(_onUpdateProfile);
    on<DeleteParentAccountRequested>(_onDeleteAccount);
  }

  Future<void> _onUpdateProfile(
    UpdateParentProfileRequested event,
    Emitter<ParentProfileState> emit,
  ) async {
    emit(ParentProfileLoading());
    try {
      final updatedUser = await repository.updateProfile(
        parentUid: event.parentUid,
        newFullName: event.newFullName,
        newEmail: event.newEmail,
        currentPassword: event.currentPassword,
        newPassword: event.newPassword,
      );

      if (event.newEmail != null && event.newEmail!.isNotEmpty) {
        // Technically we should check if email was actually updated and pending verification,
        // but for now we emit success with updated user. In a real app we might emit EmailVerificationPending.
        // emit(EmailVerificationPending(event.newEmail!));
      }

      emit(ParentProfileUpdateSuccess(updatedUser));
    } catch (e) {
      emit(ParentProfileError(_mapProfileError(e)));
    }
  }

  Future<void> _onDeleteAccount(
    DeleteParentAccountRequested event,
    Emitter<ParentProfileState> emit,
  ) async {
    emit(ParentProfileLoading());
    try {
      await repository.deleteParentAccount(event.currentPassword);
      emit(ParentAccountDeleted());
    } catch (e) {
      emit(ParentProfileError(_mapDeletionError(e)));
    }
  }

  String _mapProfileError(dynamic e) {
    final msg = e.toString();
    if (msg.contains('wrong-password') ||
        msg.contains('invalid-credential') ||
        msg.contains('INVALID_LOGIN_CREDENTIALS')) {
      return 'Current password is incorrect.';
    }
    if (msg.contains('weak-password')) {
      return 'New password is too weak. Use at least 6 characters.';
    }
    if (msg.contains('requires-recent-login')) {
      return 'Session expired. Please log out and log in again.';
    }
    if (msg.contains('network-request-failed')) {
      return 'Network error. Check your connection and try again.';
    }
    if (msg.contains('email-already-in-use')) {
      return 'That email address is already in use by another account.';
    }
    return 'Update failed. Please try again.';
  }

  String _mapDeletionError(dynamic e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('wrong-password') ||
        msg.contains('invalid-credential') ||
        msg.contains('invalid_login_credentials') ||
        msg.contains('user-not-found') ||
        msg.contains('invalid-email')) {
      return 'Current password is incorrect.';
    }
    if (msg.contains('network-request-failed')) {
      return 'Network error. Check your connection and try again.';
    }
    return 'Unable to delete account. Please try again.';
  }
}
