import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/auth_repository.dart';
import 'students_event.dart';
import 'students_state.dart';

class StudentsBloc extends Bloc<StudentsEvent, StudentsState> {
  final AuthRepository repository;

  StudentsBloc({required this.repository}) : super(StudentsInitial()) {
    on<LoadStudentsRequested>(_onLoadStudents);
    on<CreateStudentRequested>(_onCreateStudent);
    on<RefreshStudentVerificationsRequested>(_onRefreshStudentVerifications);
    on<DeleteStudentRequested>(_onDeleteStudent);
  }

  Future<void> _onLoadStudents(
    LoadStudentsRequested event,
    Emitter<StudentsState> emit,
  ) async {
    emit(StudentsLoading());
    try {
      final students = await repository.getStudentsByParent(event.parentUid);
      emit(StudentsLoaded(students));
    } catch (e) {
      emit(StudentsError(e.toString()));
    }
  }

  Future<void> _onCreateStudent(
    CreateStudentRequested event,
    Emitter<StudentsState> emit,
  ) async {
    emit(StudentCreateLoading());
    try {
      await repository.createStudent(
        fullName: event.fullName,
        email: event.email,
        password: event.password,
        parentUid: event.parentUid,
        gradeLevel: event.gradeLevel,
        username: event.username,
      );
      emit(StudentCreated());
    } catch (e) {
      emit(StudentCreateError(_mapRegistrationException(e)));
    }
  }

  Future<void> _onRefreshStudentVerifications(
    RefreshStudentVerificationsRequested event,
    Emitter<StudentsState> emit,
  ) async {
    try {
      final updated = await repository.refreshStudentVerificationStatus(
        event.currentStudents,
      );

      final changed = updated.any((s) {
        final old = event.currentStudents.firstWhere((o) => o.uid == s.uid);
        return old.isEmailVerified != s.isEmailVerified;
      });

      if (changed) {
        emit(StudentsLoaded(updated));
      }
    } catch (_) {}
  }

  Future<void> _onDeleteStudent(
    DeleteStudentRequested event,
    Emitter<StudentsState> emit,
  ) async {
    emit(StudentDeleteLoading());
    try {

      // parentUid is intentionally omitted — the repository deleteStudent
      // method only requires the student's own credentials to remove their
      // Auth account and database records.
      await repository.deleteStudent(
        studentUid: event.studentUid,
        studentEmail: event.studentEmail,
        studentPassword: event.studentPassword,
      );
      emit(StudentDeleted(event.studentUid));
    } catch (e) {
      emit(StudentDeleteError(_mapDeletionException(e)));
    }
  }

  String _mapDeletionException(dynamic e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('wrong-password') ||
        msg.contains('invalid-credential') ||
        msg.contains('invalid_login_credentials') ||
        msg.contains('user-not-found') ||
        msg.contains('invalid-email')) {
      return 'Invalid credentials';
    }
    if (msg.contains('network-request-failed')) {
      return 'Network error. Check your connection and try again.';
    }
    return 'Unable to delete account. Please try again.';
  }

  String _mapRegistrationException(dynamic e) {
    print('STUDENT_REGISTRATION_FAILED: $e');
    final str = e.toString();
    if (str.contains('Session expired')) {
      return 'Session expired. Please log out and log in again before adding a student.';
    }
    if (str.contains('username-already-in-use')) {
      return 'That username is already taken. Please choose another one.';
    }
    if (str.contains('email-already-in-use')) {
      return 'This email is already registered. Try logging in or resetting the password.';
    }
    if (str.contains('weak-password')) {
      return 'The password provided is too weak. Please use at least 6 characters.';
    }
    if (str.contains('invalid-email')) {
      return 'The email address is badly formatted.';
    }
    return 'An unexpected error occurred. Please try again.';
  }
}
