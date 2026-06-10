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
      emit(StudentProfileError(e.toString()));
    }
  }
}
