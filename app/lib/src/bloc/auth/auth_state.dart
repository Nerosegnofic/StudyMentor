// lib/src/bloc/auth/auth_state.dart

import '../../domain/models/user_model.dart';
import '../../domain/models/student_model.dart';
import '../../domain/models/app_config_model.dart';
import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final UserModel user;
  AuthAuthenticated(this.user);
  @override
  List<Object?> get props => [user];
}

class AuthEmailUnverified extends AuthState {
  final String email;
  AuthEmailUnverified(this.email);
  @override
  List<Object?> get props => [email];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
  @override
  List<Object?> get props => [message];
}

class EmailVerificationError extends AuthState {
  final String message;
  final String email;
  EmailVerificationError(this.message, this.email);
  @override
  List<Object?> get props => [message, email];
}

class PasswordResetEmailSent extends AuthState {}

class StudentCreated extends AuthState {}

class StudentsLoaded extends AuthState {
  final List<StudentModel> students;
  StudentsLoaded(this.students);
  @override
  List<Object?> get props => [students];
}

class ParentNameLoaded extends AuthState {
  final String parentFullName;
  ParentNameLoaded(this.parentFullName);
  @override
  List<Object?> get props => [parentFullName];
}

class StudentLogoutVerificationRequired extends AuthState {
  final String studentUid;
  StudentLogoutVerificationRequired({required this.studentUid});
  @override
  List<Object?> get props => [studentUid];
}

class ParentVerificationFailed extends AuthState {
  final String message;
  final String studentUid;
  ParentVerificationFailed({required this.message, required this.studentUid});
  @override
  List<Object?> get props => [message, studentUid];
}

class ProfileUpdateLoading extends AuthState {}

class ProfileUpdateSuccess extends AuthState {
  final UserModel updatedUser;
  ProfileUpdateSuccess(this.updatedUser);
  @override
  List<Object?> get props => [updatedUser];
}

class ProfileUpdateError extends AuthState {
  final String message;
  ProfileUpdateError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── App Configuration States ──────────────────────────────────────────────────

/// Emitted while app rules are being loaded from the database.
/// Distinct from [AuthLoading] — does not affect the root navigation.
class AppConfigLoading extends AuthState {}

/// Emitted when app rules have been successfully loaded.
/// [studentUid] is included so the config screen knows which student
/// these rules belong to (safe for multi-student households).
class AppRulesLoaded extends AuthState {
  final String studentUid;
  final List<AppRuleModel> rules;

  AppRulesLoaded({required this.studentUid, required this.rules});

  @override
  List<Object?> get props => [studentUid, rules];
}

/// Emitted while the save operation is in flight.
class AppConfigSaving extends AuthState {}

/// Emitted when the save completes successfully.
class AppConfigSaved extends AuthState {}

/// Emitted when any app config operation fails.
class AppConfigError extends AuthState {
  final String message;
  AppConfigError(this.message);
  @override
  List<Object?> get props => [message];
}
