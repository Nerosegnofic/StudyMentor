import 'package:equatable/equatable.dart';

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

  CreateStudentRequested({
    required this.fullName,
    required this.email,
    required this.password,
    required this.parentUid,
  });

  @override
  List<Object?> get props => [fullName, email, parentUid];
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

/// Fired when a student taps the logout button.
/// The bloc will check the user's role and either logout directly (Parent)
/// or emit a state that tells the UI to show the parent-verification dialog.
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