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
import 'src/presentation/screens/parent_screen.dart';
import 'src/presentation/screens/student_screen.dart';
import 'src/data/providers/firebase_auth_provider.dart';
import 'src/data/providers/cloud_function_provider.dart';
import 'src/data/repositories/auth_repository_impl.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Instantiate providers and repository (adjust constructors if needed).
  final firebaseProvider = FirebaseAuthProvider();
  final cloudProvider = CloudFunctionProvider();
  final authRepository = AuthRepositoryImpl(firebase: firebaseProvider, cloud: cloudProvider);

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
        create: (context) => AuthBloc(repository: authRepository)..add(AppStarted()),
        child: MaterialApp(
          title: 'StudyMentor',
          // Keep named routes for direct navigation where appropriate:
          routes: {
            '/login': (_) => LoginScreen(),
            '/register': (_) => RegisterScreen(),
            '/confirm-email': (_) => ConfirmEmailScreen(),
            '/forgot-password': (_) => ForgotPasswordScreen(),
          },
          // RootPage decides which screen to show based on AuthBloc state.
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
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      builder: (context, state) {
        if (state is AuthInitial || state is AuthLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (state is AuthUnauthenticated) {
          return LoginScreen();
        }
        if (state is AuthEmailUnverified) {
          // Confirm email screen will let user send verification and refresh status
          return ConfirmEmailScreen();
        }
        if (state is AuthAuthenticated) {
          final role = state.user.role.toLowerCase();
          final fullName = state.user.fullName;
          if (role == 'parent') {
            return ParentScreen(fullName: fullName);
          } else {
            return StudentScreen(fullName: fullName);
          }
        }
        // Fallback
        return LoginScreen();
      },
    );
  }
}