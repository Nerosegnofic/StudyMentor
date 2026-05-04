// lib/src/bloc/auth/auth_event.dart

import 'package:equatable/equatable.dart';
import '../../domain/models/student_model.dart';
import '../../domain/models/app_config_model.dart';
import '../../domain/models/installed_app_model.dart';

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

class UpdateProfileRequested extends AuthEvent {
  final String? newFullName;
  final String? currentPassword;
  final String? newPassword;

  UpdateProfileRequested({
    this.newFullName,
    this.currentPassword,
    this.newPassword,
  });

  @override
  List<Object?> get props => [newFullName, newPassword];
}

// ── App Configuration Events ─────────────────────────────────────────────────

/// Fired when the parent opens the configuration screen for a student.
/// Loads existing saved rules from the database.
class LoadAppRulesRequested extends AuthEvent {
  final String studentUid;
  LoadAppRulesRequested({required this.studentUid});
  @override
  List<Object?> get props => [studentUid];
}

/// Fired when the parent taps "Save" on the configuration screen.
/// Replaces all existing rules with [rules] in the database.
class SaveAppRulesRequested extends AuthEvent {
  final String studentUid;
  final List<PendingAppRule> rules;

  SaveAppRulesRequested({
    required this.studentUid,
    required this.rules,
  });

  @override
  List<Object?> get props => [studentUid];
}

/// Fired by the student screen to load their own saved configs.
class LoadStudentAppConfigRequested extends AuthEvent {
  final String studentUid;
  LoadStudentAppConfigRequested({required this.studentUid});
  @override
  List<Object?> get props => [studentUid];
}

// ── Installed-App Inventory Events ───────────────────────────────────────────

/// Fired by the student device on login and on every app resume when the
/// dirty flag is set. Fetches apps from PackageManager via
/// [InstalledAppsService] and syncs the result to DataConnect, then clears
/// the dirty flag.
class SyncInstalledAppsRequested extends AuthEvent {
  final String studentUid;
  SyncInstalledAppsRequested({required this.studentUid});
  @override
  List<Object?> get props => [studentUid];
}

/// Fired by the parent's [StudentConfigScreen] when it opens, to load the
/// student's installed-app inventory for the picker.
class LoadInstalledAppsForStudentRequested extends AuthEvent {
  final String studentUid;
  LoadInstalledAppsForStudentRequested({required this.studentUid});
  @override
  List<Object?> get props => [studentUid];
}
