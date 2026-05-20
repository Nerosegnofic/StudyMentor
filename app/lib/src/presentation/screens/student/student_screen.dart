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
import '../../../services/permission_service.dart';
import '../../../data/providers/dataconnect_provider.dart';
import 'permission_gate_screen.dart';
import 'student_home.dart';
import 'student_quiz.dart';
import 'student_shop.dart';
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
  AvatarConfig _avatarConfig = AvatarConfig.defaults;

  /// True while MascotOverlayService.init() is in progress.
  bool _initializing = true;

  /// True while we are checking whether all permissions are granted.
  /// Kept separate from [_initializing] so the two async paths are clear.
  bool _checkingPermissions = true;

  /// Once set to true, the permission gate is complete and the main
  /// student shell (nav bar + screens) is rendered.
  bool _permissionsGranted = false;

  /// Stable repository instance — created once in initState.
  late final AiEngineRepository _aiRepo;

  /// Subscription to the quiz-trigger stream from MascotOverlayService.
  StreamSubscription<void>? _quizSub;

  // ── Verification dialog state ─────────────────────────────────────────────
  StateSetter? _dialogSetState;
  bool _dialogIsLoading = false;
  String? _dialogError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _aiRepo = AiEngineRepository(baseUrl: _kAiEngineBaseUrl);

    // listenForQuiz must be called BEFORE init() so the stream has a listener
    // when _syncStateFromNative() fires the quiz trigger inside init().
    _quizSub = MascotOverlayService.instance.listenForQuiz(_openQuizOverlay);

    MascotOverlayService.instance.init().then((_) {
      MascotOverlayService.instance.start();
      if (mounted) {
        setState(() => _initializing = false);
      }
    });

    DataConnectProvider().updateLastActiveAt().catchError((_) {});
    _loadCoinsAndLevel();

    // Run the permission check independently of MascotOverlayService.init()
    // so both can proceed in parallel.
    _checkPermissions();
  }

  /// Checks whether all required permissions are already granted.
  /// If they are, skips the gate entirely. If not, the gate screen handles
  /// the flow and calls [_onPermissionsGranted] when done.
  Future<void> _checkPermissions() async {
    final missing = await PermissionService.firstMissingPermission();
    if (!mounted) return;

    if (missing == null) {
      // All permissions are already granted — skip the gate.
      setState(() {
        _checkingPermissions = false;
        _permissionsGranted = true;
      });
    } else {
      // Show the gate screen.
      setState(() {
        _checkingPermissions = false;
        _permissionsGranted = false;
      });
    }
  }

  /// Called by [PermissionGateScreen] when all permissions have been confirmed.
  void _onPermissionsGranted() {
    if (!mounted) return;
    setState(() => _permissionsGranted = true);
  }

  /// Called by [PermissionGateScreen] when the user taps "Sign out".
  void _onGateSignOut() {
    context.read<AuthBloc>().add(LogoutRequested());
  }

  Future<void> _loadCoinsAndLevel() async {
    try {
      final provider = DataConnectProvider();
      final results = await Future.wait([
        provider.getStudentProfile(widget.uid),
        provider.getStudentAvatar(widget.uid),
      ]);
      if (mounted) {
        final profile = results[0] as Map<String, dynamic>;
        final avatarMap = results[1];
        setState(() {
          _coins = (profile['total_coins'] as int?) ?? 0;
          _xp = (profile['total_xp'] as int?) ?? 0;
          _level = (_xp ~/ 500) + 1;
          if (avatarMap != null) {
            _avatarConfig = AvatarConfig.fromMap(avatarMap);
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

  // ── Quiz overlay ──────────────────────────────────────────────────────────

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

  void _showVerificationDialog() {
    _dialogIsLoading = false;
    _dialogError = null;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setDialogState) {
          _dialogSetState = setDialogState;
          return ParentVerificationDialog(
            errorMessage: _dialogError,
            isLoading: _dialogIsLoading,
            onSubmit: (email, password) {
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
      _dialogSetState = null;
    });
  }

  void _updateDialogWithError(String message) {
    _dialogSetState?.call(() {
      _dialogIsLoading = false;
      _dialogError = message;
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // ── Phase 1: MascotOverlayService is still initialising ─────────────────
    if (_initializing || _checkingPermissions) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F7FA),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // ── Phase 2: One or more permissions are missing ─────────────────────────
    if (!_permissionsGranted) {
      return BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthUnauthenticated) {
            Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
          }
        },
        child: PermissionGateScreen(
          onAllGranted: _onPermissionsGranted,
          onSignOut: _onGateSignOut,
        ),
      );
    }

    // ── Phase 3: All permissions granted — show the full student shell ───────
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
              _updateDialogWithError(state.message);
            }
            if (state is AuthUnauthenticated) {
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

  // ── Custom top navigation bar ─────────────────────────────────────────────

  Widget _buildTopNav(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
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
          _navPill(
            icon: Icons.star_rounded,
            iconColor: const Color(0xFFFFC107),
            label: _formatNum(_xp),
          ),
          const SizedBox(width: 8),
          _navPill(
            icon: Icons.monetization_on_rounded,
            iconColor: const Color(0xFFFFA000),
            label: _formatNum(_coins),
          ),
          const SizedBox(width: 6),
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
