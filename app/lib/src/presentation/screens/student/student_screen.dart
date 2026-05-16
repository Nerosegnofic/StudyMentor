import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/auth/auth_bloc.dart';
import '../../../bloc/auth/auth_event.dart';
import '../../../bloc/auth/auth_state.dart';
import '../../../bloc/shop/shop_bloc.dart';

import '../../../data/repositories/ai_engine_repository.dart';
import '../../../bloc/garden/garden_bloc.dart';
import '../../../domain/models/avatar_config.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/parent_verification_dialog.dart';
import '../../widgets/student_navigation_bar.dart';
import '../../../services/overlay/mascot_overlay_service.dart';
import '../../../services/installed_apps_service.dart';
import '../../../data/providers/dataconnect_provider.dart';
import 'student_home.dart';
import 'student_quiz.dart';

import 'student_shop.dart';
import 'student_leaderboard.dart';
import 'student_friends.dart';
import 'student_profile.dart';

/// Base URL for the AI Engine.
/// Change to your machine's LAN IP when testing on a physical device.
const _kAiEngineBaseUrl = 'http://192.168.100.18:8000';

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
  AvatarConfig _avatarConfig = AvatarConfig.defaults;

  /// Stable repository instance — created once in initState.
  late final AiEngineRepository _aiRepo;

  /// Subscription to the quiz-trigger stream from MascotOverlayService.
  StreamSubscription<void>? _quizSub;

  // ── Verification dialog state ─────────────────────────────────────────────
  //
  // Rather than closing and reopening the dialog on each result, we keep it
  // open for the entire verification lifecycle. StatefulBuilder gives us a
  // setDialogState callback that can rebuild the dialog's contents in-place
  // (loading spinner → error message → closed) without ever dismissing it.
  //
  // The dialog is only closed in two situations:
  //   • The user taps Cancel (dialog pops itself).
  //   • Authentication succeeds and pushNamedAndRemoveUntil removes all routes.
  //
  // _dialogSetState is non-null while the dialog is on screen and is cleared
  // in the whenComplete callback so stale updates are never applied after the
  // dialog has been dismissed.
  StateSetter? _dialogSetState;
  bool _dialogIsLoading = false;
  String? _dialogError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _aiRepo = AiEngineRepository(baseUrl: _kAiEngineBaseUrl);

    MascotOverlayService.instance.init().then(
      (_) => MascotOverlayService.instance.start(),
    );

    // Subscribe to overlay quiz trigger.
    _quizSub = MascotOverlayService.instance.quizRequested.listen((_) {
      _openQuizOverlay();
    });

    DataConnectProvider().updateLastActiveAt().catchError((_) {});
    _loadCoinsAndLevel();
  }

  Future<void> _loadCoinsAndLevel() async {
    try {
      final provider = DataConnectProvider();
      final results = await Future.wait([
        provider.getStudentProfile(widget.uid),
        provider.getParentUidForStudent(widget.uid),
        provider.getStudentAvatar(widget.uid),
      ]);
      if (mounted) {
        final profile = results[0] as Map<String, dynamic>;
        final avatarMap = results[2];
        setState(() {
          _coins = (profile['total_coins'] as int?) ?? 0;
          _xp = (profile['total_xp'] as int?) ?? 0;
          _level = (_xp ~/ 500) + 1;
          _parentUid = results[1] as String;
          if (avatarMap != null) {
            _avatarConfig = AvatarConfig.fromMap(
              avatarMap as Map<String, dynamic>,
            );
          }
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
    _quizSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    MascotOverlayService.instance.stop();
    super.dispose();
  }

  // ── Quiz overlay ─────────────────────────────────────────────────────────

  void _openQuizOverlay() {
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => QuizOverlayPage(repository: _aiRepo),
      ),
    );
  }

  // ── Verification dialog ───────────────────────────────────────────────────

  // Opens the verification dialog and stores a StateSetter reference so the
  // BLoC listener can update its contents in-place without closing it.
  void _showVerificationDialog() {
    _dialogIsLoading = false;
    _dialogError = null;
    showDialog(
      context: context,
      // Keep barrier taps disabled for the entire dialog lifecycle so the
      // dialog cannot be dismissed by tapping outside it, including when it
      // is not loading.
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setDialogState) {
          _dialogSetState = setDialogState;
          return ParentVerificationDialog(
            errorMessage: _dialogError,
            isLoading: _dialogIsLoading,
            onSubmit: (email, password) {
              // Show the loading state immediately — do NOT pop the dialog.
              // The dialog stays open until the BLoC emits a result.
              setDialogState(() => _dialogIsLoading = true);
              context.read<AuthBloc>().add(
                VerifyParentAndLogoutRequested(
                  studentUid: widget.uid,
                  parentEmail: email,
                  parentPassword: password,
                ),
              );
            },
          );
        },
      ),
    ).whenComplete(() {
      // Clear the setter once the dialog is off the screen so that a
      // belated BLoC state change can never call into a disposed widget.
      _dialogSetState = null;
    });
  }

  // Called by the BLoC listener when verification fails. Updates the dialog
  // in-place: stops the loading spinner and shows the error message. The
  // dialog remains open so the user can correct their credentials and retry.
  void _updateDialogWithError(String message) {
    _dialogSetState?.call(() {
      _dialogIsLoading = false;
      _dialogError = message;
    });
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
              // Update the already-open dialog instead of closing and
              // reopening it. The loading spinner is replaced with the
              // error banner so the user can try again without disruption.
              _updateDialogWithError(state.message);
            }
            if (state is AuthUnauthenticated) {
              // pushNamedAndRemoveUntil removes all routes — including the
              // verification dialog — so no explicit Navigator.pop() is
              // needed here.
              Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
            }
          },
          child: Scaffold(
            backgroundColor: const Color(0xFFF5F7FA),
            body: SafeArea(
              child: Column(
                children: [
                  Builder(builder: (ctx) => _buildTopNav(ctx)),
                  Expanded(
                    child: IndexedStack(
                      index: _selectedIndex,
                      children: [
                        StudentHome(fullName: widget.fullName, uid: widget.uid),
                        StudentShop(
                          uid: widget.uid,
                          coins: _coins,
                          level: _level,
                        ),
                        StudentLeaderboard(
                          uid: widget.uid,
                          fullName: widget.fullName,
                          parentUid: _parentUid,
                          // Only considered active when this tab is selected.
                          // Prevents firing DataConnect queries at login before
                          // the auth token has fully propagated.
                          isActive: _selectedIndex == 2,
                        ),
                        StudentFriends(
                          uid: widget.uid,
                          fullName: widget.fullName,
                        ),
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
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          // Avatar — tap to open profile page
          GestureDetector(
            onTap: () {
              final shopBloc = context.read<ShopBloc>();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: shopBloc,
                    child: Scaffold(
                      body: SafeArea(
                        child: StudentProfile(
                          fullName: widget.fullName,
                          uid: widget.uid,
                        ),
                      ),
                    ),
                  ),
                ),
              ).then((_) {
                if (mounted) _loadCoinsAndLevel();
              });
            },
            child: Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF4CAF50), width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4CAF50).withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: AvatarWidget(config: _avatarConfig, size: 43),
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
