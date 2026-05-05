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
    // App configuration
    on<LoadAppRulesRequested>(_onLoadAppRules);
    on<SaveAppRulesRequested>(_onSaveAppRules);
    on<LoadStudentAppConfigRequested>(_onLoadStudentAppConfig);
    // Installed-app inventory
    on<SyncInstalledAppsRequested>(_onSyncInstalledApps);
    on<LoadInstalledAppsForStudentRequested>(_onLoadInstalledAppsForStudent);
    on<RefreshStudentDataRequested>(_onRefreshStudentData);
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

  Future<void> _onUpdateProfile(
    UpdateProfileRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(ProfileUpdateLoading());
    try {
      final updatedUser = await repository.updateProfile(
        newFullName: event.newFullName,
        currentPassword: event.currentPassword,
        newPassword: event.newPassword,
      );
      emit(ProfileUpdateSuccess(updatedUser));
      emit(AuthAuthenticated(updatedUser));
    } catch (e) {
      emit(ProfileUpdateError(_mapProfileUpdateException(e)));
    }
  }

  // ── App Configuration Handlers ────────────────────────────────────────────

  /// Parent opens the config screen — load saved rules and global config.
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

  /// Parent taps Save — replace all rules and upsert global config.
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

  /// Student device loads its own saved config.
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

  /// Student device: fetch PackageManager apps, upload to DataConnect, clear flag.
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
      // Sync failure is non-fatal — enforcement continues with the last rules.
      debugPrint('[InstalledApps] sync error: $e');
    }
  }

  /// Parent side: load a student's inventory from DataConnect for the picker.
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

  /// Parent taps refresh — re-fetches both installed apps and rules in parallel.
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

  // ── Error mappers ─────────────────────────────────────────────────────────

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
