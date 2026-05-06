import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/auth/auth_bloc.dart';
import '../../../bloc/auth/auth_event.dart';
import '../../../bloc/auth/auth_state.dart';
import '../../../bloc/shop/shop_bloc.dart';
import '../../widgets/parent_verification_dialog.dart';
import '../../widgets/student_navigation_bar.dart';
import '../../../services/overlay/mascot_overlay_service.dart';
import '../../../services/installed_apps_service.dart';
import '../../../data/providers/dataconnect_provider.dart';
import 'student_home.dart';
import 'student_shop.dart';
import 'student_leaderboard.dart';
import 'student_friends.dart';
import 'student_profile.dart';

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
  int _coins = 0;
  int _level = 1;
  String _parentUid = '';

  static const List<String> _titles = [
    'Home',
    'Shop',
    'Leaderboard',
    'Friends',
    'Profile',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    MascotOverlayService.instance.init().then(
      (_) => MascotOverlayService.instance.start(),
    );
    DataConnectProvider().updateLastActiveAt().catchError((_) {});
    _loadCoinsAndLevel();
  }

  Future<void> _loadCoinsAndLevel() async {
    try {
      final provider = DataConnectProvider();
      final results = await Future.wait([
        provider.getStudentProfile(widget.uid),
        provider.getParentUidForStudent(widget.uid),
      ]);
      if (mounted) {
        final profile = results[0] as Map<String, dynamic>;
        setState(() {
          _coins = (profile['total_coins'] as int?) ?? 0;
          final xp = (profile['total_xp'] as int?) ?? 0;
          _level = (xp ~/ 500) + 1;
          _parentUid = results[1] as String;
        });
      }
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
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
    return BlocProvider<ShopBloc>(
      create: (_) => ShopBloc(),
      child: PopScope(
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
                // Coin balance in app bar when on shop tab
                if (_selectedIndex == 1)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8E1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFFFCA28)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🪙', style: TextStyle(fontSize: 14)),
                            const SizedBox(width: 4),
                            Text(
                              '$_coins',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFF57F17),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () {
                    context.read<AuthBloc>().add(
                      StudentLogoutVerificationRequested(
                        studentUid: widget.uid,
                      ),
                    );
                  },
                ),
              ],
            ),
            body: IndexedStack(
              index: _selectedIndex,
              children: [
                StudentHome(fullName: widget.fullName, uid: widget.uid),
                StudentShop(uid: widget.uid, coins: _coins, level: _level),
                StudentLeaderboard(
                  uid: widget.uid,
                  fullName: widget.fullName,
                  parentUid: _parentUid,
                ),
                StudentFriends(uid: widget.uid, fullName: widget.fullName),
                StudentProfile(fullName: widget.fullName, uid: widget.uid),
              ],
            ),
            bottomNavigationBar: StudentNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) => setState(() => _selectedIndex = index),
            ),
          ),
        ),
      ),
    );
  }
}
