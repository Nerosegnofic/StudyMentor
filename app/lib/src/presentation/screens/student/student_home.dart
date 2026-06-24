import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/auth/auth_bloc.dart';
import '../../../bloc/auth/auth_event.dart';
import '../../../bloc/auth/auth_state.dart';
import '../../../bloc/garden/garden_bloc.dart';
import '../../../bloc/garden/garden_event.dart';
import '../../../bloc/garden/garden_state.dart';
import '../../../bloc/gamification/gamification_bloc.dart';
import '../../../bloc/gamification/gamification_state.dart';
import '../../../data/repositories/ai_engine_repository.dart';
import '../../../domain/models/garden_plant_model.dart';
import '../../../domain/models/report_models.dart';
import '../../../services/installed_apps_service.dart';
import '../../../services/overlay/mascot_overlay_service.dart';
import '../../../domain/models/app_config_model.dart';
import '../../widgets/garden_subject_card.dart';
import '../../widgets/student_home/mascot_hero.dart';
import '../../widgets/student_home/rank_progress_card.dart';
import '../../widgets/student_home/screen_time_ring.dart';
import '../../widgets/student_home/free_time_banner.dart';
import '../../widgets/student_home/today_stats_card.dart';
import '../../widgets/student_home/weekly_study_chart.dart';
import '../../widgets/student_home/monitored_apps_card.dart';
import 'subject_detail_screen.dart';
import '../../../../l10n/app_localizations.dart';

class StudentHome extends StatefulWidget {
  final String fullName;
  final String uid;

  const StudentHome({super.key, required this.fullName, required this.uid});

  @override
  State<StudentHome> createState() => StudentHomeState();
}

class StudentHomeState extends State<StudentHome> {
  List<AppRuleModel> _appRules = [];
  StudentConfigModel _config = const StudentConfigModel();
  bool _rulesLoading = true;
  final Map<String, String?> _iconCache = {};

  // ── Gamification / rank ────────────────────────────────────────────────────
  int _xp = 0;
  int _level = 1;
  int _streak = 0;

  // ── Daily snapshot ─────────────────────────────────────────────────────────
  Duration _studyTimeToday = Duration.zero;
  int _accuracyToday = 0;
  List<SubjectQuestionCount> _questionsBySubject = const [];

  // ── Weekly study (for the bar chart) ────────────────────────────────────────
  List<DailyStudyPoint> _weeklyStudy = const [];

  // Last known garden data — persists across BLoC state changes.
  List<GardenPlantModel> _gardenCache = [];

  final ScrollController _gardenScrollController = ScrollController();

  // ── Screen-time live refresh ───────────────────────────────────────────────
  Timer? _usageTicker;

  @override
  void initState() {
    super.initState();
    context.read<AuthBloc>().add(
      LoadStudentAppConfigRequested(studentUid: widget.uid),
    );
    // Installed-app sync is intentionally NOT dispatched here.
    // It is triggered once per login session from StudentScreen.initState(),
    // and on resume when the native dirty flag is set (package change).
    context.read<GardenBloc>().add(LoadGardenRequested(studentUid: widget.uid));
    _loadDailyData();

    _usageTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _usageTicker?.cancel();
    _gardenScrollController.dispose();
    super.dispose();
  }

  /// Loads gamification profile (xp/level/streak), today's snapshot
  /// (study time / accuracy / per-subject questions), and the weekly study
  /// series — all used by the rank card, Today card, and weekly chart.
  Future<void> _loadDailyData() async {
    try {
      final profile =
          await AiEngineRepository.instance.getGamificationProfile(widget.uid);
      if (mounted) {
        setState(() {
          _streak = (profile['current_streak'] as int?) ?? _streak;
          _xp = (profile['xp_total'] as int?) ?? _xp;
          _level = (profile['current_level'] as int?) ?? _level;
        });
      }
    } catch (e, s) {
      debugPrint('[StudentHome] _loadDailyData gamification error: $e\n$s');
    }

    try {
      final snapshot =
          await AiEngineRepository.instance.getDailySnapshot(widget.uid);
      if (mounted) {
        setState(() {
          _studyTimeToday = snapshot.totalStudyTimeToday;
          _accuracyToday = snapshot.averageAccuracyToday;
          _questionsBySubject = snapshot.questionsBySubject;
        });
      }
    } catch (e, s) {
      debugPrint('[StudentHome] _loadDailyData daily snapshot error: $e\n$s');
    }

    try {
      final habits =
          await AiEngineRepository.instance.getStudyHabitsReport(widget.uid);
      if (mounted) {
        setState(() => _weeklyStudy = habits.dailyStudy);
      }
    } catch (e, s) {
      debugPrint('[StudentHome] _loadDailyData study habits error: $e\n$s');
    }
  }

  Future<void> refresh() async {
    setState(() {
      _rulesLoading = true;
    });
    context.read<AuthBloc>().add(
      LoadStudentAppConfigRequested(studentUid: widget.uid),
    );
    context.read<GardenBloc>().add(LoadGardenRequested(studentUid: widget.uid));
    _loadDailyData();
  }

  Future<void> _loadIcons(List<AppRuleModel> rules) async {
    final missing = rules
        .map((r) => r.packageName)
        .where((pkg) => !_iconCache.containsKey(pkg))
        .toList();
    if (missing.isEmpty) return;
    final results = await Future.wait(
      missing.map((pkg) => InstalledAppsService.instance.getAppIcon(pkg)),
    );
    if (!mounted) return;
    setState(() {
      for (var i = 0; i < missing.length; i++) {
        _iconCache[missing[i]] = results[i];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final firstName = widget.fullName.split(' ').first;
    final activeRules = _appRules.where((r) => !r.isPaused).toList();
    final isResting = MascotOverlayService.instance.isBlocked;

    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is LegacyAppRulesLoaded && state.studentUid == widget.uid) {
              setState(() {
                _appRules = state.rules;
                _config = state.config;
                _rulesLoading = false;
              });
              // FIX: pass studentUid so the native service detects account
              // switches and resets timer state for the correct student.
              MascotOverlayService.instance.updateMonitoredApps(
                state.rules,
                studentUid: widget.uid,
                config: state.config,
              );
              _loadIcons(state.rules);
            }
            if (state is LegacyAppConfigError) {
              setState(() => _rulesLoading = false);
            }
          },
        ),
        BlocListener<GardenBloc, GardenState>(
          listener: (context, state) {
            if (state is GardenLoaded) {
              setState(() => _gardenCache = state.plants);
            }
          },
        ),
        BlocListener<GamificationBloc, GamificationState>(
          listener: (context, state) {
            if (state is GamificationLoaded) {
              setState(() {
                _xp = state.profile.xpTotal;
                _level = state.profile.currentLevel;
                _streak = state.profile.currentStreak;
              });
            } else if (state is GamificationRewardProcessed) {
              setState(() {
                _xp = state.profile.xpTotal;
                _level = state.profile.currentLevel;
                _streak = state.profile.currentStreak;
              });
            }
          },
        ),
      ],
      child: RefreshIndicator(
        onRefresh: refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1 ── Mascot greeting (level-based motivation) ───────────────
                MascotHero(firstName: firstName, level: _level),
                const SizedBox(height: 16),

                // 2 ── Garden (hero growth visual) ─────────────────────────────
                _buildGardenArea(),
                const SizedBox(height: 16),

                // 3 ── Rank progress ───────────────────────────────────────────
                RankProgressCard(xpTotal: _xp, currentLevel: _level),
                const SizedBox(height: 16),

                // 4 ── Screen-time ring + free-time (rules-driven) ─────────────
                if (!_rulesLoading && activeRules.isNotEmpty) ...[
                  ScreenTimeRing(config: _config),
                  const SizedBox(height: 16),
                  FreeTimeBanner(
                    dailyEarnedSeconds:
                        MascotOverlayService.instance.dailyRewardSeconds,
                    remainingSeconds:
                        MascotOverlayService.instance.remainingRewardSeconds,
                    perQuizRewardSeconds: _config.rewardPerQuizSeconds,
                    isInCooldown: MascotOverlayService.instance.isInCooldown,
                    isLocked: isResting,
                    cooldownConfigured: _config.cooldownSeconds > 0,
                  ),
                  const SizedBox(height: 16),
                ],

                // 5 ── Today's stats (questions ring + chips) ─────────────────
                TodayStatsCard(
                  questionsBySubject: _questionsBySubject,
                  studyTime: _studyTimeToday,
                  streak: _streak,
                  accuracyPercent: _accuracyToday,
                ),
                const SizedBox(height: 16),

                // 6 ── This week (study bar chart) ─────────────────────────────
                WeeklyStudyChart(points: _weeklyStudy),
                const SizedBox(height: 16),

                // 7 ── Watched apps (compact → bottom sheet) ──────────────────
                if (_rulesLoading)
                  _buildLoadingCard()
                else
                  MonitoredAppsCard(
                    rules: _appRules,
                    iconCache: _iconCache,
                    isResting: isResting,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Atmospheric garden ──────────────────────────────────────────────────────

  Widget _buildGardenArea() {
    final loc = AppLocalizations.of(context);
    return BlocBuilder<GardenBloc, GardenState>(
      builder: (context, state) {
        if ((state is GardenLoading || state is GardenInitial) &&
            _gardenCache.isEmpty) {
          return _gardenShell(
            child: const SizedBox(
              height: 180,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          );
        }
        if (state is GardenError && _gardenCache.isEmpty) {
          return _gardenShell(
            child: SizedBox(
              height: 180,
              child: Center(
                child: Text(
                  loc.gardenLoadErrorMessage,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ),
            ),
          );
        }

        // ── Empty state ──────────────────────────────────────────────────
        if (_gardenCache.isEmpty) {
          return _gardenShell(
            child: SizedBox(
              height: 180,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.eco_outlined,
                        size: 40, color: Colors.green.shade300),
                    const SizedBox(height: 10),
                    Text(
                      loc.askParentAddSubjectsMessage,
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return _gardenShell(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = constraints.maxWidth - 32;
              final cardWidth = availableWidth / 3;
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                decoration: const BoxDecoration(
                  color: Color(0xFFB8DFA0),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(12),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(4, 14, 4, 4),
                child: ScrollbarTheme(
                  data: ScrollbarThemeData(
                    thumbColor: WidgetStateProperty.all(
                      const Color(0xFF4CAF50).withValues(alpha: 0.7),
                    ),
                    trackColor: WidgetStateProperty.all(
                      const Color(0xFF2E7D32).withValues(alpha: 0.15),
                    ),
                    thickness: WidgetStateProperty.all(3),
                    radius: const Radius.circular(4),
                  ),
                  child: Scrollbar(
                    controller: _gardenScrollController,
                    thumbVisibility: _gardenCache.length > 3,
                    child: SingleChildScrollView(
                      controller: _gardenScrollController,
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: _gardenCache.map((plant) {
                          return SizedBox(
                            width: cardWidth,
                            child: GardenSubjectCard(
                              plant: plant,
                              onTap: () => _openSubjectDetail(plant),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _gardenShell({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        color: const Color(0xFFE8F5E2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 88,
              child: Stack(
                children: [
                  Positioned(
                    top: 20,
                    left: 22,
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFFFD426),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFFFFC107,
                            ).withValues(alpha: 0.40),
                            blurRadius: 14,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 22,
                    right: 28,
                    child: SizedBox(
                      width: 72,
                      height: 38,
                      child: Stack(
                        children: [
                          Positioned(
                            bottom: 0,
                            left: 0,
                            child: Container(
                              width: 68,
                              height: 22,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.92),
                                borderRadius: BorderRadius.circular(11),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 0,
                            left: 12,
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.92),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            left: 35,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.92),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _overallGardenProgress(),
                  minHeight: 5,
                  backgroundColor: const Color(0xFFB8DBA0),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF4CAF50),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              height: 10,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: const BoxDecoration(
                color: Color(0xFF7CB342),
                borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }

  /// Average mastery across subjects the student has actually started
  /// (masteryPercent > 0). Untouched subjects are excluded so a few unstarted
  /// plants don't drag the whole garden toward 0% (mirrors the backend's
  /// "practiced skills only" rule). Returns null when nothing is started yet.
  double? _avgGardenMastery() {
    final practiced = _gardenCache.where((p) => p.masteryPercent > 0);
    if (practiced.isEmpty) return null;
    return practiced.fold(0.0, (sum, p) => sum + p.masteryPercent) /
        practiced.length;
  }

  double _overallGardenProgress() {
    return ((_avgGardenMastery() ?? 0.0) / 100).clamp(0.0, 1.0);
  }

  Widget _buildLoadingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }

  void _openSubjectDetail(GardenPlantModel plant) {
    final gardenBloc = context.read<GardenBloc>();
    final gamificationBloc = context.read<GamificationBloc>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: gardenBloc),
            BlocProvider.value(value: gamificationBloc),
          ],
          child: SubjectDetailScreen(
            studentUid: widget.uid,
            subjectId: plant.subjectId,
            subjectName: plant.subjectName,
            masteryPercent: plant.masteryPercent,
          ),
        ),
      ),
    ).then((_) {
      // A quiz taken from the subject screen can change XP/mastery/garden, so
      // reload home data on return.
      if (mounted) refresh();
    });
  }
}