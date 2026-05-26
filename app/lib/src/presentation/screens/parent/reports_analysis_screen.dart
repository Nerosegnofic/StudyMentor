import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

import '../../../domain/models/student_model.dart';

// ── Design Tokens ─────────────────────────────────────────────────────────────
const _kPrimary = Color(0xFF2196F3);
const _kPrimaryLight = Color(0xFFE3F2FD);
const _kAmber = Color(0xFFFFC107);
const _kTeal = Color(0xFF00897B);
const _kTealLight = Color(0xFFE0F2F1);
const _kRed = Color(0xFFE53935);
const _kRedLight = Color(0xFFFFEBEE);
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
                  child: Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 20),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Metrics Row
          Row(
            children: [
              Expanded(
                child: _buildMetricCard("Accuracy", "85%", _kTeal),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard("Quizzes", "12", _kPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard("Study Time", "4.5h", _kAmber),
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
                  "Weekly Accuracy Trend",
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _kDarkText,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 140,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _AccuracyTrendPainter(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _chartLabel("W1"),
                    _chartLabel("W2"),
                    _chartLabel("W3"),
                    _chartLabel("W4"),
                    _chartLabel("W5"),
                    _chartLabel("This Wk"),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Subject Time Allocation (Donut Chart)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: _cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Subject Time Allocation",
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _kDarkText,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "How learning time is split across different subjects this week.",
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    color: _kSubText,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 120,
                          height: 120,
                          child: CustomPaint(
                            painter: _SubjectDonutPainter(),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "4.5h",
                              style: GoogleFonts.roboto(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _kDarkText,
                                height: 1.1,
                              ),
                            ),
                            Text(
                              "Total Time",
                              style: GoogleFonts.roboto(
                                fontSize: 9,
                                color: _kSubText,
                                height: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _donutLegendItem("Mathematics", "40%", _kPrimary),
                          const SizedBox(height: 8),
                          _donutLegendItem("Science", "30%", _kTeal),
                          const SizedBox(height: 8),
                          _donutLegendItem("English", "20%", _kAmber),
                          const SizedBox(height: 8),
                          _donutLegendItem("History", "10%", _kRed),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Smart Insights
          Container(
            padding: const EdgeInsets.all(20),
            decoration: _cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.insights_rounded, color: _kPrimary),
                    const SizedBox(width: 8),
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
                const SizedBox(height: 12),
                Text(
                  "${widget.student.fullName.split(' ').first} has completed 12 quizzes this week with an impressive 85% accuracy. Math scores are climbing, but Science activity was low over the last 3 days. A quick review of Science topics might be beneficial.",
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    height: 1.5,
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
  }

  Widget _donutLegendItem(String subject, String percentage, Color color) {
    return Row(
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
            subject,
            style: GoogleFonts.roboto(
              fontSize: 13,
              color: _kDarkText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          percentage,
          style: GoogleFonts.roboto(
            fontSize: 13,
            color: _kSubText,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
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
            style: GoogleFonts.roboto(
              fontSize: 12,
              color: _kSubText,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Subject Mastery Tab ─────────────────────────────────────────────────────

  Widget _buildSubjectMasteryTab() {
    final subjects = ['Mathematics', 'Science', 'English', 'History'];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total Mastery Card
          _buildTotalMasteryCard(),
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
                    label: Text(sub),
                    selected: isSelected,
                    selectedColor: _kPrimary,
                    labelStyle: GoogleFonts.roboto(
                      color: isSelected ? Colors.white : _kDarkText,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _selectedSubject = sub);
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
                painter: _MasteryCirclePainter(percentage: 0.75),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "75%",
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
          _buildSkillRow("الكسور", 88, isStrong: true),
          _buildSkillRow("الجبر والتفاضل والتكامل المتقدم جداً", 82, isStrong: true),

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
          _buildSkillRow("الهندسة", 42, isNeedsWork: true),
          _buildSkillRow("الأعداد العشرية", 35, isNeedsWork: true),
          
          const SizedBox(height: 24),
          // Error Analytics
          _buildErrorAnalyticsCard(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildTotalMasteryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _kPrimary.withOpacity(0.08),
            _kTeal.withOpacity(0.04),
          ],
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
                  "72.5% Mastery Score",
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
              "Good",
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

  Widget _buildErrorAnalyticsCard() {
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
            style: GoogleFonts.roboto(
              fontSize: 12,
              color: _kSubText,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 14,
            width: double.infinity,
            child: CustomPaint(
              painter: _ErrorAnalyticsPainter(),
            ),
          ),
          const SizedBox(height: 20),
          _errorDetailItem(_kRed.withOpacity(0.8), "Careless Mistakes (45%)", "Answering too quickly on calculations"),
          const SizedBox(height: 10),
          _errorDetailItem(_kAmber, "Concept Gaps (38%)", "Struggles with newly introduced topics"),
          const SizedBox(height: 10),
          _errorDetailItem(_kPrimary, "Time Pressure (17%)", "Failing to finish within the quiz timer"),
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
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
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

  Widget _buildSkillRow(String name, int score,
      {bool isStrong = false, bool isNeedsWork = false}) {
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
                      const Icon(Icons.local_fire_department_rounded, color: _kAmber, size: 32),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Current Streak", style: GoogleFonts.roboto(fontSize: 12, color: _kSubText)),
                          Text("7 Days", style: GoogleFonts.roboto(fontSize: 18, fontWeight: FontWeight.bold, color: _kDarkText)),
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
                      const Icon(Icons.emoji_events_rounded, color: _kTeal, size: 32),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Longest Streak", style: GoogleFonts.roboto(fontSize: 12, color: _kSubText)),
                          Text("14 Days", style: GoogleFonts.roboto(fontSize: 18, fontWeight: FontWeight.bold, color: _kDarkText)),
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
          _buildHeatmapCard(),
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
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    color: _kSubText,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _CorrelationChartPainter(),
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
                  children: [
                    _chartLabel("Mon"),
                    _chartLabel("Tue"),
                    _chartLabel("Wed"),
                    _chartLabel("Thu"),
                    _chartLabel("Fri"),
                    _chartLabel("Sat"),
                    _chartLabel("Sun"),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeatmapCard() {
    final studyMinutes = [
      30, 45, 0, 60, 90, 0, 15,
      45, 0, 30, 60, 0, 120, 0,
      0, 40, 60, 90, 30, 0, 15,
      40, 60, 45, 90, 120, 30, 0
    ];

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
            style: GoogleFonts.roboto(
              fontSize: 12,
              color: _kSubText,
            ),
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
                          painter: _ActivityHeatmapPainter(studyMinutes: studyMinutes),
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
              Text("Less", style: GoogleFonts.roboto(fontSize: 10, color: _kSubText)),
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
              Text("More", style: GoogleFonts.roboto(fontSize: 10, color: _kSubText)),
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
      style: GoogleFonts.roboto(
        fontSize: 10,
        color: _kSubText,
      ),
    );
  }
}

// ── Custom Painters ───────────────────────────────────────────────────────────

class _AccuracyTrendPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final points = [0.4, 0.5, 0.45, 0.7, 0.65, 0.85];

    final paintLine = Paint()
      ..color = _kPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final paintFill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          _kPrimary.withOpacity(0.3),
          _kPrimary.withOpacity(0.0),
        ],
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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

class _SubjectDonutPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 8;
    const strokeWidth = 14.0;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final segments = [
      _DonutSegment(value: 0.40, color: _kPrimary),
      _DonutSegment(value: 0.30, color: _kTeal),
      _DonutSegment(value: 0.20, color: _kAmber),
      _DonutSegment(value: 0.10, color: _kRed),
    ];

    double startAngle = -math.pi / 2;

    for (var segment in segments) {
      final sweepAngle = segment.value * 2 * math.pi;
      paint.color = segment.color;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DonutSegment {
  final double value;
  final Color color;
  _DonutSegment({required this.value, required this.color});
}

class _ErrorAnalyticsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final r = h / 2;

    final bgPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, h), Radius.circular(r)), bgPaint);

    final paint1 = Paint()..color = _kRed.withOpacity(0.8);
    final paint2 = Paint()..color = _kAmber;
    final paint3 = Paint()..color = _kPrimary;

    final w1 = size.width * 0.45;
    final w2 = size.width * 0.38;
    final w3 = size.width * 0.17;

    final clipRRect = RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, h), Radius.circular(r));
    canvas.save();
    canvas.clipRRect(clipRRect);

    canvas.drawRect(Rect.fromLTWH(0, 0, w1, h), paint1);
    canvas.drawRect(Rect.fromLTWH(w1, 0, w2, h), paint2);
    canvas.drawRect(Rect.fromLTWH(w1 + w2, 0, w3, h), paint3);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
  @override
  void paint(Canvas canvas, Size size) {
    final studyMins = [40, 60, 45, 90, 120, 30, 0];
    final appMins = [90, 45, 60, 30, 20, 150, 180];

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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
