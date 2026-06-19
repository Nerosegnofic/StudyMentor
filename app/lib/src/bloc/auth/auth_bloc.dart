// lib/src/bloc/auth/auth_bloc.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/models/user_model.dart';
import '../../services/installed_apps_service.dart';
import '../../services/student_local_notification_handler.dart';
import '../../services/garden_nudge_service.dart';
import '../../services/streak_reminder_service.dart';
import '../../services/parent_notification_poll_service.dart';
import '../../services/parent_inactivity_check_service.dart';
import '../../services/notification_preferences_cache.dart';
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
    on<LoadParentNameRequested>(_onLoadParentName);
    on<StudentLogoutVerificationRequested>(_onStudentLogoutVerification);
    on<VerifyParentAndLogoutRequested>(_onVerifyParentAndLogout);
    on<UpdateProfileRequested>(_onUpdateProfile);
    on<LegacyLoadAppRulesRequested>(_onLoadAppRules);
    on<LegacySaveAppRulesRequested>(_onSaveAppRules);
    on<LoadStudentAppConfigRequested>(_onLoadStudentAppConfig);
    on<SyncInstalledAppsRequested>(_onSyncInstalledApps);
    on<LoadInstalledAppsForStudentRequested>(_onLoadInstalledAppsForStudent);
    on<LegacyRefreshStudentDataRequested>(_onRefreshStudentData);
    on<UpdateStudentFullNameRequested>(_onUpdateStudentFullName);
    on<DeleteParentAccountRequested>(_onDeleteParentAccount);
    on<UpdateStudentProfileRequested>(_onUpdateStudentProfile);
    on<DeleteStudentRequested>(_onDeleteStudent);
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
          if (profile.role.toLowerCase() != 'parent') {
            await GardenNudgeService.scheduleNext(
              policy: ExistingWorkPolicy.keep,
            );
            await StreakReminderService.scheduleNext(
              policy: ExistingWorkPolicy.keep,
            );
            await _cacheStudentContext(profile);
          } else {
            await _cacheParentContext(profile);
            await ParentNotificationPollService.register();
            await ParentInactivityCheckService.scheduleNext(
              policy: ExistingWorkPolicy.keep,
            );
          }
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
        if (user.role.toLowerCase() != 'parent') {
          await GardenNudgeService.scheduleNext(
            policy: ExistingWorkPolicy.keep,
          );
          await StreakReminderService.scheduleNext(
            policy: ExistingWorkPolicy.keep,
          );
          await _cacheStudentContext(user);
        } else {
          await _cacheParentContext(user);
          await ParentNotificationPollService.register();
          await ParentInactivityCheckService.scheduleNext(
            policy: ExistingWorkPolicy.keep,
          );
        }
      }
    } catch (e) {
      debugPrint('[AUTH DEBUG] Login error: $e');
      emit(AuthError(_mapException(e)));
    }
  }

  Future<void> _onLogout(LogoutRequested event, Emitter<AuthState> emit) async {
    final prevState = state;
    await repository.signOut();
    StudentLocalNotificationHandler.instance.clearFiredEvents();
    if (prevState is AuthAuthenticated) {
      if (prevState.user.role.toLowerCase() != 'parent') {
        await GardenNudgeService.cancel(prevState.user.uid);
        await StreakReminderService.cancel(prevState.user.uid);
      } else {
        await ParentNotificationPollService.cancel();
        await ParentInactivityCheckService.cancel();
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('parentUid');
      }
      await NotificationPreferencesCache.clear(prevState.user.uid);
    }
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
        StudentLocalNotificationHandler.instance.clearFiredEvents();
        await GardenNudgeService.cancel(event.studentUid);
        await StreakReminderService.cancel(event.studentUid);
        await NotificationPreferencesCache.clear(event.studentUid);
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
    emit(LegacyProfileUpdateLoading());
    try {
      final updatedUser = await repository.updateProfile(
        parentUid: '', // parentUid no longer readily available in this event, but this event is unused in UI.
        newFullName: event.newFullName,
        newEmail: event.newEmail,
        currentPassword: event.currentPassword,
        newPassword: event.newPassword,
      );

      if (event.newEmail != null && event.newEmail!.isNotEmpty) {
        emit(EmailUpdateVerificationSent(event.newEmail!));
      }

      emit(LegacyProfileUpdateSuccess(updatedUser));
      emit(AuthAuthenticated(updatedUser));
    } catch (e) {
      emit(LegacyProfileUpdateError(_mapProfileUpdateException(e)));
    }
  }

  // ── App Configuration Handlers ────────────────────────────────────────────

  Future<void> _onLoadAppRules(
    LegacyLoadAppRulesRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(LegacyAppConfigLoading());
    try {
      final (:config, :rules) = await repository.getAppConfigForStudent(
        event.studentUid,
      );
      emit(
        LegacyAppRulesLoaded(
          studentUid: event.studentUid,
          rules: rules,
          config: config ?? const StudentConfigModel(),
        ),
      );
    } catch (e, stack) {
      debugPrint('[AuthBloc] _onLoadAppRules error: $e\n$stack');
      emit(LegacyAppConfigError(_mapException(e)));
    }
  }

  Future<void> _onSaveAppRules(
    LegacySaveAppRulesRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(LegacyAppConfigSaving());
    try {
      await repository.saveAppConfigForStudent(
        studentUid: event.studentUid,
        rules: event.rules,
        config: event.config,
      );
      emit(LegacyAppConfigSaved());
    } catch (e, stack) {
      debugPrint('[AuthBloc] _onSaveAppRules error: $e\n$stack');
      emit(LegacyAppConfigError(_mapException(e)));
    }
  }

  Future<void> _onLoadStudentAppConfig(
    LoadStudentAppConfigRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(LegacyAppConfigLoading());
    try {
      final (:config, :rules) = await repository.getAppConfigForStudent(
        event.studentUid,
      );
      emit(
        LegacyAppRulesLoaded(
          studentUid: event.studentUid,
          rules: rules,
          config: config ?? const StudentConfigModel(),
        ),
      );
    } catch (e, stack) {
      debugPrint('[AuthBloc] _onLoadStudentAppConfig error: $e\n$stack');
      emit(LegacyAppConfigError(_mapException(e)));
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
    // Restore AuthAuthenticated so that screens reading AuthBloc.state
    // (e.g. ParentSettings) still find the parent's profile after this
    // sub-operation completes.
    final profile = await repository.getUserProfile();
    if (profile != null) emit(AuthAuthenticated(profile));
  }

  Future<void> _onRefreshStudentData(
    LegacyRefreshStudentDataRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(LegacyStudentDataRefreshing());
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
        LegacyAppRulesLoaded(
          studentUid: event.studentUid,
          rules: rules,
          config: config ?? const StudentConfigModel(),
        ),
      );
    } catch (e) {
      emit(LegacyAppConfigError(_mapException(e)));
    }
  }

  // ── Student Deletion ──────────────────────────────────────────────────────

  Future<void> _onDeleteStudent(
    DeleteStudentRequested event,
    Emitter<AuthState> emit,
  ) async {
    debugPrint('[DeleteStudent] started for ${event.studentUid}');
    emit(StudentDeleteLoading());
    try {
      await repository.deleteStudent(
        studentUid: event.studentUid,
        studentEmail: event.studentEmail,
        studentPassword: event.studentPassword,
      );
      debugPrint('[DeleteStudent] repository.deleteStudent completed');
      emit(StudentDeleted(studentUid: event.studentUid));
      debugPrint('[DeleteStudent] emitted StudentDeleted');
      // Restore AuthAuthenticated so parent-facing screens (settings, profile)
      // continue to display the parent's data correctly after navigation back.
      final profile = await repository.getUserProfile();
      debugPrint('[DeleteStudent] getUserProfile returned: $profile');
      if (profile != null) emit(AuthAuthenticated(profile));
      debugPrint('[DeleteStudent] done');
    } catch (e, stack) {
      debugPrint('[DeleteStudent] error: $e\n$stack');
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
    emit(LegacyParentAccountDeleteLoading());
    try {
      await repository.deleteParentAccount(event.currentPassword);
      emit(LegacyParentAccountDeleted());
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(LegacyParentAccountDeleteError(_mapProfileUpdateException(e)));
    }
  }

  // ── Student Profile Update (parent-side) ─────────────────────────────────

  Future<void> _onUpdateStudentProfile(
    UpdateStudentProfileRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(StudentLegacyProfileUpdateLoading());
    try {
      await repository.updateStudentProfile(
        studentUid: event.studentUid,
        studentEmail: event.studentEmail,
        newFullName: event.newFullName,
        newEmail: event.newEmail,
        currentPassword: event.currentPassword,
        newPassword: event.newPassword,
      );
      emit(
        StudentLegacyProfileUpdateSuccess(
          studentUid: event.studentUid,
          newFullName: event.newFullName,
          pendingEmail: null,
        ),
      );
    } catch (e) {
      emit(LegacyStudentProfileUpdateError(_mapProfileUpdateException(e)));
    }
  }

  /// Caches `parent_uid_{uid}` and `student_full_name_{uid}` in
  /// [SharedPreferences] so that [StudentLocalNotificationHandler] and
  /// [StreakReminderService] (which runs in a background isolate) can build
  /// `InsertLocalNotificationEvent` payloads for the parent without an extra
  /// network round-trip.
  Future<void> _cacheStudentContext(UserModel profile) async {
    try {
      final parentUid = await repository.getParentUidForStudent(profile.uid);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('parent_uid_${profile.uid}', parentUid);
      await prefs.setString(
        'student_full_name_${profile.uid}',
        profile.fullName,
      );
    } catch (_) {
      // Best-effort cache — a failure here must not affect the auth flow.
    }
    try {
      await NotificationPreferencesCache.refresh(profile.uid);
    } catch (_) {
      // Best-effort cache — a failure here must not affect the auth flow.
    }
  }

  /// Caches `parentUid` in [SharedPreferences] so that
  /// [ParentNotificationPollService] (which runs in a background isolate)
  /// can identify this as a parent session without an extra network
  /// round-trip.
  Future<void> _cacheParentContext(UserModel profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('parentUid', profile.uid);
    try {
      await NotificationPreferencesCache.refresh(profile.uid);
    } catch (_) {
      // Best-effort cache — a failure here must not affect the auth flow.
    }
  }

  // ── Error mappers ─────────────────────────────────────────────────────────

  /// Generic mapper — used for login and other non-registration flows.
  /// Intentionally returns the same message for all auth failures so that
  /// no information about account existence is leaked to the UI.
  String _mapException(dynamic e) {
    debugPrint('[AuthBloc] _mapException caught: $e');
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
    return 'Update failed. Please try again.';
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

  String _mapDeletionException(dynamic e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('wrong-password') ||
        msg.contains('invalid-credential') ||
        msg.contains('invalid_login_credentials') ||
        msg.contains('user-not-found') ||
        msg.contains('invalid-email')) {
      return 'Invalid credentials';
    }
    if (msg.contains('network-request-failed')) {
      return 'Network error. Check your connection and try again.';
    }
    return 'Unable to delete account. Please try again.';
  }
}
