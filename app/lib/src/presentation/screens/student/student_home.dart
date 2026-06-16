import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
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
import '../../../services/installed_apps_service.dart';
import '../../../services/overlay/mascot_overlay_service.dart';
import '../../../domain/models/app_config_model.dart';
import '../../widgets/garden_subject_card.dart';
import '../../../utils/student_rank_utils.dart';
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

  int _streak = 0;

  int _quizzesCompletedToday = 0;
  int _accuracyToday = 0;
  int _bestStreak = 0;
  int _quizzesThisWeek = 0;


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
    _loadStreak();

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

  Future<void> _loadStreak() async {
    try {
      final profile = await AiEngineRepository.instance.getGamificationProfile(widget.uid);
      if (mounted) {
        setState(() {
          _streak = (profile['current_streak'] as int?) ?? 0;
        });
      }
    } catch (e, s) {
      debugPrint('[StudentHome] _loadStreak gamification error: $e\n$s');
    }

    try {
      final snapshot = await AiEngineRepository.instance.getDailySnapshot(widget.uid);
      if (mounted) {
        setState(() {
          _quizzesCompletedToday = snapshot.quizzesCompletedToday;
          _accuracyToday = snapshot.averageAccuracyToday;
        });
      }
    } catch (e, s) {
      debugPrint('[StudentHome] _loadStreak daily snapshot error: $e\n$s');
    }

    try {
      final weekly = await AiEngineRepository.instance.getWeeklyReport(widget.uid);
      if (mounted) {
        setState(() {
          _bestStreak = weekly.longestStreakDays;
          _quizzesThisWeek = weekly.totalQuizzes;
        });
      }
    } catch (e, s) {
      debugPrint('[StudentHome] _loadStreak weekly report error: $e\n$s');
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
    _loadStreak();
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
    final loc = AppLocalizations.of(context);
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
      ],
      child: RefreshIndicator(
        onRefresh: refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Garden area ───────────────────────────────────────────────────
              Container(
                color: const Color(0xFFF8FAF6),
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.cairo(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1F2937),
                          letterSpacing: -0.3,
                        ),
                        children: [
                          TextSpan(
                            text: loc.welcomeBackGreeting(
                              widget.fullName.split(' ').first,
                            ),
                          ),
                          const TextSpan(text: '☀️'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    BlocBuilder<GamificationBloc, GamificationState>(
                      builder: (context, state) {
                        final profile = state is GamificationLoaded
                            ? state.profile
                            : state is GamificationRewardProcessed
                                ? state.profile
                                : null;
                        final text = profile == null
                            ? 'Your garden is growing beautifully!'
                            : _gardenSubMessage(
                                profile.currentLevel,
                                StudentRankUtils.rankFromLevel(
                                  profile.currentLevel,
                                ),
                              );
                        return Text(
                          text,
                          style: GoogleFonts.roboto(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildGardenArea(),
                    const SizedBox(height: 16),
                    _buildOwlSection(),
                    const SizedBox(height: 16),
                    _buildQuickStats(),
                  ],
                ),
              ),

              // ── App rules ───────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: _buildAppRulesSection(),
              ),
            ],
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

  double _overallGardenProgress() {
    if (_gardenCache.isEmpty) return 0.0;
    final avg = _gardenCache.fold(0.0, (sum, p) => sum + p.masteryPercent) /
        _gardenCache.length;
    return (avg / 100).clamp(0.0, 1.0);
  }

  // ── Owl mascot ──────────────────────────────────────────────────────────────

  Widget _buildOwlSection() {
    final loc = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 52,
            height: 52,
            child: CustomPaint(painter: _OwlPainter()),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1FBF1),
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Text(
                    loc.owlEncouragementMessage,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  loc.owlNameLabel,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Quick stats ─────────────────────────────────────────────────────────────

  Widget _buildQuickStats() {
    final avgMastery = _gardenCache.isEmpty
        ? '—'
        : '${(_gardenCache.map((p) => p.masteryPercent).reduce((a, b) => a + b) / _gardenCache.length).round()}%';

    final cards = <Widget>[
      _statCard('📚', 'Today', '$_quizzesCompletedToday', const Color(0xFF2196F3)),
      _statCard('🔥', 'Streak', '$_streak', const Color(0xFFFF9800)),
      _statCard('🏆', 'Best', '$_bestStreak', const Color(0xFFFFB300)),
      _statCard('🎯', 'Accuracy', '$_accuracyToday%', const Color(0xFFEC4899)),
      _statCard('🌱', 'Mastery', avgMastery, const Color(0xFF4CAF50)),
      _statCard('📅', 'This week', '$_quizzesThisWeek', const Color(0xFF7C3AED)),
    ];

    // Lay the cards out 3-per-row, padding the final row so every card keeps a
    // uniform width and stays column-aligned.
    final rows = <Widget>[];
    for (var i = 0; i < cards.length; i += 3) {
      final rowCards = cards.sublist(i, math.min(i + 3, cards.length));
      final padded = <Widget>[
        ...rowCards,
        for (var j = rowCards.length; j < 3; j++) const SizedBox.shrink(),
      ];
      if (rows.isNotEmpty) rows.add(const SizedBox(height: 10));
      rows.add(Row(children: _statRow(padded)));
    }
    return Column(children: rows);
  }

  // Spaces three stat cards evenly across a row.
  List<Widget> _statRow(List<Widget> cards) {
    final children = <Widget>[];
    for (var i = 0; i < cards.length; i++) {
      children.add(Expanded(child: cards[i]));
      if (i < cards.length - 1) children.add(const SizedBox(width: 10));
    }
    return children;
  }

  Widget _statCard(String emoji, String label, String value, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.20)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.10),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: GoogleFonts.roboto(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  // ── Parent section ──────────────────────────────────────────────────────────

  // ── App rules section ───────────────────────────────────────────────────────

  Widget _buildAppRulesSection() {
    final loc = AppLocalizations.of(context);
    final activeRules = _appRules.where((r) => !r.isPaused).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Monitored apps',
              style: GoogleFonts.cairo(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(width: 8),
            if (_rulesLoading)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Rules configured by your parent.',
          style: GoogleFonts.roboto(fontSize: 12, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 14),
        if (!_rulesLoading && activeRules.isEmpty)
          _buildNoRulesPlaceholder()
        else if (!_rulesLoading) ...[
          // ── Screen-time card (always visible when rules exist) ───────────────
          _buildScreenTimeCard(),
          const SizedBox(height: 16),
          _buildAppsSummaryCard(activeRules),
        ],
      ],
    );
  }

  // ── Screen-time card ────────────────────────────────────────────────────────

  /// Reads live data from [MascotOverlayService] and renders either:
  ///   • A usage progress bar with remaining time, or
  ///   • A cooldown banner with live countdown.
  Widget _buildScreenTimeCard() {
    final svc = MascotOverlayService.instance;
    final thresholdSeconds =
        (_config.usageHours * 3600) + (_config.usageMinutes * 60);

    if (svc.isBlocked) {
      return _buildCooldownBanner(svc.remainingSeconds);
    }

    // Not blocked — show remaining usage time.
    return _buildUsageBar(
      usedSeconds: svc.totalUsageSeconds,
      totalSeconds: thresholdSeconds,
    );
  }

  Widget _buildUsageBar({required int usedSeconds, required int totalSeconds}) {
    final loc = AppLocalizations.of(context);
    if (totalSeconds <= 0) return const SizedBox.shrink();

    final remaining = (totalSeconds - usedSeconds).clamp(0, totalSeconds);
    final fraction = (usedSeconds / totalSeconds).clamp(0.0, 1.0);

    // Color shifts: green → amber → red as usage fills up.
    final Color barColor;
    if (fraction < 0.6) {
      barColor = const Color(0xFF34A853);
    } else if (fraction < 0.85) {
      barColor = const Color(0xFFFFA726);
    } else {
      barColor = const Color(0xFFEF5350);
    }

    final Color bgColor = barColor.withValues(alpha: 0.10);
    final remainingLabel = _formatDurationFromSeconds(remaining);
    final totalLabel = _formatDurationFromSeconds(totalSeconds);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.timer_outlined, size: 16, color: barColor),
              ),
              const SizedBox(width: 10),
              Text(
                loc.screenTimeLabel,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  loc.timeRemainingLabel(remainingLabel),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: barColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 8,
              backgroundColor: Colors.grey.shade100,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                loc.usedTimeLabel(_formatDurationFromSeconds(usedSeconds)),
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
              Text(
                loc.limitTimeLabel(totalLabel),
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
          ),
          if (_config.cooldownHours > 0 || _config.cooldownMinutes > 0) ...[
            const SizedBox(height: 10),
            const Divider(height: 1, color: Color(0xFFF3F4F6)),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.hourglass_bottom_rounded,
                  size: 13,
                  color: Color(0xFFFF9800),
                ),
                const SizedBox(width: 5),
                Text(
                  loc.cooldownAfterLimitLabel(_formatDuration(_config.cooldownHours, _config.cooldownMinutes)),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFFF9800),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCooldownBanner(int remainingSeconds) {
    final loc = AppLocalizations.of(context);
    final cooldownLabel = _formatDurationFromSeconds(remainingSeconds);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        // Warm amber gradient — firm but not alarming
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF3E0), Color(0xFFFFF8F0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFA726).withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFA726).withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFFA726).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_clock_outlined,
              color: Color(0xFFF57C00),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.onCooldownTitle,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFE65100),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  loc.cooldownMessage,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange.shade800,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                cooldownLabel,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFF57C00),
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                loc.remainingLabel,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.orange.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoRulesPlaceholder() {
    final loc = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.app_settings_alt_outlined,
              size: 36,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 10),
            Text(
              loc.noAppRulesSetMessage,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              loc.noAppRulesDescriptionMessage,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the motivational sub-line shown under the welcome greeting.
  /// Always names the student's rank; the tail adapts to their streak and
  /// average garden mastery so it reflects real performance.
  String _gardenSubMessage(int level, String rankName) {
    final prefix = 'Level $level · $rankName — ';
    if (_streak >= 3) {
      return '$prefix🔥 $_streak-day streak — you\'re on a roll!';
    }
    final avgMastery = _gardenCache.isEmpty
        ? null
        : _gardenCache.map((p) => p.masteryPercent).reduce((a, b) => a + b) /
            _gardenCache.length;
    if (avgMastery != null && avgMastery >= 80) {
      return '${prefix}your garden is thriving! 🌟';
    }
    if (avgMastery != null && avgMastery >= 40) {
      return '${prefix}great progress — keep growing! 🌱';
    }
    return '${prefix}let\'s grow your garden today! 🌱';
  }

  /// Summary card: a facepile of the real app icons + a count, tappable to
  /// open the full list in a bottom sheet. Scales to any number of apps.
  Widget _buildAppsSummaryCard(List<AppRuleModel> rules) {
    return GestureDetector(
      onTap: () => _showAllAppsSheet(rules),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildFacepile(rules),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${rules.length} ${rules.length == 1 ? 'app' : 'apps'} locked',
                    style: GoogleFonts.cairo(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'when your screen time runs out',
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  /// Overlapping circular app icons; shows up to 4 then a "+N" bubble.
  Widget _buildFacepile(List<AppRuleModel> rules) {
    const size = 38.0;
    const step = 24.0;
    const maxFaces = 4;
    final faces = rules.take(maxFaces).toList();
    final extra = rules.length - faces.length;
    final slots = faces.length + (extra > 0 ? 1 : 0);
    final width = slots <= 1 ? size : (slots - 1) * step + size;

    return SizedBox(
      width: width,
      height: size,
      child: Stack(
        children: [
          for (int i = 0; i < faces.length; i++)
            Positioned(left: i * step, child: _faceAvatar(faces[i], size)),
          if (extra > 0)
            Positioned(
              left: faces.length * step,
              child: Container(
                width: size,
                height: size,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFE8F5E9),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Text(
                  '+$extra',
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF2E7D32),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _faceAvatar(AppRuleModel rule, double size) {
    final b64 = _iconCache[rule.packageName];
    Widget inner;
    if (b64 != null && b64.isNotEmpty) {
      try {
        inner = Image.memory(
          base64Decode(b64),
          width: size,
          height: size,
          fit: BoxFit.cover,
        );
      } catch (_) {
        inner = _letterFace(rule.appLabel, size);
      }
    } else {
      inner = _letterFace(rule.appLabel, size);
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipOval(child: inner),
    );
  }

  Widget _letterFace(String label, double size) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      color: const Color(0xFFE8EDFF),
      child: Text(
        label.isNotEmpty ? label[0].toUpperCase() : '?',
        style: GoogleFonts.roboto(
          fontSize: size * 0.4,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF4A6CF7),
        ),
      ),
    );
  }

  /// Bottom sheet listing every monitored app (icon + name).
  void _showAllAppsSheet(List<AppRuleModel> rules) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      'Monitored apps',
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(${rules.length})',
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  itemCount: rules.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final r = rules[i];
                    return Row(
                      children: [
                        _AppIcon(
                          iconBase64: _iconCache[r.packageName],
                          label: r.appLabel,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            r.appLabel,
                            style: GoogleFonts.roboto(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1F2937),
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.lock_outline_rounded,
                          size: 16,
                          color: Color(0xFF8B93A7),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  String _formatDuration(int hours, int minutes) {
    if (hours == 0 && minutes == 0) return '0m';
    if (hours == 0) return '${minutes}m';
    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes}m';
  }

  /// Formats a raw second count into a human-readable duration string.
  /// e.g. 3725 → "1h 2m", 95 → "1m 35s", 45 → "45s"
  String _formatDurationFromSeconds(int seconds) {
    if (seconds <= 0) return '0s';
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) return m > 0 ? '${h}h ${m}m' : '${h}h';
    if (m > 0) return s > 0 ? '${m}m ${s}s' : '${m}m';
    return '${s}s';
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
    );
  }
}

// â”€â”€ Owl CustomPainter â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _OwlPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 60.0;
    canvas.scale(s);

    Paint p(Color c) => Paint()..color = c;

    canvas.drawOval(
      Rect.fromCenter(center: const Offset(30, 35), width: 40, height: 46),
      p(const Color(0xFF8D6E63)),
    );

    canvas.save();
    canvas.translate(15, 35);
    canvas.rotate(-20 * math.pi / 180);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 16, height: 30),
      p(const Color(0xFF6D4C41)),
    );
    canvas.restore();

    canvas.save();
    canvas.translate(45, 35);
    canvas.rotate(20 * math.pi / 180);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 16, height: 30),
      p(const Color(0xFF6D4C41)),
    );
    canvas.restore();

    canvas.drawCircle(const Offset(30, 22), 16, p(const Color(0xFFA1887F)));
    canvas.drawCircle(const Offset(24, 20), 6, p(Colors.white));
    canvas.drawCircle(const Offset(36, 20), 6, p(Colors.white));
    canvas.drawCircle(const Offset(25, 20), 3, p(const Color(0xFF3E2723)));
    canvas.drawCircle(const Offset(37, 20), 3, p(const Color(0xFF3E2723)));
    canvas.drawCircle(const Offset(26, 19), 1.5, p(Colors.white));
    canvas.drawCircle(const Offset(38, 19), 1.5, p(Colors.white));

    final beak = Path()
      ..moveTo(30, 24)
      ..lineTo(27, 28)
      ..lineTo(33, 28)
      ..close();
    canvas.drawPath(beak, p(const Color(0xFFFF9800)));

    final leftEar = Path()
      ..moveTo(20, 12)
      ..lineTo(18, 6)
      ..lineTo(22, 10)
      ..close();
    canvas.drawPath(leftEar, p(const Color(0xFF8D6E63)));

    final rightEar = Path()
      ..moveTo(40, 12)
      ..lineTo(42, 6)
      ..lineTo(38, 10)
      ..close();
    canvas.drawPath(rightEar, p(const Color(0xFF8D6E63)));

    canvas.drawOval(
      Rect.fromCenter(center: const Offset(30, 38), width: 24, height: 28),
      p(const Color(0xFFBCAAA4)),
    );
  }

  @override
  bool shouldRepaint(_OwlPainter old) => false;
}

// â”€â”€ App icon widget â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _AppIcon extends StatelessWidget {
  final String? iconBase64;
  final String label;

  const _AppIcon({required this.iconBase64, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF6DBF5E), width: 2),
      ),
      child: _buildAvatar(),
    );
  }

  Widget _buildAvatar() {
    if (iconBase64 != null && iconBase64!.isNotEmpty) {
      try {
        return CircleAvatar(
          backgroundImage: MemoryImage(base64Decode(iconBase64!)),
          backgroundColor: const Color(0xFFE8EDFF),
          radius: 19,
        );
      } catch (_) {}
    }
    return CircleAvatar(
      radius: 19,
      backgroundColor: const Color(0xFFE8EDFF),
      child: Text(
        label[0].toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF4A6CF7),
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
    );
  }
}

