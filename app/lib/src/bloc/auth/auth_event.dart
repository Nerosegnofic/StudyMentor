// lib/src/bloc/auth/auth_event.dart

import 'package:equatable/equatable.dart';
import '../../domain/models/student_model.dart';
import '../../domain/models/app_config_model.dart';

abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AppStarted extends AuthEvent {}

class ResetAuthState extends AuthEvent {}

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
  final String username;

  CreateStudentRequested({
    required this.fullName,
    required this.email,
    required this.password,
    required this.parentUid,
    required this.gradeLevel,
    required this.username,
  });

  @override
  List<Object?> get props => [fullName, email, parentUid, gradeLevel, username];
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

class UpdateProfileRequested extends AuthEvent {
  final String? newFullName;
  final String? newEmail;
  final String? currentPassword;
  final String? newPassword;

  UpdateProfileRequested({
    this.newFullName,
    this.newEmail,
    this.currentPassword,
    this.newPassword,
  });

  @override
  List<Object?> get props => [newFullName, newEmail, newPassword];
}

// â”€â”€ App Configuration Events â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class LegacyLoadAppRulesRequested extends AuthEvent {
  final String studentUid;
  LegacyLoadAppRulesRequested({required this.studentUid});
  @override
  List<Object?> get props => [studentUid];
}

class LegacySaveAppRulesRequested extends AuthEvent {
  final String studentUid;
  final List<PendingAppRule> rules;
  final StudentConfigModel config;

  LegacySaveAppRulesRequested({
    required this.studentUid,
    required this.rules,
    required this.config,
  });

  @override
  List<Object?> get props => [studentUid];
}

class LoadStudentAppConfigRequested extends AuthEvent {
  final String studentUid;
  LoadStudentAppConfigRequested({required this.studentUid});
  @override
  List<Object?> get props => [studentUid];
}

// â”€â”€ Installed-App Inventory Events â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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

class LegacyRefreshStudentDataRequested extends AuthEvent {
  final String studentUid;
  LegacyRefreshStudentDataRequested({required this.studentUid});
  @override
  List<Object?> get props => [studentUid];
}

// â”€â”€ CHANGED: added studentEmail and studentPassword so the repository can
// sign in as the student via a secondary Firebase app and delete their
// Auth account â€” mirroring the updateStudentCredentials pattern.
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

class UpdateStudentFullNameRequested extends AuthEvent {
  final String studentUid;
  final String fullName;

  UpdateStudentFullNameRequested({
    required this.studentUid,
    required this.fullName,
  });

  @override
  List<Object?> get props => [studentUid, fullName];
}

class DeleteParentAccountRequested extends AuthEvent {
  final String currentPassword;

  DeleteParentAccountRequested({required this.currentPassword});

  @override
  List<Object?> get props => [currentPassword];
}

class UpdateStudentProfileRequested extends AuthEvent {
  final String studentUid;
  final String studentEmail;
  final String? newFullName;
  final String? newEmail;
  final String? currentPassword;
  final String? newPassword;

  UpdateStudentProfileRequested({
    required this.studentUid,
    required this.studentEmail,
    this.newFullName,
    this.newEmail,
    this.currentPassword,
    this.newPassword,
  });

  @override
  List<Object?> get props => [
    studentUid,
    studentEmail,
    newFullName,
    newEmail,
    newPassword,
  ];
}


