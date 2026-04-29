// lib/src/bloc/auth/auth_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository repository;

  AuthBloc({required this.repository}) : super(AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<RegisterRequested>(_onRegister);
    on<LoginRequested>(_onLogin);
    on<LogoutRequested>(_onLogout);
    on<SendEmailVerificationRequested>(_onSendEmailVerification);
    on<CheckEmailVerificationRequested>(_onCheckEmailVerification);
    on<PasswordResetRequested>(_onPasswordReset);
    on<CreateStudentRequested>(_onCreateStudent);
    on<LoadStudentsRequested>(_onLoadStudents);
    on<LoadParentNameRequested>(_onLoadParentName);
    on<RefreshStudentVerificationsRequested>(_onRefreshStudentVerifications);
    on<StudentLogoutVerificationRequested>(_onStudentLogoutVerification);
    on<VerifyParentAndLogoutRequested>(_onVerifyParentAndLogout);
    on<UpdateProfileRequested>(_onUpdateProfile);
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    try {
      final profile = await repository.getUserProfile();
      if (profile != null) {
        final verified = await repository.isEmailVerified();
        if (!verified) {
          emit(AuthEmailUnverified(profile.email));
        } else {
          emit(AuthAuthenticated(profile));
        }
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onRegister(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await repository.signUp(
        fullName: event.fullName,
        email: event.email,
        password: event.password,
      );
      emit(AuthEmailUnverified(user.email));
    } catch (e) {
      emit(AuthError(_mapException(e)));
    }
  }

  Future<void> _onLogin(LoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await repository.signIn(
        email: event.email,
        password: event.password,
      );
      final verified = await repository.isEmailVerified();
      if (!verified) {
        emit(AuthEmailUnverified(user.email));
      } else {
        emit(AuthAuthenticated(user));
      }
    } catch (e) {
      emit(AuthError(_mapException(e)));
    }
  }

  Future<void> _onLogout(LogoutRequested event, Emitter<AuthState> emit) async {
    await repository.signOut();
    emit(AuthUnauthenticated());
  }

  Future<void> _onSendEmailVerification(
    SendEmailVerificationRequested event,
    Emitter<AuthState> emit,
  ) async {
    final email = (await repository.getUserProfile())?.email ?? '';
    try {
      await repository.sendEmailVerification();
      emit(AuthEmailUnverified(email));
    } catch (e) {
      emit(EmailVerificationError(_mapException(e), email));
    }
  }

  Future<void> _onCheckEmailVerification(
    CheckEmailVerificationRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final isVerified = await repository.isEmailVerified();
      if (!isVerified) {
        final email = (await repository.getUserProfile())?.email ?? '';
        emit(AuthEmailUnverified(email));
        return;
      }

      final profile = await repository.getUserProfile();
      if (profile == null) {
        emit(
          EmailVerificationError(
            'Could not load your profile. Please try again.',
            '',
          ),
        );
        return;
      }

      await repository.markEmailVerifiedInDatabase(profile.uid);
      emit(AuthAuthenticated(profile));
    } catch (e) {
      emit(EmailVerificationError(_mapException(e), ''));
    }
  }

  Future<void> _onPasswordReset(
    PasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await repository.sendPasswordReset(event.email);
      emit(PasswordResetEmailSent());
    } catch (e) {
      emit(AuthError(_mapException(e)));
    }
  }

  Future<void> _onCreateStudent(
    CreateStudentRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final parent = await repository.createStudent(
        fullName: event.fullName,
        email: event.email,
        password: event.password,
        parentUid: event.parentUid,
        gradeLevel: event.gradeLevel,
      );
      emit(StudentCreated());
      emit(AuthAuthenticated(parent));
    } catch (e) {
      emit(AuthError(_mapException(e)));
    }
  }

  Future<void> _onLoadStudents(
    LoadStudentsRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final students = await repository.getStudentsByParent(event.parentUid);
      emit(StudentsLoaded(students));
    } catch (e) {
      emit(AuthError(_mapException(e)));
    }
  }

  Future<void> _onLoadParentName(
    LoadParentNameRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final parentName = await repository.getParentFullName(event.studentUid);
      emit(ParentNameLoaded(parentName));
    } catch (e) {
      emit(ParentNameLoaded('Unknown'));
    }
  }

  Future<void> _onRefreshStudentVerifications(
    RefreshStudentVerificationsRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final updated = await repository.refreshStudentVerificationStatus(
        event.currentStudents,
      );

      final changed = updated.any((s) {
        final old = event.currentStudents.firstWhere((o) => o.uid == s.uid);
        return old.isEmailVerified != s.isEmailVerified;
      });

      if (changed) {
        emit(StudentsLoaded(updated));
      }
    } catch (_) {}
  }

  Future<void> _onStudentLogoutVerification(
    StudentLogoutVerificationRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(StudentLogoutVerificationRequired(studentUid: event.studentUid));
  }

  Future<void> _onVerifyParentAndLogout(
    VerifyParentAndLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final isValid = await repository.verifyParentCredentials(
        studentUid: event.studentUid,
        parentEmail: event.parentEmail,
        parentPassword: event.parentPassword,
      );
      if (isValid) {
        await repository.signOut();
        emit(AuthUnauthenticated());
      } else {
        emit(
          ParentVerificationFailed(
            message: 'Invalid parent credentials. Logout denied.',
            studentUid: event.studentUid,
          ),
        );
      }
    } catch (e) {
      emit(
        ParentVerificationFailed(
          message: _mapParentVerificationException(e),
          studentUid: event.studentUid,
        ),
      );
    }
  }

  // ── profile update ──────────────────────────────────────────────────────────

  Future<void> _onUpdateProfile(
    UpdateProfileRequested event,
    Emitter<AuthState> emit,
  ) async {
    // Use a dedicated loading state so RootPage doesn't interpret this as
    // a global auth loading event and redirect to the loading spinner.
    emit(ProfileUpdateLoading());
    try {
      final updatedUser = await repository.updateProfile(
        newFullName: event.newFullName,
        currentPassword: event.currentPassword,
        newPassword: event.newPassword,
      );

      // Emit success first so the Settings screen can react (show snackbar,
      // reset form dirty state, etc.), then immediately re-emit
      // AuthAuthenticated with the fresh user so the AppBar name updates.
      emit(ProfileUpdateSuccess(updatedUser));
      emit(AuthAuthenticated(updatedUser));
    } catch (e) {
      emit(ProfileUpdateError(_mapProfileUpdateException(e)));
    }
  }

  // ── error mappers ───────────────────────────────────────────────────────────

  String _mapException(dynamic e) {
    final msg = e.toString();
    if (msg.contains('wrong-password') || msg.contains('user-not-found')) {
      return 'Invalid credentials.';
    }
    if (msg.contains('weak-password')) return 'Password is too weak.';
    if (msg.contains('network-request-failed')) {
      return 'Network error. Check your connection.';
    }
    return 'Authentication error: $msg';
  }

  String _mapParentVerificationException(dynamic e) {
    final msg = e.toString();
    if (msg.contains('wrong-password') || msg.contains('user-not-found')) {
      return 'Invalid parent credentials. Logout denied.';
    }
    if (msg.contains('network-request-failed')) {
      return 'Network error. Check your connection and try again.';
    }
    if (msg.contains('parent-mismatch')) {
      return 'These credentials do not belong to your linked parent.';
    }
    return 'Verification failed: $msg';
  }

  String _mapProfileUpdateException(dynamic e) {
    final msg = e.toString();
    if (msg.contains('wrong-password') ||
        msg.contains('invalid-credential') ||
        msg.contains('INVALID_LOGIN_CREDENTIALS')) {
      return 'Current password is incorrect.';
    }
    if (msg.contains('weak-password')) {
      return 'New password is too weak. Use at least 6 characters.';
    }
    if (msg.contains('requires-recent-login')) {
      return 'Session expired. Please log out and log in again.';
    }
    if (msg.contains('network-request-failed')) {
      return 'Network error. Check your connection and try again.';
    }
    return 'Update failed: $msg';
  }
}
