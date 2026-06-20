import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/reports/reports_bloc.dart';
import '../../../bloc/reports/reports_event.dart';
import '../../../bloc/reports/reports_state.dart';
import '../../../domain/models/report_models.dart';
import '../../../domain/models/student_model.dart';
import '../../../../l10n/app_localizations.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    context.read<ReportsBloc>().add(
      LoadWeeklyReportRequested(studentUid: widget.student.uid),
    );
    context.read<ReportsBloc>().add(
      LoadReportSubjectsRequested(studentUid: widget.student.uid),
    );
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
                  AppLocalizations.of(context).reportsAnalysisTitle,
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
    final loc = AppLocalizations.of(context);
    return Container(
      color: _kWhite,
      child: TabBar(
        controller: _tabController,
        labelColor: _kPrimary,
        unselectedLabelColor: _kSubText,
        indicatorColor: _kPrimary,
        labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        unselectedLabelStyle: GoogleFonts.cairo(fontWeight: FontWeight.normal),
        tabs: [
          Tab(text: loc.tabOverview),
          Tab(text: loc.tabMastery),
          Tab(text: loc.tabHabits),
        ],
      ),
    );
  }

  // ── Overview Tab ────────────────────────────────────────────────────────────

  Widget _buildOverviewTab() {
    final loc = AppLocalizations.of(context);
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
          return Center(child: Text(loc.noReportAvailableMessage));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Needs Attention alerts
              if (report.alerts.isNotEmpty) ...[
                _buildAlertsCard(report.alerts),
                const SizedBox(height: 16),
              ],

              // Metrics Row — IntrinsicHeight keeps all three cards the same
              // height even when a metric has no delta (shorter content).
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                  Expanded(
                    child: _buildMetricCard(
                      loc.accuracyLabel,
                      "${report.overallAccuracyPercent.toInt()}%",
                      _kTeal,
                      delta: (report.accuracyDelta != null &&
                              report.accuracyDelta != 0)
                          ? "${report.accuracyDelta! > 0 ? '+' : ''}${report.accuracyDelta!.toStringAsFixed(0)}%"
                          : null,
                      deltaUp: (report.accuracyDelta ?? 0) >= 0,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      loc.metricQuizzesLabel,
                      "${report.totalQuizzes}",
                      _kPrimary,
                      delta: report.quizzesDelta != 0
                          ? "${report.quizzesDelta > 0 ? '+' : ''}${report.quizzesDelta}"
                          : null,
                      deltaUp: report.quizzesDelta >= 0,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      loc.studyTimeLabel,
                      "${report.totalStudyTime.inHours}h ${report.totalStudyTime.inMinutes.remainder(60)}m",
                      _kAmber,
                      delta: report.studyMinutesDelta != 0
                          ? "${report.studyMinutesDelta > 0 ? '+' : ''}${report.studyMinutesDelta}m"
                          : null,
                      deltaUp: report.studyMinutesDelta >= 0,
                    ),
                  ),
                  ],
                ),
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
                      loc.accuracyTrendTitle,
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _kDarkText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      loc.weeklyAccuracyTrendSubtitle,
                      style: GoogleFonts.cairo(fontSize: 12, color: _kSubText),
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
                                loc.notEnoughDataYetMessage,
                                style: GoogleFonts.cairo(
                                  fontSize: 13,
                                  color: _kSubText,
                                ),
                              ),
                              Text(
                                loc.completeQuizzesTrendHint,
                                style: GoogleFonts.cairo(
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

              // Time by Subject
              if (report.subjectAllocations.isNotEmpty) ...[
                _buildSubjectAllocationCard(report.subjectAllocations),
                const SizedBox(height: 16),
              ],

              // Streak Progress Card
              _buildStreakCard(report),
              const SizedBox(height: 16),

              // Effort & Focus
              if (report.voluntaryQuizzes + report.forcedQuizzes > 0) ...[
                _buildEffortCard(report),
                const SizedBox(height: 16),
              ],

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
                          loc.smartInsightsTitle,
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
                      report.aiInsightText.isNotEmpty
                          ? report.aiInsightText
                          : _generateInsight(report),
                      style: GoogleFonts.cairo(
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
    final loc = AppLocalizations.of(context);
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
            loc.streakProgressTitle,
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _kDarkText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            loc.currentStreakVsBestSubtitle,
            style: GoogleFonts.cairo(fontSize: 12, color: _kSubText),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _streakStat(Icons.local_fire_department_rounded, _kAmber,
                  '$current', loc.currentStreakLabel, loc.daysUnitLabel),
              const SizedBox(width: 12),
              Expanded(child: Container(height: 1, color: const Color(0xFFE2E8F0))),
              const SizedBox(width: 12),
              _streakStat(Icons.emoji_events_rounded, _kTeal,
                  '$best', loc.personalBestLabel, loc.daysUnitLabel),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            best > 0
                ? loc.percentOfPersonalBest((fraction * 100).toInt())
                : loc.noStreakYetMessage,
            style: GoogleFonts.cairo(
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
              style: GoogleFonts.cairo(
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
                style: GoogleFonts.cairo(fontSize: 12, color: _kSubText),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.cairo(fontSize: 12, color: _kSubText),
        ),
      ],
    );
  }

  Widget _buildEffortCard(WeeklyReportModel report) {
    final loc = AppLocalizations.of(context);
    final voluntary = report.voluntaryQuizzes;
    final forced = report.forcedQuizzes;
    final total = voluntary + forced;
    final guessing = report.guessingSessions;
    final voluntaryFraction = total > 0 ? voluntary / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.effortFocusTitle,
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _kDarkText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            loc.effortFocusSubtitle,
            style: GoogleFonts.cairo(fontSize: 12, color: _kSubText),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _effortStat(Icons.volunteer_activism_rounded, _kTeal,
                    '$voluntary', loc.selfStartedLabel),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _effortStat(Icons.lock_open_rounded, _kAmber,
                    '$forced', loc.toUnlockAppsLabel),
              ),
            ],
          ),
          if (total > 0) ...[
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: voluntaryFraction,
                minHeight: 8,
                backgroundColor: _kAmber.withValues(alpha: 0.25),
                color: _kTeal,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              loc.percentSelfStartedMessage((voluntaryFraction * 100).toInt()),
              style: GoogleFonts.cairo(
                fontSize: 12,
                color: _kSubText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (guessing > 0) ...[
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_amber_rounded, color: _kRed, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    loc.quizzesGuessingMessage(guessing),
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: _kRed,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _effortStat(IconData icon, Color color, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                value,
                style: GoogleFonts.cairo(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: _kDarkText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.cairo(fontSize: 12, color: _kSubText)),
        ],
      ),
    );
  }

  String _generateInsight(WeeklyReportModel report) {
    final loc = AppLocalizations.of(context);
    final q = report.totalQuizzes;
    final acc = report.overallAccuracyPercent.toInt();
    final streak = report.currentStreakDays;

    if (q == 0) {
      return loc.insightNoQuizzes;
    }
    if (acc >= 85 && q >= 5) {
      return loc.insightOutstanding(q, acc);
    }
    if (acc >= 70 && q >= 3) {
      return loc.insightGoodWeek(q, acc);
    }
    if (acc >= 55) {
      return loc.insightRoomToImprove(q, acc);
    }
    if (streak >= 3) {
      return loc.insightStreakKept(streak, acc);
    }
    return loc.insightDefault(acc, q);
  }

  Widget _buildAlertsCard(List<AlertModel> alerts) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kRed.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kRed.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notifications_active_rounded,
                  color: _kRed, size: 18),
              const SizedBox(width: 8),
              Text(
                "Needs Attention",
                style: GoogleFonts.cairo(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: _kDarkText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...alerts.map((a) {
            final isHigh = a.severity == 'high';
            final color = isHigh ? _kRed : _kAmber;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      isHigh
                          ? Icons.error_rounded
                          : Icons.warning_amber_rounded,
                      color: color,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      a.message,
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        height: 1.3,
                        color: _kDarkText,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    Color color, {
    String? delta,
    bool deltaUp = true,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: _cardDecoration(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: GoogleFonts.cairo(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.cairo(fontSize: 12, color: _kSubText),
            textAlign: TextAlign.center,
          ),
          if (delta != null) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  deltaUp
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  size: 11,
                  color: deltaUp ? _kTeal : _kRed,
                ),
                const SizedBox(width: 2),
                Text(
                  delta,
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: deltaUp ? _kTeal : _kRed,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubjectAllocationCard(List<SubjectTimeAllocation> allocations) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Time by Subject",
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _kDarkText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "How study time was split this week",
            style: GoogleFonts.cairo(fontSize: 12, color: _kSubText),
          ),
          const SizedBox(height: 16),
          ...allocations.map((a) {
            final color = _hexToColor(a.colorHex);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          a.subjectKey,
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _kDarkText,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        "${a.percentage.toStringAsFixed(0)}%",
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: _kDarkText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (a.percentage / 100).clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: const Color(0xFFE2E8F0),
                      color: color,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _hexToColor(String hex) {
    var h = hex.replaceFirst('#', '').trim();
    if (h.length == 6) h = 'FF$h';
    final value = int.tryParse(h, radix: 16);
    return value != null ? Color(value) : _kPrimary;
  }

  Widget _buildMasteryHistoryCard(List<MasteryHistoryPoint> history) {
    final hasTrend = history.length >= 2;
    final points = history
        .map((h) => WeeklyAccuracyPoint(weekLabel: '', accuracy: h.mastery))
        .toList();
    final delta = hasTrend ? history.last.mastery - history.first.mastery : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Mastery Over Time",
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _kDarkText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hasTrend
                ? "Daily mastery over the last ${history.length} day${history.length == 1 ? '' : 's'}"
                : "Mastery is recorded daily as quizzes are taken",
            style: GoogleFonts.cairo(fontSize: 12, color: _kSubText),
          ),
          const SizedBox(height: 20),
          if (hasTrend) ...[
            SizedBox(
              height: 140,
              width: double.infinity,
              child: CustomPaint(painter: _AccuracyTrendPainter(points)),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  delta >= 0
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  color: delta >= 0 ? _kTeal : _kRed,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  "${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)}% over this period",
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: delta >= 0 ? _kTeal : _kRed,
                  ),
                ),
              ],
            ),
          ] else
            SizedBox(
              height: 90,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.show_chart_rounded,
                        size: 36, color: _kSubText.withValues(alpha: 0.4)),
                    const SizedBox(height: 8),
                    Text(
                      "Not enough data yet",
                      style: GoogleFonts.cairo(fontSize: 13, color: _kSubText),
                    ),
                    Text(
                      "Check back after a few more study days",
                      style: GoogleFonts.cairo(
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
    );
  }

  Widget _buildDifficultyCard(List<DifficultyAccuracy> items) {
    const labels = {
      1: 'Very Easy',
      2: 'Easy',
      3: 'Medium',
      4: 'Hard',
      5: 'Very Hard',
    };
    final shown = items.where((d) => d.total > 0).toList();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Accuracy by Difficulty",
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _kDarkText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "How performance holds up as questions get harder",
            style: GoogleFonts.cairo(fontSize: 12, color: _kSubText),
          ),
          const SizedBox(height: 16),
          ...shown.map((d) {
            final acc = d.accuracy;
            final color = acc >= 75 ? _kTeal : (acc >= 50 ? _kAmber : _kRed);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "${labels[d.difficulty] ?? 'Level ${d.difficulty}'} · ${d.total} Q",
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _kDarkText,
                          ),
                        ),
                      ),
                      Text(
                        "${acc.toInt()}%",
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (acc / 100).clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: const Color(0xFFE2E8F0),
                      color: color,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Subject Mastery Tab ─────────────────────────────────────────────────────

  Widget _buildSubjectMasteryTab() {
    return BlocBuilder<ReportsBloc, ReportsState>(
      builder: (context, state) {
        // First load (no chips yet): show spinner / error / empty for the whole tab.
        if (state.isMasteryLoading && state.subjects.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.masteryError != null && state.masteryReport == null) {
          return Center(
            child: Text(
              state.masteryError!,
              style: const TextStyle(color: Colors.red),
            ),
          );
        }
        if (state.subjects.isEmpty) {
          return Center(child: Text(AppLocalizations.of(context).noSubjectsReportMessage));
        }

        final report = state.masteryReport;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Subject chips (always visible once loaded)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: state.subjects.map((sub) {
                    final isSelected = sub.id == state.selectedSubjectId;
                    return Padding(
                      padding: const EdgeInsetsDirectional.only(end: 8.0),
                      child: ChoiceChip(
                        label: Text(sub.name),
                        selected: isSelected,
                        selectedColor: _kPrimary,
                        labelStyle: GoogleFonts.cairo(
                          color: isSelected ? Colors.white : _kDarkText,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        onSelected: (val) {
                          if (val && sub.id != state.selectedSubjectId) {
                            context.read<ReportsBloc>().add(
                              LoadSubjectMasteryRequested(
                                studentUid: widget.student.uid,
                                subjectId: sub.id,
                              ),
                            );
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              if (state.isMasteryLoading || report == null)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                // Total Mastery Card
                _buildTotalMasteryCard(
                  report.totalMasteryPercent,
                  report.masteryLabel,
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
                              style: GoogleFonts.cairo(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: _kPrimary,
                              ),
                            ),
                            Text(
                              "Mastered",
                              style: GoogleFonts.cairo(
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

                // Mastery Over Time
                _buildMasteryHistoryCard(report.masteryHistory),
                const SizedBox(height: 24),

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
                  ...report.strongSkills.map(
                    (skill) => _buildSkillRow(
                      skill.name,
                      skill.masteryPercent.toInt(),
                      isStrong: true,
                    ),
                  ),
                ] else ...[
                  Text(
                    "No strong areas identified yet.",
                    style: GoogleFonts.cairo(color: _kSubText),
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
                  ...report.weakSkills.map(
                    (skill) => _buildSkillRow(
                      skill.name,
                      skill.masteryPercent.toInt(),
                      isNeedsWork: true,
                    ),
                  ),
                ] else ...[
                  Text(
                    "No weak areas identified yet.",
                    style: GoogleFonts.cairo(color: _kSubText),
                  ),
                ],

                // Error Analytics — only when there are wrong answers to break down.
                if (report.errorAnalytics != null) ...[
                  const SizedBox(height: 24),
                  _buildErrorAnalyticsCard(
                    report.errorAnalytics!,
                    report.subjectKey,
                  ),
                ],

                // Accuracy by difficulty — only when there are answered questions.
                if (report.difficultyAccuracy.any((d) => d.total > 0)) ...[
                  const SizedBox(height: 24),
                  _buildDifficultyCard(report.difficultyAccuracy),
                ],
                const SizedBox(height: 24),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildTotalMasteryCard(double percent, String label) {
    final loc = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_kPrimary.withValues(alpha: 0.08), _kTeal.withValues(alpha: 0.04)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kPrimary.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _kPrimary.withValues(alpha: 0.1),
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
                  loc.totalAverageMasteryLabel,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _kSubText,
                    height: 1.2,
                  ),
                ),
                Text(
                  loc.masteryScorePercentLabel(percent.toStringAsFixed(1)),
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
              style: GoogleFonts.cairo(
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

  Widget _buildErrorAnalyticsCard(ErrorAnalyticModel analytics, String subjectName) {
    final loc = AppLocalizations.of(context);
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
                loc.errorAnalyticsTitle,
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
            "Common mistake types on $subjectName quizzes.",
            style: GoogleFonts.cairo(fontSize: 12, color: _kSubText),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 14,
            width: double.infinity,
            child: CustomPaint(painter: _ErrorAnalyticsPainter(analytics)),
          ),
          const SizedBox(height: 20),
          _errorDetailItem(
            _kRed.withValues(alpha: 0.8),
            "Careless Mistakes (${analytics.carelessPercent.toInt()}%)",
            "Knew the material but slipped on a quick answer",
          ),
          const SizedBox(height: 10),
          _errorDetailItem(
            _kAmber,
            "Concept Gaps (${analytics.conceptGapPercent.toInt()}%)",
            "Genuine difficulty with the underlying topic",
          ),
          const SizedBox(height: 10),
          _errorDetailItem(
            _kPrimary,
            "Guessing (${analytics.guessingPercent.toInt()}%)",
            "Answered too fast to have thought it through",
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
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: _kDarkText,
                  height: 1.2,
                ),
              ),
              Text(
                description,
                style: GoogleFonts.cairo(
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
                style: GoogleFonts.cairo(
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
    final loc = AppLocalizations.of(context);
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
          return Center(child: Text(loc.noHabitsReportMessage));
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
                                loc.currentStreakStatLabel,
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  color: _kSubText,
                                ),
                              ),
                              Text(
                                loc.daysCountLabel(report.currentStreakDays),
                                style: GoogleFonts.cairo(
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
                                loc.longestStreakStatLabel,
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  color: _kSubText,
                                ),
                              ),
                              Text(
                                loc.daysCountLabel(report.longestStreakDays),
                                style: GoogleFonts.cairo(
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

              // Daily Study Time Chart
              Container(
                padding: const EdgeInsets.all(20),
                decoration: _cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Daily Study Time",
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _kDarkText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Active learning minutes over the last 7 days.",
                      style: GoogleFonts.cairo(fontSize: 12, color: _kSubText),
                    ),
                    const SizedBox(height: 24),
                    if (report.dailyStudy.any((d) => d.studyMinutes > 0)) ...[
                      SizedBox(
                        height: 180,
                        width: double.infinity,
                        child: CustomPaint(
                          painter: _DailyStudyPainter(report.dailyStudy, hLabel: loc.hourUnitLabel, mLabel: loc.minuteUnitLabel),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: report.dailyStudy
                            .map((c) => _chartLabel(c.dayLabel))
                            .toList(),
                      ),
                    ] else
                      SizedBox(
                        height: 100,
                        child: Center(
                          child: Text(
                            "No study time recorded in the last 7 days",
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              color: _kSubText,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // When They Study (time-of-day distribution)
              if (report.timeOfDay.any((t) => t.minutes > 0)) ...[
                _buildTimeOfDayCard(report.timeOfDay),
                const SizedBox(height: 16),
              ],
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimeOfDayCard(List<TimeOfDayPoint> points) {
    final loc = AppLocalizations.of(context);
    final maxMinutes = points
        .map((p) => p.minutes)
        .fold<int>(0, (a, b) => a > b ? a : b);
    final scale = maxMinutes <= 0 ? 1 : maxMinutes;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "When They Study",
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _kDarkText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Study time by part of the day (last 30 days)",
            style: GoogleFonts.cairo(fontSize: 12, color: _kSubText),
          ),
          const SizedBox(height: 16),
          ...points.map((p) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 78,
                    child: Text(
                      p.label,
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _kDarkText,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (p.minutes / scale).clamp(0.0, 1.0),
                        minHeight: 8,
                        backgroundColor: const Color(0xFFE2E8F0),
                        color: _kTeal,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 52,
                    child: Text(
                      p.minutes >= 60
                          ? (p.minutes % 60 == 0
                              ? '${p.minutes ~/ 60}${loc.hourUnitLabel}'
                              : '${p.minutes ~/ 60}${loc.hourUnitLabel} ${p.minutes % 60}${loc.minuteUnitLabel}')
                          : '${p.minutes}${loc.minuteUnitLabel}',
                      textAlign: TextAlign.right,
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _kSubText,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHeatmapCard(StudyHabitsReport report) {
    final loc = AppLocalizations.of(context);
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
            loc.studyConsistencyGridTitle,
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _kDarkText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            loc.activeStudyDaysSubtitle,
            style: GoogleFonts.cairo(fontSize: 12, color: _kSubText),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 18),
                  _heatmapWeekLabel(loc.threeWeeksAgoLabel),
                  _heatmapWeekLabel(loc.twoWeeksAgoLabel),
                  _heatmapWeekLabel(loc.oneWeekAgoLabel),
                  _heatmapWeekLabel(loc.thisWeekLabel),
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
                          _heatmapDayLabel(loc.dayAbbrevMon),
                          _heatmapDayLabel(loc.dayAbbrevTue),
                          _heatmapDayLabel(loc.dayAbbrevWed),
                          _heatmapDayLabel(loc.dayAbbrevThu),
                          _heatmapDayLabel(loc.dayAbbrevFri),
                          _heatmapDayLabel(loc.dayAbbrevSat),
                          _heatmapDayLabel(loc.dayAbbrevSun),
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
                loc.legendLessLabel,
                style: GoogleFonts.cairo(fontSize: 10, color: _kSubText),
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
                loc.legendMoreLabel,
                style: GoogleFonts.cairo(fontSize: 10, color: _kSubText),
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
          style: GoogleFonts.cairo(
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
          style: GoogleFonts.cairo(
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
      color = _kPrimary.withValues(alpha: 0.25);
    } else if (minutes < 60) {
      color = _kPrimary.withValues(alpha: 0.5);
    } else if (minutes < 90) {
      color = _kPrimary.withValues(alpha: 0.75);
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
      style: GoogleFonts.cairo(fontSize: 10, color: _kSubText),
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
        colors: [_kPrimary.withValues(alpha: 0.3), _kPrimary.withValues(alpha: 0.0)],
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

    final paint1 = Paint()..color = _kRed.withValues(alpha: 0.8);
    final paint2 = Paint()..color = _kAmber;
    final paint3 = Paint()..color = _kPrimary;

    final w1 = size.width * (data.carelessPercent / 100.0);
    final w2 = size.width * (data.conceptGapPercent / 100.0);
    final w3 = size.width * (data.guessingPercent / 100.0);

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
          paint.color = _kPrimary.withValues(alpha: 0.25);
        } else if (minutes < 60) {
          paint.color = _kPrimary.withValues(alpha: 0.5);
        } else if (minutes < 90) {
          paint.color = _kPrimary.withValues(alpha: 0.75);
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

class _DailyStudyPainter extends CustomPainter {
  final List<DailyStudyPoint> data;
  final String hLabel;
  final String mLabel;
  _DailyStudyPainter(this.data, {required this.hLabel, required this.mLabel});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final values = data.map((e) => e.studyMinutes).toList();
    final maxVal = values.reduce((a, b) => a > b ? a : b).toDouble();
    final scale = maxVal <= 0 ? 1.0 : maxVal;

    final n = data.length;
    final stepX = size.width / n;
    final barWidth = (stepX * 0.5).clamp(6.0, 28.0);
    // Reserve room at the top so the minute labels are always readable.
    const labelGap = 18.0;
    final chartHeight = size.height - labelGap;

    final paint = Paint()
      ..color = _kPrimary
      ..style = PaintingStyle.fill;

    for (int i = 0; i < n; i++) {
      final centerX = (i * stepX) + (stepX / 2);
      final h = (values[i] / scale) * (chartHeight - 4);
      final top = size.height - h;
      final rect = Rect.fromLTWH(
        centerX - barWidth / 2,
        top,
        barWidth,
        h,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        paint,
      );

      // Value label above each bar so exact study time is readable.
      if (values[i] > 0) {
        final tp = TextPainter(
          text: TextSpan(
            text: _formatMinutes(values[i]),
            style: GoogleFonts.cairo(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: _kDarkText,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(centerX - tp.width / 2, top - tp.height - 2));
      }
    }
  }

  String _formatMinutes(int minutes) {
    if (minutes >= 60) {
      final h = minutes ~/ 60;
      final m = minutes % 60;
      return m == 0 ? '$h$hLabel' : '$h$hLabel $m$mLabel';
    }
    return '$minutes$mLabel';
  }

  @override
  bool shouldRepaint(covariant _DailyStudyPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.hLabel != hLabel || oldDelegate.mLabel != mLabel;
  }
}
