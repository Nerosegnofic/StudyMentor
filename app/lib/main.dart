import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:workmanager/workmanager.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'src/bloc/auth/auth_bloc.dart';
import 'src/bloc/auth/auth_event.dart';
import 'src/bloc/auth/auth_state.dart';
import 'src/bloc/app_config/app_config_bloc.dart';
import 'src/bloc/locale/locale_cubit.dart';
import 'src/bloc/subject/subject_bloc.dart';
import 'src/bloc/reports/reports_bloc.dart';
import 'src/bloc/students/students_bloc.dart';
import 'src/bloc/ai_summary/ai_summary_bloc.dart';
import 'src/bloc/notifications/notifications_bloc.dart';
import 'src/bloc/parent_profile/parent_profile_bloc.dart';
import 'src/bloc/student_profile/student_profile_bloc.dart';
import 'src/bloc/snapshot/snapshot_bloc.dart';
import 'src/data/providers/dataconnect_provider.dart';
import 'src/data/providers/firebase_auth_provider.dart';
import 'src/data/repositories/auth_repository_impl.dart';
import 'src/domain/repositories/auth_repository.dart';
import 'src/presentation/screens/auth/confirm_email_screen.dart';
import 'src/presentation/screens/auth/forgot_password_screen.dart';
import 'src/presentation/screens/auth/login_screen.dart';
import 'src/presentation/screens/parent/parent_screen.dart';
import 'src/presentation/screens/auth/parent_register_screen.dart';
import 'src/presentation/screens/student/student_screen.dart';
import 'src/services/installed_apps_service.dart';
import 'src/services/device_admin_service.dart';
import 'src/services/local_notification_service.dart';
import 'src/services/garden_nudge_service.dart';
import 'src/services/streak_reminder_service.dart';
import 'src/services/student_local_notification_handler.dart';
import 'src/services/parent_notification_poll_service.dart';
import 'src/services/parent_inactivity_check_service.dart';

// ── WorkManager task identifiers ─────────────────────────────────────────────
const _kSyncTaskName = 'installedAppSync';
const _kSyncTaskTag = 'com.example.studymentor.installedAppSync';

// ── Background callback dispatcher ───────────────────────────────────────────
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (_) {}

    if (taskName == _kSyncTaskName) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return true;

        final apps = await InstalledAppsService.instance.getFromDevice();

        final provider = DataConnectProvider();
        await provider.deleteAllInstalledAppsForStudent(user.uid);
        await Future.wait(
          apps.map(
            (app) => provider.insertInstalledApp(
              studentUid: user.uid,
              packageName: app.packageName,
              appLabel: app.appLabel,
              isSystemApp: app.isSystemApp,
            ),
          ),
        );

        await InstalledAppsService.instance.markInventoryClean();

        return true;
      } catch (_) {
        return false;
      }
    } else if (taskName == kGardenNudgeTaskName) {
      await GardenNudgeService.runTask();
    } else if (taskName == kStreakReminderTaskName) {
      await StreakReminderService.runTask();
    } else if (taskName == kParentNotificationPollTaskName) {
      await ParentNotificationPollService.runTask();
    } else if (taskName == kParentInactivityCheckTaskName) {
      await ParentInactivityCheckService.runTask();
    } else if (taskName == kStudentEventWriteTaskName) {
      final eventType = inputData?['eventType'] as String?;
      final payload = inputData?['payload'] as String?;
      final fromStudentUid = inputData?['fromStudentUid'] as String?;
      final toParentUid = inputData?['toParentUid'] as String?;
      if (eventType == null ||
          payload == null ||
          fromStudentUid == null ||
          toParentUid == null) {
        return true;
      }
      try {
        await DataConnectProvider().insertLocalNotificationEvent(
          fromStudentUid: fromStudentUid,
          toParentUid: toParentUid,
          eventType: eventType,
          payload: payload,
        );
      } catch (_) {
        return false; // let WorkManager retry with backoff
      }
    }

    return true;
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await LocalNotificationService.instance.init();

  await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);

  await Workmanager().registerPeriodicTask(
    _kSyncTaskName,
    _kSyncTaskName,
    tag: _kSyncTaskTag,
    frequency: const Duration(minutes: 15),
    constraints: Constraints(networkType: NetworkType.connected),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
  );

  final firebaseProvider = FirebaseAuthProvider();
  final dataConnectProvider = DataConnectProvider();
  final authRepository = AuthRepositoryImpl(
    firebase: firebaseProvider,
    dataConnect: dataConnectProvider,
  );

  final initialLocale = await LocaleCubit.readSavedLocale();

  runApp(StudyMentorApp(authRepository: authRepository, initialLocale: initialLocale));
}

class StudyMentorApp extends StatelessWidget {
  final AuthRepository authRepository;
  final Locale initialLocale;

  const StudyMentorApp({super.key, required this.authRepository, required this.initialLocale});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<AuthRepository>.value(
      value: authRepository,
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (context) =>
                AuthBloc(repository: authRepository)..add(AppStarted()),
          ),
          BlocProvider<AppConfigBloc>(
            create: (context) => AppConfigBloc(authRepository: authRepository),
          ),
          BlocProvider<LocaleCubit>(
            create: (context) => LocaleCubit(initialLocale),
          ),
          BlocProvider<SubjectBloc>(
            create: (context) => SubjectBloc(authRepository: authRepository),
          ),
          BlocProvider<StudentsBloc>(
            create: (context) => StudentsBloc(repository: authRepository),
          ),
          BlocProvider<ReportsBloc>(
            create: (context) => ReportsBloc(repository: authRepository),
          ),
          BlocProvider<AiSummaryBloc>(
            create: (context) => AiSummaryBloc(repository: authRepository),
          ),
          BlocProvider<NotificationsBloc>(
            create: (context) => NotificationsBloc(repository: authRepository),
          ),
          BlocProvider<ParentProfileBloc>(
            create: (context) => ParentProfileBloc(repository: authRepository),
          ),
          BlocProvider<StudentProfileBloc>(
            create: (context) => StudentProfileBloc(repository: authRepository),
          ),
          BlocProvider<SnapshotBloc>(
            create: (context) => SnapshotBloc(repository: authRepository),
          ),
        ],
        child: BlocBuilder<LocaleCubit, Locale>(
          builder: (context, locale) => MaterialApp(
          title: 'StudyMentor',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            textTheme: GoogleFonts.cairoTextTheme(),
            primaryTextTheme: GoogleFonts.cairoTextTheme(),
          ),
          locale: locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          routes: {
            '/login': (_) => const LoginScreen(),
            '/register': (_) => const ParentRegisterScreen(),
            '/confirm-email': (_) => const ConfirmEmailScreen(),
            '/forgot-password': (_) => const ForgotPasswordScreen(),
            // ── Safe cast: fall back to LoginScreen if state is unexpected ──
            '/parent': (context) {
              final state = context.read<AuthBloc>().state;
              if (state is AuthAuthenticated) {
                return ParentScreen(
                  fullName: state.user.fullName,
                  uid: state.user.uid,
                );
              }
              return const LoginScreen();
            },
            '/student': (context) {
              final state = context.read<AuthBloc>().state;
              if (state is AuthAuthenticated) {
                return StudentScreen(
                  fullName: state.user.fullName,
                  uid: state.user.uid,
                );
              }
              return const LoginScreen();
            },
          },
          home: const RootPage(),
          ),
        ),
      ),
    );
  }
}

class RootPage extends StatelessWidget {
  const RootPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (prev, curr) =>
          curr is AuthAuthenticated ||
          curr is AuthUnauthenticated ||
          curr is AuthEmailUnverified,
      listener: (context, state) async {
        if (state is AuthAuthenticated) {
          final isStudent = state.user.role.toLowerCase() != 'parent';
          if (!isStudent) {
            // Parent logged in — ensure the Settings guard is disabled.
            await DeviceAdminService.onStudentLogout();
          }
          // Do NOT activate student mode for students here. The Settings block
          // must not be enabled until ALL required permissions have been
          // granted — otherwise the student is locked out of Settings mid-flow
          // and cannot enable the remaining permissions.
          //
          // Student mode (isStudentLoggedIn = true) is activated by
          // PermissionGateScreen once every permission is confirmed, just
          // before navigating to student_home.
        } else if (state is AuthUnauthenticated ||
            state is AuthEmailUnverified) {
          // Logged out or unverified — disable the guard.
          await DeviceAdminService.onStudentLogout();
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        buildWhen: (prev, curr) =>
            curr is AuthInitial ||
            (curr is AuthLoading && prev is AuthInitial) ||
            curr is AuthAuthenticated ||
            curr is AuthUnauthenticated ||
            curr is AuthEmailUnverified,
        builder: (context, state) {
          if (state is AuthInitial || state is AuthLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (state is AuthUnauthenticated) {
            return const LoginScreen();
          }
          if (state is AuthEmailUnverified) {
            return const ConfirmEmailScreen();
          }
          if (state is AuthAuthenticated) {
            final role = state.user.role.toLowerCase();
            final fullName = state.user.fullName;
            // Key by uid so a new login rebuilds the screen's State (re-running initState,
            // which is what dispatches the data loads) instead of reusing a stale instance.
            if (role == 'parent') {
              return ParentScreen(
                key: ValueKey(state.user.uid),
                fullName: fullName,
                uid: state.user.uid,
              );
            } else {
              return StudentScreen(
                key: ValueKey(state.user.uid),
                fullName: fullName,
                uid: state.user.uid,
              );
            }
          }
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }
}
