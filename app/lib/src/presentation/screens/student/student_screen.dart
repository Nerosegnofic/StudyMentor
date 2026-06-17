import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/auth/auth_bloc.dart';
import '../../../bloc/auth/auth_event.dart';
import '../../../bloc/auth/auth_state.dart';
import '../../../bloc/shop/shop_bloc.dart';
import '../../../bloc/shop/shop_state.dart';
import '../../../bloc/gamification/gamification_bloc.dart';
import '../../../bloc/gamification/gamification_event.dart';
import '../../../bloc/gamification/gamification_state.dart';
import '../../../domain/models/gamification_enums.dart';
import '../../../data/repositories/gamification_repository_impl.dart';
import '../../../data/constants/gamification_levels.dart';

import '../../../data/repositories/ai_engine_repository.dart';
import '../../../bloc/garden/garden_bloc.dart';
import '../../../domain/models/app_config_model.dart';
import '../../../domain/models/quiz_count.dart';
import '../../../domain/models/avatar_config.dart';
import '../../widgets/student_home/student_top_bar.dart';
import '../../widgets/gamification/level_up_modal.dart';
// LevelUpCelebrationScreen is exported from level_up_modal.dart
import '../../widgets/gamification/streak_milestone_modal.dart';
import '../../utils/reward_toast.dart';
import '../../widgets/parent_verification_dialog.dart';
import '../../../services/overlay/mascot_overlay_service.dart';
import '../../../services/installed_apps_service.dart';
import '../../../services/permission_service.dart';
import '../../../services/device_admin_service.dart';
import '../../../data/providers/dataconnect_provider.dart';
import 'student_permission_gate_screen.dart';
import 'student_home.dart';
import 'student_quiz.dart';
import 'student_profile.dart';
import 'shop/custom_shop_screen.dart';
import '../../../../l10n/app_localizations.dart';

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
  final int _selectedIndex = 0;
  int _coins = 0;
  int _xp = 0;
  int _level = 1;

  // ── Pending celebrations (buffered while a quiz overlay is open) ──────────
  int? _pendingLevelUp;
  int? _pendingMilestone;
  int _pendingXp = 0;
  int _pendingCoins = 0;
  int _pendingMilestoneStreak = 0;

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

  /// Parent-configured quiz question count — kept in sync when config loads.
  QuizCount _quizCount = const Auto();

  /// Student's grade level (set by the parent) — used to size generated quizzes.
  /// Null until loaded; falls back to 5 in the quiz request.
  int? _studentGrade;

  /// Stable repository instance — created once in initState.
  late final AiEngineRepository _aiRepo;

  /// Subscription to the quiz-trigger stream from MascotOverlayService.
  StreamSubscription<void>? _quizSub;

  // ── Verification dialog state ─────────────────────────────────────────────
  StateSetter? _dialogSetState;
  bool _dialogIsLoading = false;
  String? _dialogError;

  // ── Persistent BLoC instances ─────────────────────────────────────────────
  late final ShopBloc _shopBloc;
  late final GardenBloc _gardenBloc;
  late final GamificationBloc _gamificationBloc;

  /// Lets the resume handler refresh the home screen's data (XP/streak/garden/
  /// daily snapshot) by reusing StudentHome.refresh().
  final _homeKey = GlobalKey<StudentHomeState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _aiRepo = AiEngineRepository(baseUrl: _kAiEngineBaseUrl);

    _shopBloc = ShopBloc();
    _gardenBloc = GardenBloc();
    _gamificationBloc = GamificationBloc(
      repository: GamificationRepositoryImpl(),
    )..add(LoadGamificationDataRequested(studentId: widget.uid))
     ..add(CheckDailyLoginRewardRequested(studentId: widget.uid));

    _quizSub = MascotOverlayService.instance.listenForQuiz(_onQuizTriggered);

    _initMascotService();

    _loadAvatar();
    _loadGrade();

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
      // FIX: pass studentUid so the native service can detect account switches
      // and reset timer state when a different student logs in.
      await MascotOverlayService.instance.init(studentUid: widget.uid);
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
          final resolvedConfig = config ?? const StudentConfigModel();
          _quizCount = resolvedConfig.quizCount;
          await MascotOverlayService.instance.updateMonitoredApps(
            rules,
            studentUid: widget.uid,
            config: resolvedConfig,
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
      final profile = await AiEngineRepository.instance.getGamificationProfile(widget.uid);
      if (mounted) {
        setState(() {
          _coins = (profile['coins_total'] as int?) ?? 0;
          _xp = (profile['xp_total'] as int?) ?? 0;
          _level = (profile['current_level'] as int?) ?? levelForXp(_xp).levelNumber;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadAvatar() async {
    try {
      final avatarMap = await DataConnectProvider().getStudentAvatar(widget.uid);
      if (mounted && avatarMap != null) {
        setState(() => _avatarConfig = AvatarConfig.fromMap(avatarMap));
      }
    } catch (_) {}
  }

  Future<void> _loadGrade() async {
    try {
      final profile = await DataConnectProvider().getStudentProfile(widget.uid);
      if (mounted) {
        setState(() => _studentGrade = profile['grade_level'] as int?);
      }
    } catch (_) {}
  }

  /// Re-fetch the parent-configured quiz count so a change made while the student
  /// app was backgrounded takes effect on the next forced quiz. (The voluntary path
  /// already reloads config when the subject screen opens.) The count is also
  /// enforced server-side: a pre-warmed quiz with a stale count is not reused — a
  /// fresh quiz is generated for the new count instead.
  Future<void> _refreshQuizCount() async {
    try {
      final repo = context.read<AuthBloc>().repository;
      final config = (await repo.getAppConfigForStudent(widget.uid)).config;
      if (mounted && config != null) {
        setState(() => _quizCount = config.quizCount);
      }
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;

    // Pick up parent config changes (e.g. quiz count) made while backgrounded.
    _refreshQuizCount();

    // Reload home data (XP/streak/garden/daily snapshot) so the dashboard isn't
    // stale after returning from background or from a quiz. Skipped while a quiz
    // overlay is open to avoid churning state mid-quiz.
    if (_permissionsGranted &&
        !_initializing &&
        !_checkingPermissions &&
        !_quizIsOpen) {
      _homeKey.currentState?.refresh();
    }

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
    _shopBloc.close();
    _gardenBloc.close();
    _gamificationBloc.close();
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

    // The BlocListener for GamificationBloc only enters the tree once the shell
    // is rendered (after permissions are granted). If gamification events were
    // emitted earlier (while the spinner / permission gate was showing), the
    // listener missed them. Read the current BLoC state here and apply it so
    // the coins/xp/level bar is always up-to-date on first render.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final s = _gamificationBloc.state;
      if (s is GamificationLoaded) {
        setState(() {
          _coins = s.profile.coinsTotal;
          _xp = s.profile.xpTotal;
          _level = s.profile.currentLevel;
        });
      } else if (s is GamificationRewardProcessed) {
        setState(() {
          _coins = s.profile.coinsTotal;
          _xp = s.profile.xpTotal;
          _level = s.profile.currentLevel;
        });
      }
    });

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
    // ── Defense-in-depth guard ─────────────────────────────────────────────
    // The primary guard lives in MascotOverlayService._onLimitReached()
    // (the _isBlocked early-return). This flag catches any duplicate signal
    // that slips through — e.g. a race between broadcastState PATH 1 and the
    // startActivity PATH 2 on a warm resume where both arrive after _isBlocked
    // has already been set to true by the first call but before the stream
    // listener fires for the second.
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

            builder: (_) => MultiBlocProvider(
              providers: [
                BlocProvider.value(value: _gamificationBloc),
                BlocProvider.value(value: _gardenBloc),
              ],
              child: QuizOverlayPage(
                repository: _aiRepo,
                studentId: widget.uid,
                contextType: QuizContext.forced,
                studentGrade: _studentGrade,
                totalQuestions: switch (_quizCount) {
                  Auto() => 5,
                  Fixed(:final count) => count,
                },
                autoLength: _quizCount is Auto,
              ),

            ),
          ),
        )
        .then((completed) {
          _quizIsOpen = false;
          if (completed == true) {
            MascotOverlayService.instance.markQuizCompleted();
          } else {
            MascotOverlayService.instance.markQuizDismissed();
          }

          // Flush any buffered celebrations now that the quiz is gone.
          _flushPendingCelebrations();
        });
  }

  // ── Celebration helpers ────────────────────────────────────────────────────

  /// Shows reward toast, then level-up fullscreen, then streak milestone.
  /// Called either immediately (for non-quiz rewards) or after quiz pops.
  void _showCelebrations(
    BuildContext context, {
    required int xp,
    required int coins,
    int? leveledUpTo,
    int? milestoneHit,
    int currentStreak = 0,
  }) {
    if (xp > 0 || coins > 0) {
      RewardToast.show(context, xp, coins);
    }
    if (leveledUpTo != null) {
      // Schedule after the current frame so the toast is visible first.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        LevelUpCelebrationScreen.show(
          context,
          kGamificationLevels.firstWhere(
            (l) => l.levelNumber == leveledUpTo,
            orElse: () => kGamificationLevels.first,
          ),
        ).then((_) {
          // After level-up dismisses, show streak milestone if any.
          if (milestoneHit != null && mounted) {
            StreakMilestoneModal.show(
              context,
              milestoneDays: milestoneHit,
              coinReward: 20,
              currentStreak: currentStreak,
            );
          }
        });
      });
    } else if (milestoneHit != null) {
      StreakMilestoneModal.show(
        context,
        milestoneDays: milestoneHit,
        coinReward: 20,
        currentStreak: currentStreak,
      );
    }
  }

  /// Drains any buffered celebration data and shows them now.
  void _flushPendingCelebrations() {
    if (!mounted) return;
    final xp = _pendingXp;
    final coins = _pendingCoins;
    final levelUp = _pendingLevelUp;
    final milestone = _pendingMilestone;
    final streak = _pendingMilestoneStreak;

    // Clear immediately to prevent double-flush.
    _pendingXp = 0;
    _pendingCoins = 0;
    _pendingLevelUp = null;
    _pendingMilestone = null;
    _pendingMilestoneStreak = 0;

    if (xp == 0 && coins == 0 && levelUp == null && milestone == null) return;

    // Wait one frame so the home screen is fully visible.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showCelebrations(
        context,
        xp: xp,
        coins: coins,
        leveledUpTo: levelUp,
        milestoneHit: milestone,
        currentStreak: streak,
      );
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
    // MultiBlocProvider is always at the root so the widget type never changes
    // across the loading → permission-gate → main transitions. Changing the
    // root type forces Flutter to destroy and recreate the entire element tree,
    // which can miss a frame and briefly reveal the black Android window
    // background behind the Flutter surface.
    return MultiBlocProvider(
      providers: [
        BlocProvider<ShopBloc>.value(value: _shopBloc),
        BlocProvider<GardenBloc>.value(value: _gardenBloc),
        BlocProvider<GamificationBloc>.value(value: _gamificationBloc),
      ],
      child: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
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

    return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) {
            context.read<AuthBloc>().add(
              StudentLogoutVerificationRequested(studentUid: widget.uid),
            );
          }
        },
        child: MultiBlocListener(
          listeners: [
            BlocListener<AuthBloc, AuthState>(
              listener: (context, state) {
                if (state is LegacyAppRulesLoaded && state.studentUid == widget.uid) {
                  MascotOverlayService.instance.updateMonitoredApps(
                    state.rules,
                    studentUid: widget.uid,
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
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil('/', (_) => false);
                }
              },
            ),
            BlocListener<GamificationBloc, GamificationState>(
              listener: (context, state) {
                if (state is GamificationLoaded) {
                  setState(() {
                    _coins = state.profile.coinsTotal;
                    _xp = state.profile.xpTotal;
                    _level = state.profile.currentLevel;
                  });
                }
                if (state is GamificationRewardProcessed) {
                  setState(() {
                    _coins = state.profile.coinsTotal;
                    _xp = state.profile.xpTotal;
                    _level = state.profile.currentLevel;
                  });

                  if (_quizIsOpen) {
                    // Buffer celebrations — they'll be flushed after "Done".
                    _pendingXp = state.xpEarned;
                    _pendingCoins = state.coinsEarned;
                    _pendingLevelUp = state.leveledUpTo;
                    _pendingMilestone = state.milestoneHit;
                    _pendingMilestoneStreak = state.profile.currentStreak;
                  } else {
                    // Show immediately (e.g. daily login reward).
                    _showCelebrations(
                      context,
                      xp: state.xpEarned,
                      coins: state.coinsEarned,
                      leveledUpTo: state.leveledUpTo,
                      milestoneHit: state.milestoneHit,
                      currentStreak: state.profile.currentStreak,
                    );
                  }
                }
              },
            ),
            BlocListener<ShopBloc, ShopState>(
              listener: (context, state) {
                if (state is ShopLoaded) {
                  setState(() {
                    _coins = state.coins;
                    // Only commit avatar changes after the user taps Done and
                    // the DB write completes — not on every equip toggle.
                    if (state.avatarSaved) {
                      _avatarConfig = state.avatarConfig;
                    }
                  });
                }
              },
            ),
          ],
          child: Scaffold(
            backgroundColor: const Color(0xFFF5F7FA),
            body: SafeArea(
              top: false,
              child: Column(
                children: [
                  Builder(builder: (ctx) => _buildTopNav(ctx)),
                  Expanded(
                    child: IndexedStack(
                      index: _selectedIndex,
                      children: [
                        StudentHome(
                          key: _homeKey,
                          fullName: widget.fullName,
                          uid: widget.uid,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
    );
  }

  // ── Custom top navigation bar ─────────────────────────────────────────────

  Widget _buildTopNav(BuildContext context) {
    return StudentTopBar(
      avatarConfig: _avatarConfig,
      level: _level,
      coins: _coins,
      onAvatarTap: () {
        final shopBloc = context.read<ShopBloc>();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: shopBloc,
              child: Scaffold(
                // top: false lets the profile's green header paint into the
                // status/notification bar (the header owns the top inset).
                body: SafeArea(
                  top: false,
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
      onCoinsTap: () {
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
          if (mounted) {
            _loadCoinsAndLevel();
            _loadAvatar();
          }
        });
      },
      onNotificationsTap: () {},
    );
  }
}
