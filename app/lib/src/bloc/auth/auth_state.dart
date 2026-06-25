// lib/src/bloc/auth/auth_state.dart

import '../../domain/models/user_model.dart';
import '../../domain/models/app_config_model.dart';
import '../../domain/models/installed_app_model.dart';
import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

// Emitted as an intermediate "reset" state to force BlocListeners to fire
// when the next state is identical to the previous one (Equatable would
// otherwise swallow the transition). Do not pattern-match on this in UI.
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

// ── App Configuration States ──────────────────────────────────────────────────

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

/// Emitted when any app config operation fails.
class LegacyAppConfigError extends AuthState {
  final String message;
  LegacyAppConfigError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── Installed-App Inventory States ────────────────────────────────────────────

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

// ── Student Deletion States ───────────────────────────────────────────────────

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

class EmailVerificationSent extends AuthState {
  final String email;
  EmailVerificationSent(this.email);
  @override
  List<Object?> get props => [email];
}
