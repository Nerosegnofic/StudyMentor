// lib/src/bloc/auth/auth_event.dart

import 'package:equatable/equatable.dart';
import '../../domain/models/student_model.dart';

abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AppStarted extends AuthEvent {}

class RegisterRequested extends AuthEvent {
  final String fullName;
  final String email;
  final String password;

  RegisterRequested({
    required this.fullName,
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [fullName, email];
}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;
  LoginRequested({required this.email, required this.password});
  @override
  List<Object?> get props => [email];
}

class LogoutRequested extends AuthEvent {}

class SendEmailVerificationRequested extends AuthEvent {}

class CheckEmailVerificationRequested extends AuthEvent {}

class PasswordResetRequested extends AuthEvent {
  final String email;
  PasswordResetRequested({required this.email});
  @override
  List<Object?> get props => [email];
}

class CreateStudentRequested extends AuthEvent {
  final String fullName;
  final String email;
  final String password;
  final String parentUid;
  final int gradeLevel;

  CreateStudentRequested({
    required this.fullName,
    required this.email,
    required this.password,
    required this.parentUid,
    required this.gradeLevel,
  });

  @override
  List<Object?> get props => [fullName, email, parentUid, gradeLevel];
}

class LoadStudentsRequested extends AuthEvent {
  final String parentUid;
  LoadStudentsRequested({required this.parentUid});
  @override
  List<Object?> get props => [parentUid];
}

class LoadParentNameRequested extends AuthEvent {
  final String studentUid;
  LoadParentNameRequested({required this.studentUid});
  @override
  List<Object?> get props => [studentUid];
}

/// Fired periodically by ParentScreen to re-check the email-verification
/// status of any students that are still unverified.
class RefreshStudentVerificationsRequested extends AuthEvent {
  final List<StudentModel> currentStudents;
  RefreshStudentVerificationsRequested({required this.currentStudents});
  @override
  List<Object?> get props => [currentStudents];
}

/// Fired when a student taps the logout button.
class StudentLogoutVerificationRequested extends AuthEvent {
  final String studentUid;
  StudentLogoutVerificationRequested({required this.studentUid});
  @override
  List<Object?> get props => [studentUid];
}

/// Fired when the student submits the parent credentials in the dialog.
class VerifyParentAndLogoutRequested extends AuthEvent {
  final String studentUid;
  final String parentEmail;
  final String parentPassword;

  VerifyParentAndLogoutRequested({
    required this.studentUid,
    required this.parentEmail,
    required this.parentPassword,
  });

  @override
  List<Object?> get props => [studentUid, parentEmail];
}
