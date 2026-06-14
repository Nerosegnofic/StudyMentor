import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/reports/reports_bloc.dart';
import '../../../bloc/reports/reports_event.dart';
import '../../../bloc/reports/reports_state.dart';
import '../../../domain/models/report_models.dart';
import '../../../domain/models/student_model.dart';

// ── Design Tokens ─────────────────────────────────────────────────────────────
const _kPrimary = Color(0xFF2196F3);
const _kAmber = Color(0xFFFFC107);
const _kTeal = Color(0xFF00897B);
const _kRed = Color(0xFFE53935);
const _kCanvas = Color(0xFFF5F7FA);
const _kWhite = Color(0xFFFFFFFF);
const _kDarkText = Color(0xFF1E293B);
const _kSubText = Color(0xFF64748B);

class ReportsAnalysisScreen extends StatefulWidget {
  final StudentModel student;

  const ReportsAnalysisScreen({super.key, required this.student});

  @override
  State<ReportsAnalysisScreen> createState() => _ReportsAnalysisScreenState();
}

class _ReportsAnalysisScreenState extends State<ReportsAnalysisScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedSubject = 'Mathematics';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    context.read<ReportsBloc>().add(
      LoadWeeklyReportRequested(studentUid: widget.student.uid),
    );
    context.read<ReportsBloc>().add(
      LoadSubjectMasteryRequested(
        studentUid: widget.student.uid,
        subjectKey: 'math',
      ),
    ); // Mock key
    context.read<ReportsBloc>().add(
      LoadStudyHabitsRequested(studentUid: widget.student.uid),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kCanvas,
      body: Column(
        children: [
          _buildStickyHeader(context),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildSubjectMasteryTab(),
                _buildTimeHabitsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyHeader(BuildContext context) {
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
              InkWell(
                onTap: () => Navigator.of(context).pop(),
                borderRadius: BorderRadius.circular(24),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  "Reports & Analysis",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 28), // balance
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: _kWhite,
      child: TabBar(
        controller: _tabController,
        labelColor: _kPrimary,
        unselectedLabelColor: _kSubText,
        indicatorColor: _kPrimary,
        labelStyle: GoogleFonts.roboto(fontWeight: FontWeight.bold),
        unselectedLabelStyle: GoogleFonts.roboto(fontWeight: FontWeight.normal),
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Mastery'),
          Tab(text: 'Habits'),
        ],
      ),
    );
  }

  // ── Overview Tab ────────────────────────────────────────────────────────────

  Widget _buildOverviewTab() {
    return BlocBuilder<ReportsBloc, ReportsState>(
      builder: (context, state) {
        if (state.isWeeklyLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.weeklyError != null) {
          return Center(
            child: Text(
              state.weeklyError!,
              style: const TextStyle(color: Colors.red),
            ),
          );
        }
        final report = state.weeklyReport;
        if (report == null) {
          return const Center(child: Text('No report available.'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Metrics Row
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      "Accuracy",
                      "${report.overallAccuracyPercent.toInt()}%",
                      _kTeal,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      "Quizzes",
                      "${report.totalQuizzes}",
                      _kPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      "Study Time",
                      "${report.totalStudyTime.inHours}h ${report.totalStudyTime.inMinutes.remainder(60)}m",
                      _kAmber,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Accuracy Trend Chart
              Container(
                padding: const EdgeInsets.all(20),
                decoration: _cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Accuracy Trend",
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _kDarkText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Weekly accuracy over the past 6 weeks",
                      style: GoogleFonts.roboto(fontSize: 12, color: _kSubText),
                    ),
                    const SizedBox(height: 20),
                    if (report.accuracyTrend.length >= 2) ...[
                      SizedBox(
                        height: 140,
                        width: double.infinity,
                        child: CustomPaint(
                          painter: _AccuracyTrendPainter(report.accuracyTrend),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: report.accuracyTrend
                            .map((point) => _chartLabel(point.weekLabel))
                            .toList(),
                      ),
                    ] else
                      SizedBox(
                        height: 100,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.show_chart_rounded,
                                  size: 36, color: _kSubText.withValues(alpha: 0.4)),
                              const SizedBox(height: 8),
                              Text(
                                "Not enough data yet",
                                style: GoogleFonts.roboto(
                                  fontSize: 13,
                                  color: _kSubText,
                                ),
                              ),
                              Text(
                                "Complete quizzes over multiple weeks to see a trend",
                                style: GoogleFonts.roboto(
                                  fontSize: 11,
                                  color: _kSubText.withValues(alpha: 0.7),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Streak Progress Card
              _buildStreakCard(report),
              const SizedBox(height: 16),

              // Smart Insights (auto-generated)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: _cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: _kPrimary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.lightbulb_rounded,
                              color: _kPrimary, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "Smart Insights",
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _kDarkText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _generateInsight(report),
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        height: 1.6,
                        color: _kSubText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStreakCard(WeeklyReportModel report) {
    final current = report.currentStreakDays;
    final best = report.longestStreakDays;
    final fraction = best > 0 ? (current / best).clamp(0.0, 1.0) : 0.0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Streak Progress",
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _kDarkText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Current streak vs. personal best",
            style: GoogleFonts.roboto(fontSize: 12, color: _kSubText),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _streakStat(Icons.local_fire_department_rounded, _kAmber,
                  '$current', 'Current streak', 'days'),
              const SizedBox(width: 12),
              Expanded(child: Container(height: 1, color: const Color(0xFFE2E8F0))),
              const SizedBox(width: 12),
              _streakStat(Icons.emoji_events_rounded, _kTeal,
                  '$best', 'Personal best', 'days'),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            best > 0
                ? '${(fraction * 100).toInt()}% of personal best'
                : 'No streak yet — start studying to build one!',
            style: GoogleFonts.roboto(
              fontSize: 12,
              color: _kSubText,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 8,
              backgroundColor: const Color(0xFFE2E8F0),
              color: current >= best && best > 0 ? _kTeal : _kAmber,
            ),
          ),
        ],
      ),
    );
  }

  Widget _streakStat(
      IconData icon, Color color, String value, String label, String unit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 6),
            Text(
              value,
              style: GoogleFonts.roboto(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: _kDarkText,
                height: 1,
              ),
            ),
            const SizedBox(width: 3),
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(
                unit,
                style: GoogleFonts.roboto(fontSize: 12, color: _kSubText),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.roboto(fontSize: 12, color: _kSubText),
        ),
      ],
    );
  }

  String _generateInsight(WeeklyReportModel report) {
    final q = report.totalQuizzes;
    final acc = report.overallAccuracyPercent.toInt();
    final streak = report.currentStreakDays;

    if (q == 0) {
      return 'No quizzes completed this week yet. Encourage your student to log in and start a session to keep their streak alive!';
    }
    if (acc >= 85 && q >= 5) {
      return '$q quizzes completed this week with $acc% accuracy — an outstanding performance! The student is mastering the material at a high level. Keep the momentum going.';
    }
    if (acc >= 70 && q >= 3) {
      return 'Good week overall: $q quizzes at $acc% accuracy. To push higher, visit the Mastery tab and focus on skills rated below 60%.';
    }
    if (acc >= 55) {
      return '$q quizzes completed with $acc% accuracy. There is room to improve — check the Mastery tab to identify specific concept gaps that need attention.';
    }
    if (streak >= 3) {
      return 'The student has kept a $streak-day streak, which is great for consistency! Accuracy is at $acc% — reviewing weaker topics between sessions should help raise scores.';
    }
    return 'Accuracy was $acc% across $q quizzes this week. Encourage shorter, more focused study sessions and review any topics marked as weak in the Mastery tab.';
  }

  Widget _buildMetricCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.roboto(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.roboto(fontSize: 12, color: _kSubText),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Subject Mastery Tab ─────────────────────────────────────────────────────

  Widget _buildSubjectMasteryTab() {
    final subjects = ['math', 'science', 'english', 'history']; // Use keys

    return BlocBuilder<ReportsBloc, ReportsState>(
      builder: (context, state) {
        if (state.isMasteryLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.masteryError != null) {
          return Center(
            child: Text(
              state.masteryError!,
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final report = state.masteryReport;
        if (report == null) {
          return const Center(child: Text('No mastery report available.'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Total Mastery Card
              _buildTotalMasteryCard(
                report.totalMasteryPercent,
                report.masteryLabel,
              ),
              const SizedBox(height: 16),

              // Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: subjects.map((sub) {
                    final isSelected = sub == _selectedSubject;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(sub.toUpperCase()),
                        selected: isSelected,
                        selectedColor: _kPrimary,
                        labelStyle: GoogleFonts.roboto(
                          color: isSelected ? Colors.white : _kDarkText,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        onSelected: (val) {
                          if (val && _selectedSubject != sub) {
                            setState(() => _selectedSubject = sub);
                            context.read<ReportsBloc>().add(
                              LoadSubjectMasteryRequested(
                                studentUid: widget.student.uid,
                                subjectKey: sub,
                              ),
                            );
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),

              // Mastery Circle
              Center(
                child: SizedBox(
                  width: 160,
                  height: 160,
                  child: CustomPaint(
                    painter: _MasteryCirclePainter(
                      percentage: report.totalMasteryPercent / 100.0,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "${report.totalMasteryPercent.toInt()}%",
                            style: GoogleFonts.roboto(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: _kPrimary,
                            ),
                          ),
                          Text(
                            "Mastered",
                            style: GoogleFonts.roboto(
                              fontSize: 14,
                              color: _kSubText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Actionable Areas
              Text(
                "🔥 Strong Areas",
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _kDarkText,
                ),
              ),
              const SizedBox(height: 12),
              if (report.strongSkills.isNotEmpty) ...[
                ...report.strongSkills
                    .map(
                      (skill) => _buildSkillRow(
                        skill.skillKey,
                        skill.masteryPercent.toInt(),
                        isStrong: true,
                      ),
                    )
                    .toList(),
              ] else ...[
                Text(
                  "No strong areas identified yet.",
                  style: GoogleFonts.roboto(color: _kSubText),
                ),
              ],

              const SizedBox(height: 24),
              Text(
                "⚠️ Needs Work",
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _kDarkText,
                ),
              ),
              const SizedBox(height: 12),
              if (report.weakSkills.isNotEmpty) ...[
                ...report.weakSkills
                    .map(
                      (skill) => _buildSkillRow(
                        skill.skillKey,
                        skill.masteryPercent.toInt(),
                        isNeedsWork: true,
                      ),
                    )
                    .toList(),
              ] else ...[
                Text(
                  "No weak areas identified yet.",
                  style: GoogleFonts.roboto(color: _kSubText),
                ),
              ],

              const SizedBox(height: 24),
              // Error Analytics
              _buildErrorAnalyticsCard(report.errorAnalytics),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTotalMasteryCard(double percent, String label) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_kPrimary.withOpacity(0.08), _kTeal.withOpacity(0.04)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kPrimary.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _kPrimary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.school_rounded, color: _kPrimary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Total Average Mastery",
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _kSubText,
                    height: 1.2,
                  ),
                ),
                Text(
                  "${percent.toStringAsFixed(1)}% Mastery Score",
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _kDarkText,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _kTeal,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              label,
              style: GoogleFonts.roboto(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorAnalyticsCard(ErrorAnalyticModel analytics) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_rounded, color: _kRed, size: 22),
              const SizedBox(width: 8),
              Text(
                "Error Analytics",
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _kDarkText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            "Common mistake types on $_selectedSubject quizzes.",
            style: GoogleFonts.roboto(fontSize: 12, color: _kSubText),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 14,
            width: double.infinity,
            child: CustomPaint(painter: _ErrorAnalyticsPainter(analytics)),
          ),
          const SizedBox(height: 20),
          _errorDetailItem(
            _kRed.withOpacity(0.8),
            "Careless Mistakes (${analytics.carelessPercent.toInt()}%)",
            "Answering too quickly on calculations",
          ),
          const SizedBox(height: 10),
          _errorDetailItem(
            _kAmber,
            "Concept Gaps (${analytics.conceptGapPercent.toInt()}%)",
            "Struggles with newly introduced topics",
          ),
          const SizedBox(height: 10),
          _errorDetailItem(
            _kPrimary,
            "Time Pressure (${analytics.timePressurePercent.toInt()}%)",
            "Failing to finish within the quiz timer",
          ),
        ],
      ),
    );
  }

  Widget _errorDetailItem(Color color, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 4),
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.roboto(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: _kDarkText,
                  height: 1.2,
                ),
              ),
              Text(
                description,
                style: GoogleFonts.roboto(
                  fontSize: 11,
                  color: _kSubText,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSkillRow(
    String name,
    int score, {
    bool isStrong = false,
    bool isNeedsWork = false,
  }) {
    final bool failed = score < 50;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _kDarkText,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  textDirection: TextDirection.rtl,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "$score%",
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: failed ? _kRed : _kDarkText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Stack(
            children: [
              Container(
                width: double.infinity,
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: score / 100,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: failed ? _kRed : _kPrimary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Time & Habits Tab ───────────────────────────────────────────────────────

  Widget _buildTimeHabitsTab() {
    return BlocBuilder<ReportsBloc, ReportsState>(
      builder: (context, state) {
        if (state.isHabitsLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.habitsError != null) {
          return Center(
            child: Text(
              state.habitsError!,
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final report = state.habitsReport;
        if (report == null) {
          return const Center(child: Text('No habits report available.'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Streak
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: _cardDecoration(),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.local_fire_department_rounded,
                            color: _kAmber,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Current Streak",
                                style: GoogleFonts.roboto(
                                  fontSize: 12,
                                  color: _kSubText,
                                ),
                              ),
                              Text(
                                "${report.currentStreakDays} Days",
                                style: GoogleFonts.roboto(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _kDarkText,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: _cardDecoration(),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.emoji_events_rounded,
                            color: _kTeal,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Longest Streak",
                                style: GoogleFonts.roboto(
                                  fontSize: 12,
                                  color: _kSubText,
                                ),
                              ),
                              Text(
                                "${report.longestStreakDays} Days",
                                style: GoogleFonts.roboto(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _kDarkText,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Study Consistency Grid (Heatmap)
              _buildHeatmapCard(report),
              const SizedBox(height: 16),

              // Correlation Chart
              Container(
                padding: const EdgeInsets.all(20),
                decoration: _cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Study vs Monitored App Usage",
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _kDarkText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Compare active learning time vs time blocked on other apps.",
                      style: GoogleFonts.roboto(fontSize: 12, color: _kSubText),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 180,
                      width: double.infinity,
                      child: CustomPaint(
                        painter: _CorrelationChartPainter(report.correlation),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _legendItem("Study Time", _kPrimary),
                        const SizedBox(width: 24),
                        _legendItem("App Usage", _kRed.withOpacity(0.6)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: report.correlation
                          .map((c) => _chartLabel(c.dayLabel))
                          .toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeatmapCard(StudyHabitsReport report) {
    // Map HeatmapDay objects into an array of 28 ints for the painter
    final studyMinutes = report.consistencyHeatmap
        .map((d) => d.studyMinutes)
        .toList();
    // Ensure we have exactly 28, pad with 0 if needed (just in case)
    while (studyMinutes.length < 28) {
      studyMinutes.add(0);
    }
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Study Consistency Grid",
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _kDarkText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Active study days over the last 4 weeks.",
            style: GoogleFonts.roboto(fontSize: 12, color: _kSubText),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 18),
                  _heatmapWeekLabel("3w ago"),
                  _heatmapWeekLabel("2w ago"),
                  _heatmapWeekLabel("1w ago"),
                  _heatmapWeekLabel("This wk"),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _heatmapDayLabel("M"),
                          _heatmapDayLabel("T"),
                          _heatmapDayLabel("W"),
                          _heatmapDayLabel("T"),
                          _heatmapDayLabel("F"),
                          _heatmapDayLabel("S"),
                          _heatmapDayLabel("S"),
                        ],
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: 184,
                        height: 103,
                        child: CustomPaint(
                          painter: _ActivityHeatmapPainter(
                            studyMinutes: studyMinutes,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                "Less",
                style: GoogleFonts.roboto(fontSize: 10, color: _kSubText),
              ),
              const SizedBox(width: 6),
              _heatmapLegendBox(0),
              const SizedBox(width: 3),
              _heatmapLegendBox(20),
              const SizedBox(width: 3),
              _heatmapLegendBox(50),
              const SizedBox(width: 3),
              _heatmapLegendBox(80),
              const SizedBox(width: 3),
              _heatmapLegendBox(100),
              const SizedBox(width: 6),
              Text(
                "More",
                style: GoogleFonts.roboto(fontSize: 10, color: _kSubText),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heatmapWeekLabel(String text) {
    return SizedBox(
      height: 26,
      child: Center(
        child: Text(
          text,
          style: GoogleFonts.roboto(
            fontSize: 10,
            color: _kSubText,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _heatmapDayLabel(String text) {
    return SizedBox(
      width: 26,
      child: Center(
        child: Text(
          text,
          style: GoogleFonts.roboto(
            fontSize: 10,
            color: _kSubText,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _heatmapLegendBox(int minutes) {
    Color color;
    if (minutes == 0) {
      color = const Color(0xFFE2E8F0);
    } else if (minutes < 30) {
      color = _kPrimary.withOpacity(0.25);
    } else if (minutes < 60) {
      color = _kPrimary.withOpacity(0.5);
    } else if (minutes < 90) {
      color = _kPrimary.withOpacity(0.75);
    } else {
      color = _kPrimary;
    }
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  Widget _legendItem(String text, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(text, style: GoogleFonts.roboto(fontSize: 12, color: _kSubText)),
      ],
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: _kWhite,
      borderRadius: BorderRadius.circular(16),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0A000000),
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ],
    );
  }

  Widget _chartLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.roboto(fontSize: 10, color: _kSubText),
    );
  }
}

// ── Custom Painters ───────────────────────────────────────────────────────────

class _AccuracyTrendPainter extends CustomPainter {
  final List<WeeklyAccuracyPoint> data;
  _AccuracyTrendPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final points = data.map((d) => d.accuracy / 100.0).toList();
    if (points.length < 2) return;

    final paintLine = Paint()
      ..color = _kPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final paintFill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_kPrimary.withOpacity(0.3), _kPrimary.withOpacity(0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path();
    final stepX = size.width / (points.length - 1);

    for (int i = 0; i < points.length; i++) {
      final x = i * stepX;
      final y = size.height - (points[i] * size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        final prevX = (i - 1) * stepX;
        final prevY = size.height - (points[i - 1] * size.height);
        final controlX1 = prevX + stepX / 2;
        final controlY1 = prevY;
        final controlX2 = x - stepX / 2;
        final controlY2 = y;
        path.cubicTo(controlX1, controlY1, controlX2, controlY2, x, y);
      }
    }

    canvas.drawPath(path, paintLine);

    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, paintFill);

    final dotPaint = Paint()..color = _kWhite;
    final dotStroke = Paint()
      ..color = _kPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (int i = 0; i < points.length; i++) {
      final x = i * stepX;
      final y = size.height - (points[i] * size.height);
      canvas.drawCircle(Offset(x, y), 4, dotPaint);
      canvas.drawCircle(Offset(x, y), 4, dotStroke);
    }
  }

  @override
  bool shouldRepaint(covariant _AccuracyTrendPainter oldDelegate) {
    return oldDelegate.data != data;
  }
}

class _MasteryCirclePainter extends CustomPainter {
  final double percentage;
  _MasteryCirclePainter({required this.percentage});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 10;

    final bgPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    final fgPaint = Paint()
      ..color = _kPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    final sweepAngle = 2 * math.pi * percentage;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _MasteryCirclePainter oldDelegate) {
    return oldDelegate.percentage != percentage;
  }
}

class _ErrorAnalyticsPainter extends CustomPainter {
  final ErrorAnalyticModel data;
  _ErrorAnalyticsPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final r = h / 2;

    final bgPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, h),
        Radius.circular(r),
      ),
      bgPaint,
    );

    final paint1 = Paint()..color = _kRed.withOpacity(0.8);
    final paint2 = Paint()..color = _kAmber;
    final paint3 = Paint()..color = _kPrimary;

    final w1 = size.width * (data.carelessPercent / 100.0);
    final w2 = size.width * (data.conceptGapPercent / 100.0);
    final w3 = size.width * (data.timePressurePercent / 100.0);

    final clipRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, h),
      Radius.circular(r),
    );
    canvas.save();
    canvas.clipRRect(clipRRect);

    canvas.drawRect(Rect.fromLTWH(0, 0, w1, h), paint1);
    canvas.drawRect(Rect.fromLTWH(w1, 0, w2, h), paint2);
    canvas.drawRect(Rect.fromLTWH(w1 + w2, 0, w3, h), paint3);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ErrorAnalyticsPainter oldDelegate) {
    return oldDelegate.data != data;
  }
}

class _ActivityHeatmapPainter extends CustomPainter {
  final List<int> studyMinutes;
  _ActivityHeatmapPainter({required this.studyMinutes});

  @override
  void paint(Canvas canvas, Size size) {
    const double boxSize = 22.0;
    const double spacing = 4.0;

    final paint = Paint()..style = PaintingStyle.fill;

    for (int week = 0; week < 4; week++) {
      for (int day = 0; day < 7; day++) {
        final index = week * 7 + day;
        final minutes = studyMinutes[index];

        if (minutes == 0) {
          paint.color = const Color(0xFFE2E8F0);
        } else if (minutes < 30) {
          paint.color = _kPrimary.withOpacity(0.25);
        } else if (minutes < 60) {
          paint.color = _kPrimary.withOpacity(0.5);
        } else if (minutes < 90) {
          paint.color = _kPrimary.withOpacity(0.75);
        } else {
          paint.color = _kPrimary;
        }

        final x = day * (boxSize + spacing);
        final y = week * (boxSize + spacing);

        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, boxSize, boxSize),
            const Radius.circular(4),
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ActivityHeatmapPainter oldDelegate) {
    return oldDelegate.studyMinutes != studyMinutes;
  }
}

class _CorrelationChartPainter extends CustomPainter {
  final List<StudyVsAppCorrelationPoint> data;
  _CorrelationChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final studyMins = data.map((e) => e.studyMinutes).toList();
    final appMins = data.map((e) => e.appUsageMinutes).toList();

    final maxVal = 200.0;

    final barWidth = 12.0;
    final stepX = size.width / 7;

    final studyPaint = Paint()
      ..color = _kPrimary
      ..style = PaintingStyle.fill;

    final appPaint = Paint()
      ..color = _kRed.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 7; i++) {
      final centerX = (i * stepX) + (stepX / 2);

      final studyH = (studyMins[i] / maxVal) * size.height;
      final studyRect = Rect.fromLTWH(
        centerX - barWidth - 2,
        size.height - studyH,
        barWidth,
        studyH,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(studyRect, const Radius.circular(4)),
        studyPaint,
      );

      final appH = (appMins[i] / maxVal) * size.height;
      final appRect = Rect.fromLTWH(
        centerX + 2,
        size.height - appH,
        barWidth,
        appH,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(appRect, const Radius.circular(4)),
        appPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CorrelationChartPainter oldDelegate) {
    return oldDelegate.data != data;
  }
}
