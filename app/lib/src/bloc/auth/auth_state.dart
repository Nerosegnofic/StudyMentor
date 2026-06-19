// lib/src/bloc/auth/auth_state.dart

import '../../domain/models/user_model.dart';
import '../../domain/models/student_model.dart';
import '../../domain/models/app_config_model.dart';
import '../../domain/models/installed_app_model.dart';
import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthIdle extends AuthState {}

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

class LegacyStudentsLoaded extends AuthState {
  final List<StudentModel> students;
  LegacyStudentsLoaded(this.students);
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

class LegacyProfileUpdateLoading extends AuthState {}

class LegacyProfileUpdateSuccess extends AuthState {
  final UserModel updatedUser;
  LegacyProfileUpdateSuccess(this.updatedUser);
  @override
  List<Object?> get props => [updatedUser];
}

class LegacyProfileUpdateError extends AuthState {
  final String message;
  LegacyProfileUpdateError(this.message);
  @override
  List<Object?> get props => [message];
}

// â”€â”€ App Configuration States â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

/// Emitted while app rules are being loaded from the database.
/// Distinct from [AuthLoading] â€” does not affect the root navigation.
class LegacyAppConfigLoading extends AuthState {}

/// Emitted when app rules and global config have been successfully loaded.
/// [studentUid] is included so the config screen knows which student
/// these rules belong to (safe for multi-student households).
/// [config] falls back to [StudentConfigModel] defaults if the parent
/// hasn't saved a config yet.
class LegacyAppRulesLoaded extends AuthState {
  final String studentUid;
  final List<AppRuleModel> rules;
  final StudentConfigModel config;

  LegacyAppRulesLoaded({
    required this.studentUid,
    required this.rules,
    required this.config,
  });

  @override
  List<Object?> get props => [studentUid, rules, config];
}

/// Emitted while the save operation is in flight.
class LegacyAppConfigSaving extends AuthState {}

/// Emitted when the save completes successfully.
class LegacyAppConfigSaved extends AuthState {}

/// Emitted when any app config operation fails.
class LegacyAppConfigError extends AuthState {
  final String message;
  LegacyAppConfigError(this.message);
  @override
  List<Object?> get props => [message];
}

// â”€â”€ Installed-App Inventory States â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

/// Emitted while the student device is syncing its installed-app inventory
/// to DataConnect. Does not affect root navigation.
class InstalledAppsSyncing extends AuthState {}

/// Emitted when the inventory sync completes successfully.
class InstalledAppsSynced extends AuthState {}

/// Emitted when the parent's app-picker has finished loading a student's
/// installed-app inventory from DataConnect.
/// [studentUid] lets [StudentConfigScreen] verify the data is for its student.
class InstalledAppsLoaded extends AuthState {
  final String studentUid;
  final List<InstalledAppModel> apps;

  InstalledAppsLoaded({required this.studentUid, required this.apps});

  @override
  List<Object?> get props => [studentUid, apps];
}

/// Emitted when a parent-triggered refresh is in flight.
/// Distinct from [LegacyAppConfigLoading] â€" does not wipe the existing rules
/// from the screen while the new data loads.
class LegacyStudentDataRefreshing extends AuthState {}

class EmailUpdateVerificationSent extends AuthState {
  final String pendingEmail;
  EmailUpdateVerificationSent(this.pendingEmail);
  @override
  List<Object?> get props => [pendingEmail];
}

// â”€â”€ Student Deletion States â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class StudentDeleteLoading extends AuthState {}

class StudentDeleted extends AuthState {
  final String studentUid;
  StudentDeleted({required this.studentUid});
  @override
  List<Object?> get props => [studentUid];
}

class StudentDeleteError extends AuthState {
  final String message;
  StudentDeleteError(this.message);
  @override
  List<Object?> get props => [message];
}

// â”€â”€ Student Full Name Update States â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class StudentNameUpdateLoading extends AuthState {}

class StudentNameUpdateSuccess extends AuthState {
  final String studentUid;
  final String newFullName;
  StudentNameUpdateSuccess({
    required this.studentUid,
    required this.newFullName,
  });
  @override
  List<Object?> get props => [studentUid, newFullName];
}

class StudentNameUpdateError extends AuthState {
  final String message;
  StudentNameUpdateError(this.message);
  @override
  List<Object?> get props => [message];
}

// â”€â”€ Student Profile Update States (parent-side: name + email + password) â”€â”€â”€â”€â”€

class StudentLegacyProfileUpdateLoading extends AuthState {}

class StudentLegacyProfileUpdateSuccess extends AuthState {
  final String studentUid;
  final String? newFullName;

  /// Non-null if an email verification was sent to a new address.
  final String? pendingEmail;
  StudentLegacyProfileUpdateSuccess({
    required this.studentUid,
    this.newFullName,
    this.pendingEmail,
  });
  @override
  List<Object?> get props => [studentUid, newFullName, pendingEmail];
}

class LegacyStudentProfileUpdateError extends AuthState {
  final String message;
  LegacyStudentProfileUpdateError(this.message);
  @override
  List<Object?> get props => [message];
}

// â”€â”€ Parent Account Deletion States â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class LegacyParentAccountDeleteLoading extends AuthState {}

class LegacyParentAccountDeleted extends AuthState {}

class LegacyParentAccountDeleteError extends AuthState {
  final String message;
  LegacyParentAccountDeleteError(this.message);
  @override
  List<Object?> get props => [message];
}

class EmailVerificationSent extends AuthState {
  final String email;
  EmailVerificationSent(this.email);
  @override
  List<Object?> get props => [email];
}

