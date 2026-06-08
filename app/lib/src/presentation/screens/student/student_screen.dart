import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/auth/auth_bloc.dart';
import '../../../bloc/auth/auth_event.dart';
import '../../../bloc/auth/auth_state.dart';
import '../../../bloc/shop/shop_bloc.dart';

import '../../../data/repositories/ai_engine_repository.dart';
import '../../../bloc/garden/garden_bloc.dart';
import '../../../domain/models/app_config_model.dart';
import '../../../domain/models/avatar_config.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/parent_verification_dialog.dart';
import '../../../services/overlay/mascot_overlay_service.dart';
import '../../../services/installed_apps_service.dart';
import '../../../services/permission_service.dart';
import '../../../services/device_admin_service.dart';
import '../../../data/providers/dataconnect_provider.dart';
import 'permission_gate_screen.dart';
import 'student_home.dart';
import 'student_quiz.dart';
import 'student_profile.dart';
import 'shop/custom_shop_screen.dart';
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

  /// True while _initMascotService() is in progress.
  bool _initializing = true;

  /// True while we are checking whether all permissions are granted.
  bool _checkingPermissions = true;

  /// Once set to true, the permission gate is complete and the main
  /// student shell (nav bar + screens) is rendered.
  bool _permissionsGranted = false;

  /// True when a quiz trigger arrived while the shell was not yet ready.
  /// Flushed by [_onShellReady].
  bool _pendingQuizAfterInit = false;

  /// Defense-in-depth guard against double-push of QuizOverlayPage.
  /// Set to true immediately before pushing, cleared in the .then() callback
  /// after the route pops.
  bool _quizIsOpen = false;

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

    _quizSub = MascotOverlayService.instance.listenForQuiz(_onQuizTriggered);

    _initMascotService();

    DataConnectProvider().updateLastActiveAt().catchError((_) {});
    _loadCoinsAndLevel();

    // Sync the installed-app inventory on every login so DataConnect always
    // has an up-to-date list for this account. The repository's diff logic
    // ensures only changed apps are written, so this is cheap when nothing
    // has changed.
    context.read<AuthBloc>().add(
      SyncInstalledAppsRequested(studentUid: widget.uid),
    );

    _checkPermissions();
  }

  Future<void> _initMascotService() async {
    try {
      await MascotOverlayService.instance.init();
    } catch (e) {
      debugPrint('[StudentScreen] MascotOverlayService.init() failed: $e');
      if (mounted) setState(() => _initializing = false);
      return;
    }

    if (mounted) {
      try {
        final repo = context.read<AuthBloc>().repository;
        final (:config, :rules) = await repo.getAppConfigForStudent(widget.uid);
        if (mounted) {
          await MascotOverlayService.instance.updateMonitoredApps(
            rules,
            config: config ?? const StudentConfigModel(),
          );
        }
      } catch (e) {
        debugPrint(
          '[StudentScreen] Config pre-load failed, using defaults: $e',
        );
      }
    }

    MascotOverlayService.instance.start();

    if (mounted) {
      setState(() => _initializing = false);
      _onShellReady();
    }
  }

  Future<void> _checkPermissions() async {
    final missing = await PermissionService.firstMissingPermission();
    if (!mounted) return;

    if (missing == null) {
      await DeviceAdminService.onPermissionsGranted();
      setState(() {
        _checkingPermissions = false;
        _permissionsGranted = true;
      });
      _onShellReady();
    } else {
      setState(() {
        _checkingPermissions = false;
        _permissionsGranted = false;
      });
    }
  }

  void _onPermissionsGranted() {
    if (!mounted) return;
    setState(() => _permissionsGranted = true);
    _onShellReady();
  }

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
          // _coins = 200; test value 
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

    // Sync on resume only when the native side flags a package change.
    InstalledAppsService.instance.isInventoryDirty().then((dirty) {
      if (dirty && mounted) {
        context.read<AuthBloc>().add(
          SyncInstalledAppsRequested(studentUid: widget.uid),
        );
      }
    });

    if (_permissionsGranted &&
        !_initializing &&
        !_checkingPermissions &&
        !_quizIsOpen &&
        MascotOverlayService.instance.shouldShowQuiz) {
      debugPrint(
        '[StudentScreen] warm-resume: shouldShowQuiz=true and no quiz open — re-arming.',
      );
      _openQuizOverlay();
    }
  }

  @override
  void dispose() {
    _quizSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    MascotOverlayService.instance.stop();
    super.dispose();
  }

  // ── Quiz overlay ──────────────────────────────────────────────────────────

  void _onQuizTriggered() {
    if (!MascotOverlayService.instance.shouldShowQuiz) {
      debugPrint(
        '[StudentScreen] quiz trigger suppressed — already dismissed '
        'for this cooldown.',
      );
      return;
    }

    final shellReady =
        !_initializing && !_checkingPermissions && _permissionsGranted;
    if (!shellReady) {
      debugPrint(
        '[StudentScreen] quiz trigger arrived before shell was ready — buffering.',
      );
      _pendingQuizAfterInit = true;
      return;
    }
    _openQuizOverlay();
  }

  void _onShellReady() {
    if (!mounted) return;
    if (_initializing || _checkingPermissions || !_permissionsGranted) return;

    if (_pendingQuizAfterInit && MascotOverlayService.instance.shouldShowQuiz) {
      _pendingQuizAfterInit = false;
      debugPrint(
        '[StudentScreen] shell ready — flushing buffered quiz trigger.',
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openQuizOverlay();
      });
    } else if (_pendingQuizAfterInit) {
      _pendingQuizAfterInit = false;
      debugPrint(
        '[StudentScreen] shell ready — buffered quiz trigger dropped '
        '(quiz dismissed for this cooldown).',
      );
    }
  }

  void _openQuizOverlay() {
    if (!mounted) return;

    if (_quizIsOpen) {
      debugPrint(
        '[StudentScreen] _openQuizOverlay called while quiz is already open — ignoring duplicate.',
      );
      return;
    }

    _quizIsOpen = true;

    MascotOverlayService.instance.markQuizShown();

    Navigator.of(context)
        .push(
          MaterialPageRoute<bool?>(
            fullscreenDialog: true,
            builder: (_) => QuizOverlayPage(repository: _aiRepo),
          ),
        )
        .then((completed) {
          _quizIsOpen = false;
          if (completed == true) {
            MascotOverlayService.instance.markQuizCompleted();
          } else {
            MascotOverlayService.instance.markQuizDismissed();
          }
        });
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
    if (_initializing || _checkingPermissions) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F7FA),
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
            if (state is AppRulesLoaded && state.studentUid == widget.uid) {
              MascotOverlayService.instance.updateMonitoredApps(
                state.rules,
                config: state.config,
              );
            }

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
                      ],
                    ),
                  ),
                ],
              ),
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
                child: AvatarWidget(config: _avatarConfig, size: 43.0),
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
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: context.read<ShopBloc>(),
                    child: CustomShopScreen(
                      studentUid: widget.uid,
                      currentCoins: _coins,
                      currentLevel: _level,
                    ),
                  ),
                ),
              ).then((_) {
                if (mounted) _loadCoinsAndLevel();
              });
            },
            child: _navPill(
              icon: Icons.monetization_on_rounded,
              iconColor: const Color(0xFFFFA000),
              label: _formatNum(_coins),
            ),
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
