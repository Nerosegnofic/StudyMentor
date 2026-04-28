import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'src/bloc/auth/auth_bloc.dart';
import 'src/bloc/auth/auth_event.dart';
import 'src/bloc/auth/auth_state.dart';
import 'src/presentation/screens/login_screen.dart';
import 'src/presentation/screens/register_screen.dart';
import 'src/presentation/screens/confirm_email_screen.dart';
import 'src/presentation/screens/forgot_password_screen.dart';
import 'src/presentation/screens/parent/parent_screen.dart';
import 'src/presentation/screens/student_screen.dart';
import 'src/data/providers/firebase_auth_provider.dart';
import 'src/data/providers/dataconnect_provider.dart';
import 'src/data/repositories/auth_repository_impl.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

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
            '/register': (_) => const RegisterScreen(),
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
