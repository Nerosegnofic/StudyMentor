import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:workmanager/workmanager.dart';

import 'firebase_options.dart';
import 'src/bloc/auth/auth_bloc.dart';
import 'src/bloc/auth/auth_event.dart';
import 'src/bloc/auth/auth_state.dart';
import 'src/data/providers/dataconnect_provider.dart';
import 'src/data/providers/firebase_auth_provider.dart';
import 'src/data/repositories/auth_repository_impl.dart';
import 'src/presentation/screens/auth/confirm_email_screen.dart';
import 'src/presentation/screens/auth/forgot_password_screen.dart';
import 'src/presentation/screens/auth/login_screen.dart';
import 'src/presentation/screens/parent/parent_screen.dart';
import 'src/presentation/screens/auth/parent_register_screen.dart';
import 'src/presentation/screens/student/student_screen.dart';
import 'src/services/installed_apps_service.dart';

// ── WorkManager task identifiers ─────────────────────────────────────────────
const _kSyncTaskName = 'installedAppSync';
const _kSyncTaskTag = 'com.example.studymentor.installedAppSync';

// ── Background callback dispatcher ───────────────────────────────────────────
// Top-level function — runs in a separate isolate when the app is closed.
// No widgets, no Bloc, no BuildContext available here.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName != _kSyncTaskName) return true;

    try {
      // 1. Boot Firebase for this isolate.
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // 2. Check that a student is still signed in.
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return true; // No user — nothing to sync.

      // 3. Fetch apps from PackageManager via MethodChannel.
      final apps = await InstalledAppsService.instance.getFromDevice();

      // 4. Push to DataConnect directly — no Bloc involved.
      final provider = DataConnectProvider();
      await provider.deleteAllInstalledAppsForStudent(user.uid);
      await Future.wait(
        apps.map(
          (app) => provider.insertInstalledApp(
            studentUid: user.uid,
            packageName: app.packageName,
            appLabel: app.appLabel,
            isSystemApp: app.isSystemApp,
            iconBase64: app.iconBase64,
          ),
        ),
      );

      // 5. Clear the dirty flag so the resume handler doesn't double-sync.
      await InstalledAppsService.instance.markInventoryClean();

      return true;
    } catch (_) {
      // Returning false tells WorkManager to retry with backoff.
      return false;
    }
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialise WorkManager with the background callback.
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);

  // Register the periodic 15-minute background sync.
  // ExistingWorkPolicy.replace ensures only one task is ever scheduled,
  // even if main() is called again (e.g. after a hot restart in debug).
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

  runApp(StudyMentorApp(authRepository: authRepository));
}

class StudyMentorApp extends StatelessWidget {
  final dynamic authRepository;

  const StudyMentorApp({super.key, required this.authRepository});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
      value: authRepository,
      child: BlocProvider(
        create: (context) =>
            AuthBloc(repository: authRepository)..add(AppStarted()),
        child: MaterialApp(
          title: 'StudyMentor',
          debugShowCheckedModeBanner: false,
          routes: {
            '/login': (_) => const LoginScreen(),
            '/register': (_) => const ParentRegisterScreen(),
            '/confirm-email': (_) => const ConfirmEmailScreen(),
            '/forgot-password': (_) => const ForgotPasswordScreen(),
            '/parent': (context) {
              final user =
                  (context.read<AuthBloc>().state as AuthAuthenticated).user;
              return ParentScreen(fullName: user.fullName, uid: user.uid);
            },
            '/student': (context) {
              final user =
                  (context.read<AuthBloc>().state as AuthAuthenticated).user;
              return StudentScreen(fullName: user.fullName, uid: user.uid);
            },
          },
          home: const RootPage(),
        ),
      ),
    );
  }
}

class RootPage extends StatelessWidget {
  const RootPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (prev, curr) => curr is AuthError,
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      buildWhen: (prev, curr) =>
          curr is AuthInitial ||
          (curr is AuthLoading &&
              prev is! AuthUnauthenticated &&
              prev is! AuthError) ||
          curr is AuthAuthenticated ||
          curr is AuthUnauthenticated ||
          curr is AuthEmailUnverified ||
          curr is AuthError,
      builder: (context, state) {
        if (state is AuthInitial || state is AuthLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (state is AuthUnauthenticated || state is AuthError) {
          return const LoginScreen();
        }
        if (state is AuthEmailUnverified) {
          return const ConfirmEmailScreen();
        }
        if (state is AuthAuthenticated) {
          final role = state.user.role.toLowerCase();
          final fullName = state.user.fullName;
          if (role == 'parent') {
            return ParentScreen(fullName: fullName, uid: state.user.uid);
          } else {
            return StudentScreen(fullName: fullName, uid: state.user.uid);
          }
        }
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}
