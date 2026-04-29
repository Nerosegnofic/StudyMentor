// lib/src/bloc/auth/auth_state.dart

import '../../domain/models/user_model.dart';
import '../../domain/models/student_model.dart';
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

/// Emitted while the profile update network calls are in flight.
/// Distinct from [AuthLoading] so the Settings screen can show its own
/// in-place loading indicator without triggering the global root redirect.
class ProfileUpdateLoading extends AuthState {}

/// Emitted when the profile update completes successfully.
/// Contains the refreshed [UserModel] so the UI can update the name field
/// and the parent AppBar without a full re-login.
class ProfileUpdateSuccess extends AuthState {
  final UserModel updatedUser;
  ProfileUpdateSuccess(this.updatedUser);
  @override
  List<Object?> get props => [updatedUser];
}

/// Emitted when the profile update fails (e.g. wrong current password,
/// network error). Distinct from [AuthError] so it doesn't cause
/// [RootPage] to redirect to the login screen.
class ProfileUpdateError extends AuthState {
  final String message;
  ProfileUpdateError(this.message);
  @override
  List<Object?> get props => [message];
}
