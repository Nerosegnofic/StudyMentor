import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';
import '../widgets/parent_verification_dialog.dart';
import '../widgets/student_navigation_bar.dart';
import '../../services/overlay/mascot_overlay_service.dart';
import '../../services/installed_apps_service.dart';
import '../../data/providers/dataconnect_provider.dart';
import 'student/student_home.dart';
import 'student/student_shop.dart';
import 'student/student_leaderboard.dart';
import 'student/student_profile.dart';

class StudentScreen extends StatefulWidget {
  final String fullName;
  final String uid;

  const StudentScreen({super.key, required this.fullName, required this.uid});

  @override
  State<StudentScreen> createState() => _StudentScreenState();
}

class _StudentScreenState extends State<StudentScreen>
    with WidgetsBindingObserver {
  int _selectedIndex = 0;

  static const List<String> _titles = ['Home', 'Shop', 'Leaderboard', 'Profile'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    MascotOverlayService.instance.init().then(
      (_) => MascotOverlayService.instance.start(),
    );
    // Initial heartbeat
    DataConnectProvider().updateLastActiveAt().catchError((_) {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    // Refresh heartbeat whenever app comes to foreground
    DataConnectProvider().updateLastActiveAt().catchError((_) {});
    InstalledAppsService.instance.isInventoryDirty().then((dirty) {
      if (dirty && mounted) {
        context.read<AuthBloc>().add(
          SyncInstalledAppsRequested(studentUid: widget.uid),
        );
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    MascotOverlayService.instance.stop();
    super.dispose();
  }

  void _showVerificationDialog({String? errorMessage}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => ParentVerificationDialog(
        errorMessage: errorMessage,
        onSubmit: (email, password) {
          Navigator.of(dialogContext).pop();
          context.read<AuthBloc>().add(
            VerifyParentAndLogoutRequested(
              studentUid: widget.uid,
              parentEmail: email,
              parentPassword: password,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          context.read<AuthBloc>().add(
            StudentLogoutVerificationRequested(studentUid: widget.uid),
          );
        }
      },
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is StudentLogoutVerificationRequired) {
            _showVerificationDialog();
          }
          if (state is ParentVerificationFailed) {
            _showVerificationDialog(errorMessage: state.message);
          }
        },
        child: Scaffold(
          backgroundColor: const Color(0xFFF5F7FF),
          appBar: AppBar(
            title: Text(
              _selectedIndex == 0
                  ? 'Welcome, ${widget.fullName}'
                  : _titles[_selectedIndex],
            ),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () {
                  context.read<AuthBloc>().add(
                    StudentLogoutVerificationRequested(studentUid: widget.uid),
                  );
                },
              ),
            ],
          ),
          body: IndexedStack(
            index: _selectedIndex,
            children: [
              StudentHome(fullName: widget.fullName, uid: widget.uid),
              const StudentShop(),
              StudentLeaderboard(uid: widget.uid, fullName: widget.fullName),
              StudentProfile(fullName: widget.fullName, uid: widget.uid),
            ],
          ),
          bottomNavigationBar: StudentNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
          ),
        ),
      ),
    );
  }
}
