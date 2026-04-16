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
    on<StudentLogoutVerificationRequested>(_onStudentLogoutVerification);
    on<VerifyParentAndLogoutRequested>(_onVerifyParentAndLogout);
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

  Future<void> _onLogout(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await repository.signOut();
    emit(AuthUnauthenticated());
  }

  Future<void> _onSendEmailVerification(
    SendEmailVerificationRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await repository.sendEmailVerification();
      final email = (await repository.getUserProfile())?.email ?? '';
      emit(AuthEmailUnverified(email));
    } catch (e) {
      emit(AuthError(_mapException(e)));
    }
  }

  Future<void> _onCheckEmailVerification(
    CheckEmailVerificationRequested event,
    Emitter<AuthState> emit,
  ) async {
    final isVerified = await repository.isEmailVerified();
    if (isVerified) {
      final profile = await repository.getUserProfile();
      if (profile != null) {
        emit(AuthAuthenticated(profile));
      } else {
        emit(AuthUnauthenticated());
      }
    } else {
      emit(
        AuthEmailUnverified(
          (await repository.getUserProfile())?.email ?? '',
        ),
      );
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

  /// When a student taps logout, emit a state that tells the UI
  /// to show the parent-verification dialog instead of logging out.
  Future<void> _onStudentLogoutVerification(
    StudentLogoutVerificationRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(StudentLogoutVerificationRequired(studentUid: event.studentUid));
  }

  /// Verify the parent credentials against the linked parent and
  /// only log out if they match.
  Future<void> _onVerifyParentAndLogout(
    VerifyParentAndLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
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
        emit(ParentVerificationFailed(
          message: 'Invalid parent credentials. Logout denied.',
          studentUid: event.studentUid,
        ));
      }
    } catch (e) {
      emit(ParentVerificationFailed(
        message: _mapParentVerificationException(e),
        studentUid: event.studentUid,
      ));
    }
  }

  String _mapException(dynamic e) {
    final msg = e.toString();
    if (msg.contains('wrong-password') || msg.contains('user-not-found')) {
      return 'Invalid credentials.';
    }
    if (msg.contains('weak-password')) {
      return 'Password is too weak.';
    }
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
}