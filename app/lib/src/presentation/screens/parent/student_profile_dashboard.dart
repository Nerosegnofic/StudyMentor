// lib/src/presentation/screens/parent/student_profile_dashboard.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../bloc/auth/auth_bloc.dart';
import '../../../bloc/snapshot/snapshot_bloc.dart';
import '../../../bloc/snapshot/snapshot_event.dart';
import '../../../bloc/snapshot/snapshot_state.dart';
import '../../../bloc/reports/reports_bloc.dart';
import '../../../bloc/reports/reports_event.dart';
import '../../../bloc/reports/reports_state.dart';
import '../../../domain/models/student_model.dart';
import '../../../data/repositories/ai_engine_repository.dart';
import 'student_config_screen.dart';
import 'subjects_skills_screen.dart';
import 'reports_analysis_screen.dart';

// ── Design Tokens ─────────────────────────────────────────────────────────────
const _kPrimary = Color(0xFF2196F3);
const _kAmber = Color(0xFFFFC107);
const _kAmberBg = Color(0xFFFFF8E1);
const _kIconBg = Color(0xFFE3F2FD);
const _kCanvas = Color(0xFFF5F7FA);
const _kWhite = Color(0xFFFFFFFF);
const _kDarkText = Color(0xFF1E293B);
const _kSubText = Color(0xFF64748B);
const _kChevron = Color(0xFFCBD5E1);

class StudentProfileDashboard extends StatefulWidget {
  final StudentModel student;

  const StudentProfileDashboard({super.key, required this.student});

  @override
  State<StudentProfileDashboard> createState() =>
      _StudentProfileDashboardState();
}

class _StudentProfileDashboardState extends State<StudentProfileDashboard> {
  late StudentModel _student;

  String get _firstName => _student.fullName.split(' ').first;
  String get _initial => _student.fullName.isNotEmpty
      ? _student.fullName[0].toUpperCase()
      : '?';

  int _xp = 0;
  int _coins = 0;
  int _streak = 0;
  bool _loadingGamification = true;

  @override
  void initState() {
    super.initState();
    _student = widget.student;
    // Load daily snapshot (quizzes today, study time, accuracy)
    context.read<SnapshotBloc>().add(
          LoadDailySnapshotRequested(studentUid: _student.uid),
        );
    // Load weekly report (accuracy trend, streak)
    context.read<ReportsBloc>().add(
          LoadWeeklyReportRequested(studentUid: _student.uid),
        );

    _loadGamification();
  }

  Future<void> _loadGamification() async {
    try {
      final profile = await AiEngineRepository.instance.getGamificationProfile(widget.student.uid);
      if (mounted) {
        setState(() {
          _xp = (profile['xp_total'] as int?) ?? 0;
          _coins = (profile['coins_total'] as int?) ?? 0;
          _streak = (profile['current_streak'] as int?) ?? 0;
          _loadingGamification = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingGamification = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kCanvas,
      body: Column(
        children: [
          // ── Sticky Branded Header ─────────────────────────────────────────
          _StickyHeader(name: _firstName),

          // ── Scrollable Body ───────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // 1 — Hero Profile Card
                  _HeroProfileCard(
                    student: _student,
                    initial: _initial,
                    xp: _xp,
                    coins: _coins,
                    streak: _streak,
                  ),
                  const SizedBox(height: 16),

                  // 2 — Quick Stats 2x2 Grid (BLoC-driven)
                  _QuickStatsGrid(student: _student),
                  const SizedBox(height: 16),

                  // 3 — Navigation List
                  _NavigationList(
                    student: _student,
                    onStudentUpdated: (updated) => setState(() => _student = updated),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sticky Header ─────────────────────────────────────────────────────────────

class _StickyHeader extends StatelessWidget {
  final String name;
  const _StickyHeader({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: _kPrimary,
        boxShadow: [
          BoxShadow(
            color: Color(0x1A2196F3),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Back button
              InkWell(
                onTap: () => Navigator.of(context).pop(),
                borderRadius: BorderRadius.circular(24),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
              // Center: student name
              Expanded(
                child: Text(
                  "$name's Profile",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Right spacer — same width as back button for balance
              const SizedBox(width: 28),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Hero Profile Card ─────────────────────────────────────────────────────────

class _HeroProfileCard extends StatelessWidget {
  final StudentModel student;
  final String initial;
  final int xp;
  final int coins;
  final int streak;
  
  const _HeroProfileCard({
    required this.student,
    required this.initial,
    required this.xp,
    required this.coins,
    required this.streak,
  });

  String get _gradeLabel {
    final g = student.gradeLevel;
    if (g == null) return 'Grade —';
    return 'Grade $g';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar
          CircleAvatar(
            radius: 32,
            backgroundColor: _kPrimary,
            child: Text(
              initial,
              style: GoogleFonts.cairo(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Name
          Text(
            student.fullName,
            style: GoogleFonts.cairo(
              color: _kDarkText,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Gamification Pill Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _GamPill(icon: '⚡', value: '$xp'),
              const SizedBox(width: 12),
              _GamPill(icon: '🔥', value: '$streak'),
              const SizedBox(width: 12),
              _GamPill(icon: '🪙', value: '$coins'),
            ],
          ),
          const SizedBox(height: 14),

          // Grade Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            decoration: BoxDecoration(
              color: _kPrimary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _gradeLabel,
              style: GoogleFonts.roboto(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GamPill extends StatelessWidget {
  final String icon;
  final String value;
  const _GamPill({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _kAmberBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 5),
          Text(
            value,
            style: GoogleFonts.roboto(
              color: _kAmber,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quick Stats Grid ──────────────────────────────────────────────────────────
// Reads from SnapshotBloc (quizzes today, study time) and ReportsBloc
// (weekly accuracy %, active streak days). Shows a small spinner while loading
// and a dash '—' on error/no data.

class _QuickStatsGrid extends StatelessWidget {
  final StudentModel student;
  const _QuickStatsGrid({required this.student});

  // Format a Duration as "Xh Ym" or "Xm" when under an hour.
  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SnapshotBloc, SnapshotState>(
      builder: (context, snapState) {
        return BlocBuilder<ReportsBloc, ReportsState>(
          builder: (context, reportsState) {
            // ── resolve values ──────────────────────────────────────────────
            final isSnapLoading = snapState is SnapshotLoading ||
                snapState is SnapshotInitial;
            final snap = snapState is SnapshotLoaded ? snapState.snapshot : null;

            final isReportLoading = reportsState.isWeeklyLoading ||
                reportsState.weeklyReport == null;
            final report = reportsState.weeklyReport;

            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.quiz_outlined,
                        iconColor: _kPrimary,
                        value: isSnapLoading
                            ? null
                            : snap != null
                                ? '${snap.quizzesCompletedToday}'
                                : '—',
                        label: 'Quizzes Today',
                        isLoading: isSnapLoading,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.access_time_rounded,
                        iconColor: _kPrimary,
                        value: isSnapLoading
                            ? null
                            : snap != null
                                ? _formatDuration(snap.totalStudyTimeToday)
                                : '—',
                        label: 'Study Time Today',
                        isLoading: isSnapLoading,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.track_changes_rounded,
                        iconColor: _kPrimary,
                        value: isReportLoading
                            ? null
                            : report != null
                                ? '${report.overallAccuracyPercent.toInt()}%'
                                : '—',
                        label: 'Weekly Accuracy',
                        isLoading: isReportLoading,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.local_fire_department_rounded,
                        iconColor: _kAmber,
                        value: isReportLoading
                            ? null
                            : report != null
                                ? '${report.currentStreakDays} days'
                                : '—',
                        label: 'Active Streak',
                        isLoading: isReportLoading,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  /// Null means still loading — shows a spinner. '—' means loaded but no data.
  final String? value;
  final String label;
  final bool isLoading;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 10),
          if (isLoading)
            const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Text(
              value ?? '—',
              style: GoogleFonts.roboto(
                color: _kDarkText,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.roboto(
              color: _kSubText,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Navigation List ───────────────────────────────────────────────────────────

class _NavigationList extends StatelessWidget {
  final StudentModel student;
  final void Function(StudentModel) onStudentUpdated;
  const _NavigationList({required this.student, required this.onStudentUpdated});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _NavRow(
          icon: Icons.menu_book_rounded,
          title: 'Subjects & Skills',
          subtitle: 'Manage subjects and view skill progress',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SubjectsSkillsScreen(student: student),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _NavRow(
          icon: Icons.bar_chart_rounded,
          title: 'Reports & Analytics',
          subtitle: 'Weekly reports, accuracy trends, weak topics',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ReportsAnalysisScreen(student: student),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _NavRow(
          icon: Icons.settings_rounded,
          title: 'App Configurations',
          subtitle: 'Gateway timers, monitored apps, quiz rules',
          onTap: () async {
            final updated = await Navigator.push<StudentModel>(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: context.read<AuthBloc>(),
                  child: StudentConfigScreen(student: student),
                ),
              ),
            );
            if (updated != null && context.mounted) {
              onStudentUpdated(updated);
            }
          },
        ),
      ],
    );
  }
}

class _NavRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _NavRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kWhite,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon block
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _kIconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: _kPrimary, size: 24),
              ),
              const SizedBox(width: 16),

              // Text block
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.roboto(
                        color: _kDarkText,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: GoogleFonts.roboto(
                        color: _kSubText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Chevron
              const Icon(Icons.chevron_right_rounded,
                  color: _kChevron, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
