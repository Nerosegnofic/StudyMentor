// lib/src/bloc/auth/auth_bloc.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../services/installed_apps_service.dart';
import '../../domain/models/installed_app_model.dart';
import '../../domain/models/app_config_model.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository repository;

  AuthBloc({required this.repository}) : super(AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<ResetAuthState>(_onResetAuthState);
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
    on<LoadAppRulesRequested>(_onLoadAppRules);
    on<SaveAppRulesRequested>(_onSaveAppRules);
    on<LoadStudentAppConfigRequested>(_onLoadStudentAppConfig);
    on<SyncInstalledAppsRequested>(_onSyncInstalledApps);
    on<LoadInstalledAppsForStudentRequested>(_onLoadInstalledAppsForStudent);
    on<RefreshStudentDataRequested>(_onRefreshStudentData);
    on<DeleteStudentRequested>(_onDeleteStudent);
    on<UpdateStudentFullNameRequested>(_onUpdateStudentFullName);
    on<DeleteParentAccountRequested>(_onDeleteParentAccount);
    on<UpdateStudentProfileRequested>(_onUpdateStudentProfile);
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

  /// Restores the authenticated state after a sub-flow (e.g. AddStudentScreen)
  /// is cancelled or dismissed without completing. Prevents the BLoC from
  /// staying stuck in AuthLoading or AuthError and causing RootPage to show
  /// a spinner when the parent navigates back.
  Future<void> _onResetAuthState(
    ResetAuthState event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final profile = await repository.getUserProfile();
      if (profile != null) {
        emit(AuthAuthenticated(profile));
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
      emit(AuthError(_mapRegistrationException(e)));
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
    emit(AuthLoading());
    try {
      final email = (await repository.getUserProfile())?.email ?? '';
      await repository.sendEmailVerification();
      emit(EmailVerificationSent(email));
    } catch (e) {
      final email = (await repository.getUserProfile())?.email ?? '';
      emit(EmailVerificationError(_mapEmailVerificationException(e), email));
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
        username: event.username,
      );
      emit(StudentCreated());
      emit(AuthAuthenticated(parent));
    } catch (e) {
      emit(AuthError(_mapRegistrationException(e)));
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
    emit(AuthIdle());
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
        // Emit AuthIdle first to guarantee a state transition even when the
        // previous state was already ParentVerificationFailed with identical
        // props. Without this, Equatable would consider the state unchanged
        // and BlocListener would not fire, leaving the dialog permanently
        // dismissed after a repeated failure.
        emit(AuthIdle());
        emit(
          ParentVerificationFailed(
            message: 'Invalid parent credentials. Logout denied.',
            studentUid: event.studentUid,
          ),
        );
      }
    } catch (e) {
      emit(AuthIdle());
      emit(
        ParentVerificationFailed(
          message: _mapParentVerificationException(e),
          studentUid: event.studentUid,
        ),
      );
    }
  }

  Future<void> _onUpdateProfile(
    UpdateProfileRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(ProfileUpdateLoading());
    try {
      final updatedUser = await repository.updateProfile(
        newFullName: event.newFullName,
        newEmail: event.newEmail,
        currentPassword: event.currentPassword,
        newPassword: event.newPassword,
      );

      if (event.newEmail != null && event.newEmail!.isNotEmpty) {
        emit(EmailUpdateVerificationSent(event.newEmail!));
      }

      emit(ProfileUpdateSuccess(updatedUser));
      emit(AuthAuthenticated(updatedUser));
    } catch (e) {
      emit(ProfileUpdateError(_mapProfileUpdateException(e)));
    }
  }

  // ── App Configuration Handlers ────────────────────────────────────────────

  Future<void> _onLoadAppRules(
    LoadAppRulesRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AppConfigLoading());
    try {
      final (:config, :rules) = await repository.getAppConfigForStudent(
        event.studentUid,
      );
      emit(
        AppRulesLoaded(
          studentUid: event.studentUid,
          rules: rules,
          config: config ?? const StudentConfigModel(),
        ),
      );
    } catch (e) {
      emit(AppConfigError(_mapException(e)));
    }
  }

  Future<void> _onSaveAppRules(
    SaveAppRulesRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AppConfigSaving());
    try {
      await repository.saveAppConfigForStudent(
        studentUid: event.studentUid,
        rules: event.rules,
        config: event.config,
      );
      emit(AppConfigSaved());
    } catch (e) {
      emit(AppConfigError(_mapException(e)));
    }
  }

  Future<void> _onLoadStudentAppConfig(
    LoadStudentAppConfigRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AppConfigLoading());
    try {
      final (:config, :rules) = await repository.getAppConfigForStudent(
        event.studentUid,
      );
      emit(
        AppRulesLoaded(
          studentUid: event.studentUid,
          rules: rules,
          config: config ?? const StudentConfigModel(),
        ),
      );
    } catch (e) {
      emit(AppConfigError(_mapException(e)));
    }
  }

  // ── Installed-App Inventory Handlers ─────────────────────────────────────

  Future<void> _onSyncInstalledApps(
    SyncInstalledAppsRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(InstalledAppsSyncing());
    try {
      final apps = await InstalledAppsService.instance.getFromDevice();
      await repository.syncInstalledAppsForStudent(
        studentUid: event.studentUid,
        apps: apps,
      );
      await InstalledAppsService.instance.markInventoryClean();
      emit(InstalledAppsSynced());
    } catch (e) {
      debugPrint('[InstalledApps] sync error: $e');
    }
  }

  Future<void> _onLoadInstalledAppsForStudent(
    LoadInstalledAppsForStudentRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final apps = await repository.getInstalledAppsForStudent(
        event.studentUid,
      );
      emit(InstalledAppsLoaded(studentUid: event.studentUid, apps: apps));
    } catch (e) {
      emit(InstalledAppsLoaded(studentUid: event.studentUid, apps: const []));
    }
  }

  Future<void> _onRefreshStudentData(
    RefreshStudentDataRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(StudentDataRefreshing());
    try {
      final results = await Future.wait([
        repository.getInstalledAppsForStudent(event.studentUid),
        repository.getAppConfigForStudent(event.studentUid),
      ]);

      emit(
        InstalledAppsLoaded(
          studentUid: event.studentUid,
          apps: results[0] as List<InstalledAppModel>,
        ),
      );

      final (:config, :rules) =
          results[1]
              as ({StudentConfigModel? config, List<AppRuleModel> rules});
      emit(
        AppRulesLoaded(
          studentUid: event.studentUid,
          rules: rules,
          config: config ?? const StudentConfigModel(),
        ),
      );
    } catch (e) {
      emit(AppConfigError(_mapException(e)));
    }
  }

  // ── Student Deletion ──────────────────────────────────────────────────────

  // Uses _mapDeletionException instead of the generic _mapException so that:
  // (a) wrong-password errors are reliably caught across Firebase SDK versions
  //     (both the legacy 'wrong-password' code and the newer 'invalid-credential'
  //     / 'INVALID_LOGIN_CREDENTIALS' codes are matched), and
  // (b) unexpected failures never surface raw internal error strings to the UI.
  Future<void> _onDeleteStudent(
    DeleteStudentRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(StudentDeleteLoading());
    try {
      await repository.deleteStudent(
        studentUid: event.studentUid,
        studentEmail: event.studentEmail,
        studentPassword: event.studentPassword,
      );
      // Only emit StudentDeleted. ParentStudents sets _isLoading = true on
      // this state and immediately fires LoadStudentsRequested, which will
      // produce the authoritative StudentsLoaded. Emitting StudentsLoaded
      // here raced against that — the (possibly empty) list arrived and
      // cleared _isLoading before the fresh fetch completed, causing the
      // "No students" empty state to flash.
      emit(StudentDeleted(studentUid: event.studentUid));
    } catch (e) {
      emit(StudentDeleteError(_mapDeletionException(e)));
    }
  }

  // ── Student Full Name Update ──────────────────────────────────────────────

  Future<void> _onUpdateStudentFullName(
    UpdateStudentFullNameRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(StudentNameUpdateLoading());
    try {
      await repository.updateStudentFullName(
        studentUid: event.studentUid,
        fullName: event.fullName,
      );
      emit(
        StudentNameUpdateSuccess(
          studentUid: event.studentUid,
          newFullName: event.fullName,
        ),
      );
    } catch (e) {
      emit(StudentNameUpdateError(_mapException(e)));
    }
  }

  // ── Parent Account Deletion ───────────────────────────────────────────────

  Future<void> _onDeleteParentAccount(
    DeleteParentAccountRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(ParentAccountDeleteLoading());
    try {
      await repository.deleteParentAccount(
        currentPassword: event.currentPassword,
      );
      emit(ParentAccountDeleted());
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(ParentAccountDeleteError(_mapProfileUpdateException(e)));
    }
  }

  // ── Student Profile Update (parent-side) ─────────────────────────────────

  Future<void> _onUpdateStudentProfile(
    UpdateStudentProfileRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(StudentProfileUpdateLoading());
    try {
      final pendingEmail = await repository.updateStudentProfile(
        studentUid: event.studentUid,
        studentEmail: event.studentEmail,
        newFullName: event.newFullName,
        newEmail: event.newEmail,
        currentPassword: event.currentPassword,
        newPassword: event.newPassword,
      );
      emit(
        StudentProfileUpdateSuccess(
          studentUid: event.studentUid,
          newFullName: event.newFullName,
          pendingEmail: pendingEmail,
        ),
      );
    } catch (e) {
      emit(StudentProfileUpdateError(_mapProfileUpdateException(e)));
    }
  }

  // ── Error mappers ─────────────────────────────────────────────────────────

  /// Generic mapper — used for login and other non-registration flows.
  /// Intentionally returns the same message for all auth failures so that
  /// no information about account existence is leaked to the UI.
  String _mapException(dynamic e) {
    final msg = e.toString();
    if (msg.contains('weak-password')) return 'Password is too weak.';
    if (msg.contains('network-request-failed')) {
      return 'Network error. Check your connection.';
    }
    // All auth failures — wrong password, unknown email, invalid credential,
    // malformed data, expired tokens, etc. — return the same generic message
    // so that no information about account existence is leaked to the UI.
    return 'Invalid email or password. Please try again.';
  }

  /// Registration mapper — used for parent sign-up and student creation.
  /// Unlike [_mapException], this surfaces specific, actionable messages
  /// because leaking "email already in use" is acceptable (and helpful)
  /// in a registration context.
  String _mapRegistrationException(dynamic e) {
    final msg = e.toString();
    if (msg.contains('email-already-in-use')) {
      return 'That email address is already registered. Please use a different one.';
    }
    if (msg.contains('weak-password')) {
      return 'Password is too weak. Please use at least 6 characters.';
    }
    if (msg.contains('invalid-email')) {
      return 'That email address doesn\'t look right. Please check it.';
    }
    if (msg.contains('network-request-failed')) {
      return 'Network error. Check your connection and try again.';
    }
    if (msg.contains('session expired') || msg.contains('Session expired')) {
      return 'Session expired. Please log out and log in again.';
    }
    // Username uniqueness — matches exceptions thrown by DataConnect /
    // the repository when a duplicate username is detected. The repository
    // should throw Exception('username-already-in-use') for this case.
    if (msg.contains('username-already-in-use') ||
        (msg.contains('username') && msg.contains('already'))) {
      return 'That username is already taken. Please choose a different one.';
    }
    if (msg.contains('too-many-requests') ||
        msg.contains('too_many_requests')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    return 'Registration failed. Please try again.';
  }

  String _mapParentVerificationException(dynamic e) {
    final msg = e.toString();
    if (msg.contains('network-request-failed')) {
      return 'Network error. Check your connection and try again.';
    }
    return 'Invalid parent credentials. Logout denied.';
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
    if (msg.contains('email-already-in-use')) {
      return 'That email address is already in use by another account.';
    }
    return 'Update failed: $msg';
  }

  // Dedicated mapper for student deletion errors. Handles both the legacy
  // Firebase 'wrong-password' error code and the newer 'invalid-credential' /
  // 'INVALID_LOGIN_CREDENTIALS' codes introduced in recent SDK versions, so a
  // bad password always produces the 'Invalid credentials' sentinel that
  // parent_students.dart checks for. All unexpected failures produce a generic
  // message so internal details are never exposed to the UI.
  String _mapDeletionException(dynamic e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('wrong-password') ||
        msg.contains('invalid-credential') ||
        msg.contains('invalid_login_credentials') ||
        msg.contains('user-not-found') ||
        msg.contains('invalid-email')) {
      // Must contain 'Invalid credentials' — matched by the contains() check
      // in parent_students.dart to show the friendly wrong-password message.
      return 'Invalid credentials';
    }
    if (msg.contains('network-request-failed')) {
      return 'Network error. Check your connection and try again.';
    }
    // Never surface raw exception details for a deletion failure.
    return 'Unable to delete account. Please try again.';
  }

  /// Mapper for email verification errors. Distinct from [_mapException] so
  /// that verification failures never show the login-specific
  /// "Invalid email or password" message.
  String _mapEmailVerificationException(dynamic e) {
    final msg = e.toString();
    if (msg.contains('network-request-failed')) {
      return 'Network error. Check your connection and try again.';
    }
    if (msg.contains('too-many-requests') ||
        msg.contains('too_many_requests')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    if (msg.contains('user-not-found') || msg.contains('no-current-user')) {
      return 'No signed-in account found. Please log in again.';
    }
    return 'Could not send verification email. Please try again.';
  }
}
