import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../l10n/app_localizations.dart';
import '../../utils/error_localizer.dart';
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
import '../../../bloc/garden/garden_state.dart';
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
import '../../../features/mascot/mascot_cubit.dart';
import '../../../features/mascot/mascot_state.dart';
import '../../../features/mascot/mascot_widget.dart';
import '../../../services/quiz_lock_service.dart';
import 'student_permission_gate_screen.dart';
import 'student_home.dart';
import 'student_quiz.dart';
import 'student_profile.dart';
import 'shop/custom_shop_screen.dart';
import '../../../bloc/notifications/notifications_bloc.dart';
import '../../../bloc/notifications/notifications_event.dart';
import '../../../bloc/notifications/notifications_state.dart';
import '../../../domain/models/notification_model.dart';
import '../../widgets/student_home/student_notifications_sheet.dart';


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

  /// True while [_openQuizOverlay] / [_onQuizRestoreTriggered] are awaiting the
  /// async `QuizLockService.loadSession()` lookup. Guards the await gap so two
  /// concurrent triggers (e.g. the forced-quiz stream racing the native restore
  /// signal on relaunch) cannot both open a quiz. Always paired with [_quizIsOpen].
  bool _quizResolving = false;

  /// Whether the student has at least one subject uploaded by the parent.
  /// null = garden not loaded yet, false = no subjects, true = has subjects.
  bool? _hasSubjects;

  /// True when a forced-quiz trigger arrived before garden state was known.
  /// Flushed (and quiz opened or suppressed) when [GardenLoaded] is received.
  bool _pendingQuizAwaitingGarden = false;

  /// Parent-configured quiz question count — kept in sync when config loads.
  QuizCount _quizCount = const Auto();

  /// Student's grade level (set by the parent) — used to size generated quizzes.
  /// Null until loaded; falls back to 5 in the quiz request.
  int? _studentGrade;

  /// Stable repository instance — created once in initState.
  late final AiEngineRepository _aiRepo;

  /// Subscription to the quiz-trigger stream from MascotOverlayService.
  StreamSubscription<void>? _quizSub;

  /// Subscription to the quiz-restore stream fired after task removal / reboot.
  StreamSubscription<void>? _quizRestoreSub;

  /// Buffered restore session received before the shell was ready.
  QuizSessionData? _pendingQuizRestoreAfterShell;

  // ── Verification dialog state ─────────────────────────────────────────────
  StateSetter? _dialogSetState;
  bool _dialogIsLoading = false;
  String? _dialogError;

  // ── Persistent BLoC instances ─────────────────────────────────────────────
  late final ShopBloc _shopBloc;
  late final GardenBloc _gardenBloc;
  late final GamificationBloc _gamificationBloc;
  late final MascotCubit _mascotCubit;

  /// Lets the resume handler refresh the home screen's data (XP/streak/garden/
  /// daily snapshot) by reusing StudentHome.refresh().
  final _homeKey = GlobalKey<StudentHomeState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _aiRepo = AiEngineRepository(baseUrl: AiEngineRepository.defaultBaseUrl);

    _shopBloc = ShopBloc();
    _gardenBloc = GardenBloc();
    _mascotCubit = MascotCubit();
    _gamificationBloc = GamificationBloc(
      repository: GamificationRepositoryImpl(),
    )..add(LoadGamificationDataRequested(studentId: widget.uid))
     ..add(CheckDailyLoginRewardRequested(studentId: widget.uid));

    _quizSub = MascotOverlayService.instance.listenForQuiz(_onQuizTriggered);
    _quizRestoreSub =
        MascotOverlayService.instance.listenForQuizRestore(_onQuizRestoreTriggered);

    _initMascotService();

    _loadAvatar();
    _loadGrade();

    // Load this student's notifications into the shared NotificationsBloc so
    // the header bell reflects unread state and the sheet has content.
    context.read<NotificationsBloc>().add(
          LoadStudentNotificationsRequested(widget.uid),
        );

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

    // Recover the monitoring service if an earlier foreground-service start was
    // refused by the OS (e.g. the app was briefly backgrounded during the login /
    // permission flow). Idempotent; the native side now bails out cleanly instead
    // of crashing when it cannot enter the foreground.
    if (_permissionsGranted && !_initializing && !_checkingPermissions) {
      unawaited(MascotOverlayService.instance.ensureStarted());
    }

    // Reload home data (XP/streak/garden/daily snapshot) so the dashboard isn't
    // stale after returning from background or from a quiz. Skipped while a quiz
    // overlay is open to avoid churning state mid-quiz.
    if (_permissionsGranted &&
        !_initializing &&
        !_checkingPermissions &&
        !_quizIsOpen) {
      _homeKey.currentState?.refresh();

      // Top up the quiz cache for every active subject so the next start is
      // instant for any subject — catches subjects that went cold via ingestion
      // while the app was backgrounded. Fire-and-forget and idempotent (already-warm
      // subjects are cheap no-ops server-side).
      unawaited(_aiRepo.warmAllQuizzes());
    }

    // Sync on resume only when the native side flags a package change.
    InstalledAppsService.instance.isInventoryDirty().then((dirty) {
      if (dirty && mounted) {
        context.read<AuthBloc>().add(
          SyncInstalledAppsRequested(studentUid: widget.uid),
        );
      }
    });

    // On every resume, re-run the quiz gate. It resumes an in-progress session
    // if one exists (covers a voluntary quiz that was swiped away even when the
    // student is not blocked), otherwise opens a fresh quiz only when
    // shouldShowQuiz. Cheap: a single SharedPreferences read when not already open.
    if (_permissionsGranted &&
        !_initializing &&
        !_checkingPermissions &&
        !_quizIsOpen &&
        !_quizResolving) {
      _openQuizOverlay();
    }
  }

  @override
  void dispose() {
    _quizSub?.cancel();
    _quizRestoreSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    MascotOverlayService.instance.stop();
    _shopBloc.close();
    _gardenBloc.close();
    _gamificationBloc.close();
    _mascotCubit.close();
    super.dispose();
  }

  // ── Quiz overlay ──────────────────────────────────────────────────────────

  void _onQuizTriggered() {
    final shellReady =
        !_initializing && !_checkingPermissions && _permissionsGranted;
    if (!shellReady) {
      debugPrint(
        '[StudentScreen] quiz trigger arrived before shell was ready — buffering.',
      );
      _pendingQuizAfterInit = true;
      return;
    }
    // _openQuizOverlay() is the single gate: it restores an in-progress session
    // if one exists, otherwise opens a fresh quiz only when shouldShowQuiz.
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

    // Flush a buffered quiz-restore session (e.g. received from native before
    // the permission gate finished).
    if (_pendingQuizRestoreAfterShell != null) {
      final session = _pendingQuizRestoreAfterShell!;
      _pendingQuizRestoreAfterShell = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openQuizOverlayWithRestore(session);
      });
      return;
    }

    if (_pendingQuizAfterInit) {
      _pendingQuizAfterInit = false;
      debugPrint(
        '[StudentScreen] shell ready — flushing buffered quiz trigger.',
      );
      // The gate (_openQuizOverlay) restores an in-progress session if present,
      // otherwise opens a fresh quiz only when shouldShowQuiz is still true.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openQuizOverlay();
      });
    }

    // Top up the quiz cache for every active subject on dashboard load so the
    // first start is instant for any subject — including ones the student has
    // never quizzed (warmed before first request rather than cold-starting).
    // Fire-and-forget and idempotent server-side, so repeated _onShellReady calls
    // are cheap no-ops once caches are full.
    unawaited(_aiRepo.warmAllQuizzes());
  }

  /// Single entry point for showing the quiz overlay. Enforces **restore
  /// precedence**: if an in-progress quiz session is persisted on disk
  /// (`QuizLockService.loadSession()` non-null), it is resumed exactly — a fresh
  /// quiz is **never** generated while a session exists. This closes the bug
  /// where swiping mid-quiz spawned a new quiz (different subject, lost progress)
  /// and let the student dodge submission. A fresh quiz is opened only when no
  /// session exists AND `shouldShowQuiz` is true.
  void _openQuizOverlay() {
    if (!mounted) return;

    // ── No subjects guard ──────────────────────────────────────────────────
    // Never prompt for a quiz until the parent has uploaded at least one subject.
    if (_hasSubjects == false) {
      debugPrint('[StudentScreen] Quiz suppressed — no subjects uploaded yet.');
      return;
    }
    if (_hasSubjects == null) {
      // Garden hasn't responded yet — buffer this trigger.
      debugPrint('[StudentScreen] Quiz deferred — waiting for garden to load.');
      _pendingQuizAwaitingGarden = true;
      return;
    }

    // Already open, or another trigger is mid-resolution — ignore duplicates.
    if (_quizIsOpen || _quizResolving) return;

    // Restore precedence: check for a saved in-progress session before deciding
    // whether to resume it or generate a new quiz. _quizResolving guards the
    // await gap so a concurrent trigger cannot also open a quiz.
    _quizResolving = true;
    QuizLockService.instance.loadSession().then((session) {
      _quizResolving = false;
      if (!mounted || _quizIsOpen) return;
      if (session != null) {
        _openQuizOverlayWithRestore(session);
      } else if (MascotOverlayService.instance.shouldShowQuiz) {
        _pushFreshQuiz();
      }
    }).catchError((_) {
      _quizResolving = false;
    });
  }

  /// Pushes a brand-new forced quiz. Only called from [_openQuizOverlay] after
  /// confirming no in-progress session exists.
  void _pushFreshQuiz() {
    if (!mounted || _quizIsOpen) return;
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
            // Grant the configured per-quiz reward time to the student.
            final reward =
                MascotOverlayService.instance.config.rewardPerQuizSeconds;
            if (reward > 0) {
              MascotOverlayService.instance.addRewardTime(reward);
            }
          } else {
            MascotOverlayService.instance.markQuizDismissed();
          }

          // Flush any buffered celebrations now that the quiz is gone.
          _flushPendingCelebrations();
        });
  }

  // ── Quiz restore (after task removal / reboot) ────────────────────────────

  /// Called when the native side signals that a quiz session must be restored.
  /// Fires on both warm resume (onNewIntent) and cold start (onFlutterUiDisplayed).
  void _onQuizRestoreTriggered() {
    // If the quiz overlay is already in the navigation stack (warm resume
    // where the process was not killed), there is nothing to do — the existing
    // overlay is still live and will resume normally.
    if (_quizIsOpen || _quizResolving) return;

    _quizResolving = true;
    QuizLockService.instance.loadSession().then((session) {
      _quizResolving = false;
      if (session == null || !mounted || _quizIsOpen) return;
      final shellReady =
          !_initializing && !_checkingPermissions && _permissionsGranted;
      if (!shellReady) {
        _pendingQuizRestoreAfterShell = session;
        return;
      }
      _openQuizOverlayWithRestore(session);
    }).catchError((_) {
      _quizResolving = false;
    });
  }

  /// Pushes QuizOverlayPage seeded with a previously saved [session].
  void _openQuizOverlayWithRestore(QuizSessionData session) {
    if (!mounted || _quizIsOpen) return;

    // Respect the no-subjects guard the same way _openQuizOverlay does.
    if (_hasSubjects == false) return;
    if (_hasSubjects == null) {
      _pendingQuizRestoreAfterShell = session;
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
                studentId: session.studentId,
                contextType: session.contextType,
                totalQuestions: session.totalQuestions,
                autoLength: session.autoLength,
                subjectId: session.subjectId,
                studentGrade: session.studentGrade,
                restoredSession: session,
              ),
            ),
          ),
        )
        .then((completed) {
          _quizIsOpen = false;
          if (completed == true) {
            MascotOverlayService.instance.markQuizCompleted();
            final reward =
                MascotOverlayService.instance.config.rewardPerQuizSeconds;
            if (reward > 0) {
              MascotOverlayService.instance.addRewardTime(reward);
            }
          } else {
            MascotOverlayService.instance.markQuizDismissed();
          }
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
          if (milestoneHit == null) return;
          if (!context.mounted) return;
          StreakMilestoneModal.show(
            context,
            milestoneDays: milestoneHit,
            coinReward: 20,
            currentStreak: currentStreak,
          );
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
    if (_initializing || _checkingPermissions) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const MascotWidget(state: MascotState.idle, size: 140),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context).appTitle,
                style: GoogleFonts.cairo(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1F2937),
                  letterSpacing: -0.4,
                ),
              ),
            ],
          ),
        ),
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
        BlocProvider<ShopBloc>.value(value: _shopBloc),
        BlocProvider<GardenBloc>.value(value: _gardenBloc),
        BlocProvider<GamificationBloc>.value(value: _gamificationBloc),
        BlocProvider<MascotCubit>.value(value: _mascotCubit),
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
        child: MultiBlocListener(
          listeners: [
            BlocListener<GardenBloc, GardenState>(
              listener: (context, state) {
                if (state is GardenLoaded) {
                  setState(() => _hasSubjects = state.plants.isNotEmpty);
                  if (_pendingQuizAwaitingGarden) {
                    _pendingQuizAwaitingGarden = false;
                    if (_hasSubjects!) {
                      _openQuizOverlay();
                    } else {
                      debugPrint('[StudentScreen] Deferred quiz dropped — no subjects.');
                    }
                  }
                }
              },
            ),
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
                  _updateDialogWithError(
                    localizeError(state.message, AppLocalizations.of(context)),
                  );
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
      ),
    );
  }

  // ── Custom top navigation bar ─────────────────────────────────────────────

  Widget _buildTopNav(BuildContext context) {
    return BlocBuilder<NotificationsBloc, NotificationsState>(
      builder: (context, state) {
        final notifications =
            state is NotificationsLoaded ? state.notifications : <NotificationModel>[];
        final hasUnread = notifications.any((n) => !n.isRead);
        return StudentTopBar(
          avatarConfig: _avatarConfig,
          level: _level,
          coins: _coins,
          hasNotifications: hasUnread,
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
          onNotificationsTap: () => _showNotificationsSheet(context),
        );
      },
    );
  }

  void _showNotificationsSheet(BuildContext context) {
    final bloc = context.read<NotificationsBloc>();
    bloc.add(RefreshStudentNotificationsRequested(widget.uid));
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: StudentNotificationsSheet(studentUid: widget.uid),
      ),
    );
  }
}
