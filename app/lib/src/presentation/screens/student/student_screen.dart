import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/auth/auth_bloc.dart';
import '../../../bloc/auth/auth_event.dart';
import '../../../bloc/auth/auth_state.dart';
import '../../../bloc/shop/shop_bloc.dart';
import '../../../bloc/garden/garden_bloc.dart';
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
  int _xp = 0;
  int _level = 1;
  String _parentUid = '';

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
          _xp = (profile['total_xp'] as int?) ?? 0;
          _level = (_xp ~/ 500) + 1;
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
    return MultiBlocProvider(
      providers: [
        BlocProvider<ShopBloc>(create: (_) => ShopBloc()),
        BlocProvider<GardenBloc>(create: (_) => GardenBloc()),
      ],
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
            backgroundColor: const Color(0xFFF5F7FA),
            body: SafeArea(
              child: Column(
                children: [
                  _buildTopNav(context),
                  Expanded(
                    child: IndexedStack(
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
                  ),
                ],
              ),
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

  // ── Custom top navigation bar ──────────────────────────────────────────────

  Widget _buildTopNav(BuildContext context) {
    final firstName = widget.fullName.split(' ').first;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          // Avatar — shows first letter, tap to logout
          GestureDetector(
            onTap: () => context.read<AuthBloc>().add(
              StudentLogoutVerificationRequested(studentUid: widget.uid),
            ),
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Color(0xFFFFD95A),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  firstName.isNotEmpty ? firstName[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5D4037),
                  ),
                ),
              ),
            ),
          ),
          const Spacer(),
          // XP pill
          _navPill(
            icon: Icons.star_rounded,
            iconColor: const Color(0xFFFFC107),
            label: _formatNum(_xp),
          ),
          const SizedBox(width: 8),
          // Coins pill
          _navPill(
            icon: Icons.monetization_on_rounded,
            iconColor: const Color(0xFFFFA000),
            label: _formatNum(_coins),
          ),
          const SizedBox(width: 6),
          // Bell with green dot
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: Color(0xFF757575),
                  size: 24,
                ),
                onPressed: () {},
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _navPill({
    required IconData icon,
    required Color iconColor,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFE082)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFFE6A800),
            ),
          ),
        ],
      ),
    );
  }

  String _formatNum(int n) {
    if (n >= 1000) {
      final s = n.toString();
      final thousands = s.substring(0, s.length - 3);
      final remainder = s.substring(s.length - 3);
      return '$thousands,$remainder';
    }
    return '$n';
  }
}
