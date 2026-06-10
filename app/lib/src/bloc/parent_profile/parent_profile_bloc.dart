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
      emit(ParentProfileError(e.toString()));
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
      emit(ParentProfileError(e.toString()));
    }
  }
}
