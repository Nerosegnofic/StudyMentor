import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/auth_repository.dart';
import 'student_profile_event.dart';
import 'student_profile_state.dart';

class StudentProfileBloc extends Bloc<StudentProfileEvent, StudentProfileState> {
  final AuthRepository repository;

  StudentProfileBloc({required this.repository}) : super(StudentProfileInitial()) {
    on<UpdateStudentProfileRequested>(_onUpdateStudentProfile);
  }

  Future<void> _onUpdateStudentProfile(
    UpdateStudentProfileRequested event,
    Emitter<StudentProfileState> emit,
  ) async {
    emit(StudentProfileLoading());
    try {
      final updatedStudent = await repository.updateStudentProfile(
        studentUid: event.studentUid,
        studentEmail: event.studentEmail,
        newFullName: event.newFullName,
        newGradeLevel: event.newGradeLevel,
        newEmail: event.newEmail,
        currentPassword: event.currentPassword,
        newPassword: event.newPassword,
      );
      emit(StudentProfileUpdateSuccess(updatedStudent));
    } catch (e) {
      emit(StudentProfileError(_mapProfileError(e)));
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
}
