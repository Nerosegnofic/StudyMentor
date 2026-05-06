// lib/src/bloc/auth/auth_event.dart

import 'package:equatable/equatable.dart';
import '../../domain/models/student_model.dart';
import '../../domain/models/app_config_model.dart';

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

// ── CHANGED: added username ───────────────────────────────────────────────────
class CreateStudentRequested extends AuthEvent {
  final String fullName;
  final String email;
  final String password;
  final String parentUid;
  final int gradeLevel;
  final String username; // ── ADDED ───────────────────────────────────────────

  CreateStudentRequested({
    required this.fullName,
    required this.email,
    required this.password,
    required this.parentUid,
    required this.gradeLevel,
    required this.username, // ── ADDED ─────────────────────────────────────────
  });

  @override
  List<Object?> get props => [fullName, email, parentUid, gradeLevel, username];
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

// ── App Configuration Events ──────────────────────────────────────────────────

class LoadAppRulesRequested extends AuthEvent {
  final String studentUid;
  LoadAppRulesRequested({required this.studentUid});
  @override
  List<Object?> get props => [studentUid];
}

class SaveAppRulesRequested extends AuthEvent {
  final String studentUid;
  final List<PendingAppRule> rules;
  final StudentConfigModel config;

  SaveAppRulesRequested({
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

class RefreshStudentDataRequested extends AuthEvent {
  final String studentUid;
  RefreshStudentDataRequested({required this.studentUid});
  @override
  List<Object?> get props => [studentUid];
}

class DeleteStudentRequested extends AuthEvent {
  final String studentUid;
  final String parentUid;

  DeleteStudentRequested({
    required this.studentUid,
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

/// Updates a student's account info from the parent side.
/// [currentPassword] is the STUDENT's current password (used to re-auth via
/// a secondary Firebase app — the parent's session is never touched).
class UpdateStudentProfileRequested extends AuthEvent {
  final String studentUid;
  final String studentEmail; // current email, needed to sign in as student
  final String? newFullName;
  final String? newEmail;
  final String? currentPassword; // student's current password
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
  List<Object?> get props => [studentUid, studentEmail, newFullName, newEmail, newPassword];
}
