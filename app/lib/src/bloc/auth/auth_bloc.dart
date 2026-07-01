// lib/src/bloc/auth/auth_bloc.dart

import 'dart:async';
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
import '../../domain/models/app_config_model.dart';

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
    on<StudentLogoutVerificationRequested>(_onStudentLogoutVerification);
    on<VerifyParentAndLogoutRequested>(_onVerifyParentAndLogout);
    on<LoadStudentAppConfigRequested>(_onLoadStudentAppConfig);
    on<SyncInstalledAppsRequested>(_onSyncInstalledApps);
    on<LoadInstalledAppsForStudentRequested>(_onLoadInstalledAppsForStudent);
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
          // Background scheduling + context caching don't gate the UI — run them
          // fire-and-forget so the splash dismisses as soon as auth state is
          // known (mirrors the _onLogin change).
          if (profile.role.toLowerCase() != 'parent') {
            unawaited(_postLoginStudentSetup(profile));
          } else {
            unawaited(_postLoginParentSetup(profile));
          }
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
      // signIn() already reloaded the Firebase user, so read the cached
      // verification status instead of forcing a second network reload on the
      // critical login path.
      final verified = repository.isEmailVerifiedCached();
      if (!verified) {
        emit(AuthEmailUnverified(user.email));
      } else {
        emit(AuthAuthenticated(user));
        // Background scheduling + context caching don't gate any UI — run them
        // fire-and-forget so they don't contend with the screen mount / first
        // paint right after navigation.
        if (user.role.toLowerCase() != 'parent') {
          unawaited(_postLoginStudentSetup(user));
        } else {
          unawaited(_postLoginParentSetup(user));
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

  // ── App Configuration Handlers ────────────────────────────────────────────

  Future<void> _onLoadStudentAppConfig(
    LoadStudentAppConfigRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final (:config, :rules) = await repository.getAppConfigForStudent(
        event.studentUid,
      );
      // Reset first: if the previous state was an equal LegacyAppRulesLoaded
      // (e.g. still zero rules configured), Equatable would consider the
      // re-emitted state unchanged and BlocListener would never fire, leaving
      // student_home's "loading" flag stuck forever after a manual refresh.
      emit(AuthIdle());
      emit(
        LegacyAppRulesLoaded(
          studentUid: event.studentUid,
          rules: rules,
          config: config ?? const StudentConfigModel(),
        ),
      );
    } catch (e, stack) {
      debugPrint('[AuthBloc] _onLoadStudentAppConfig error: $e\n$stack');
      emit(AuthIdle());
      emit(LegacyAppConfigError(_mapException(e)));
    }
  }

  // ── Installed-App Inventory Handlers ─────────────────────────────────────

  Future<void> _onSyncInstalledApps(
    SyncInstalledAppsRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      // Skip the expensive native enumeration (getFromDevice) on the common
      // "nothing changed" login. Only run a full sync when the native dirty flag
      // is set (a package was installed/removed since the last sync) or this
      // device hasn't completed an initial sync for this student yet. The native
      // dirty flag defaults to false on a fresh install, so the per-uid bootstrap
      // flag is what guarantees the very first sync still runs.
      final prefs = await SharedPreferences.getInstance();
      final bootstrapKey = 'installed_apps_bootstrapped_${event.studentUid}';
      final bootstrapped = prefs.getBool(bootstrapKey) ?? false;
      final dirty = await InstalledAppsService.instance.isInventoryDirty();

      if (bootstrapped && !dirty) {
        debugPrint(
          '[InstalledApps] inventory clean & bootstrapped — skipping sync',
        );
        return;
      }

      final apps = await InstalledAppsService.instance.getFromDevice();
      await repository.syncInstalledAppsForStudent(
        studentUid: event.studentUid,
        apps: apps,
      );
      await InstalledAppsService.instance.markInventoryClean();
      await prefs.setBool(bootstrapKey, true);
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

  /// Post-login background setup for a student — WorkManager job scheduling +
  /// context caching. Runs fire-and-forget after `AuthAuthenticated` is emitted
  /// so it never blocks navigation / first paint. Fully guarded since it is not
  /// awaited.
  Future<void> _postLoginStudentSetup(UserModel user) async {
    try {
      await GardenNudgeService.scheduleNext(policy: ExistingWorkPolicy.keep);
    } catch (_) {}
    try {
      await StreakReminderService.scheduleNext(policy: ExistingWorkPolicy.keep);
    } catch (_) {}
    await _cacheStudentContext(user);
  }

  /// Post-login background setup for a parent — context caching + poll/inactivity
  /// job registration. Runs fire-and-forget after `AuthAuthenticated` is emitted.
  Future<void> _postLoginParentSetup(UserModel user) async {
    await _cacheParentContext(user);
    try {
      await ParentNotificationPollService.register();
    } catch (_) {}
    try {
      await ParentInactivityCheckService.scheduleNext(
        policy: ExistingWorkPolicy.keep,
      );
    } catch (_) {}
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
