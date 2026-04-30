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

class RefreshStudentVerificationsRequested extends AuthEvent {
  final List<StudentModel> currentStudents;
  RefreshStudentVerificationsRequested({required this.currentStudents});
  @override
  List<Object?> get props => [currentStudents];
}

class StudentLogoutVerificationRequested extends AuthEvent {
  final String studentUid;
  StudentLogoutVerificationRequested({required this.studentUid});
  @override
  List<Object?> get props => [studentUid];
}

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

/// Fired when the parent taps "Save" on the Settings screen.
///
/// At least one of [newFullName] or [newPassword] must be non-null.
/// [currentPassword] is required whenever [newPassword] is provided —
/// Firebase needs it to reauthenticate before a password change.
class UpdateProfileRequested extends AuthEvent {
  /// New display name, or null if the name was not changed.
  final String? newFullName;

  /// The user's current password. Required when [newPassword] is set.
  final String? currentPassword;

  /// The desired new password, or null if not changing the password.
  final String? newPassword;

  UpdateProfileRequested({
    this.newFullName,
    this.currentPassword,
    this.newPassword,
  });

  @override
  List<Object?> get props => [newFullName, newPassword];
}
