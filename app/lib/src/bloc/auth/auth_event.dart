// lib/src/bloc/auth/auth_event.dart

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

// ── App Configuration Events ──────────────────────────────────────────────────

class LoadStudentAppConfigRequested extends AuthEvent {
  final String studentUid;
  LoadStudentAppConfigRequested({required this.studentUid});
  @override
  List<Object?> get props => [studentUid];
}

// ── Installed-App Inventory Events ────────────────────────────────────────────

class SyncInstalledAppsRequested extends AuthEvent {
  final String studentUid;
  SyncInstalledAppsRequested({required this.studentUid});
  @override
  List<Object?> get props => [studentUid];
}

class LoadInstalledAppsForStudentRequested extends AuthEvent {
  final String studentUid;
  LoadInstalledAppsForStudentRequested({required this.studentUid});
  @override
  List<Object?> get props => [studentUid];
}

// ── CHANGED: added studentEmail and studentPassword so the repository can
// sign in as the student via a secondary Firebase app and delete their
// Auth account — mirroring the updateStudentCredentials pattern.
class DeleteStudentRequested extends AuthEvent {
  final String studentUid;
  final String studentEmail;
  final String studentPassword;
  final String parentUid;

  DeleteStudentRequested({
    required this.studentUid,
    required this.studentEmail,
    required this.studentPassword,
    required this.parentUid,
  });

  @override
  List<Object?> get props => [studentUid, parentUid];
}
