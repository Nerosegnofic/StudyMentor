import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../domain/models/student_model.dart';
import '../../../domain/models/report_models.dart';
import '../../../data/repositories/ai_engine_repository.dart';

class ChildCard extends StatefulWidget {
  final StudentModel student;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const ChildCard({super.key, required this.student, this.onTap, this.onDelete});

  @override
  State<ChildCard> createState() => _ChildCardState();
}

class _ChildCardState extends State<ChildCard> {
  int _xp = 0;
  int _coins = 0;
  int _streakDays = 0;
  int _weeklyQuizzes = 0;
  int _weeklyStudyMinutes = 0;
  int _weeklyAccuracyPercent = 0;
  bool _statsLoading = true;
  bool _statsError = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadStats();
    _startPollingIfUnverified();
  }

  @override
  void didUpdateWidget(ChildCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.student.isEmailVerified != widget.student.isEmailVerified) {
      _startPollingIfUnverified();
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startPollingIfUnverified() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    if (!widget.student.isEmailVerified) {
      _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        if (mounted) _loadStats();
      });
    }
  }

  Future<void> _loadStats() async {
    try {
      final results = await Future.wait([
        AiEngineRepository.instance.getGamificationProfile(widget.student.uid),
        AiEngineRepository.instance.getWeeklyReport(widget.student.uid),
      ]);
      if (!mounted) return;
      final profile = results[0] as Map<String, dynamic>;
      final report = results[1] as WeeklyReportModel;
      setState(() {
        _xp = (profile['xp_total'] as int?) ?? 0;
        _coins = (profile['coins_total'] as int?) ?? 0;
        _streakDays = (profile['current_streak'] as int?) ?? 0;
        _weeklyQuizzes = report.totalQuizzes;
        _weeklyStudyMinutes = report.totalStudyTime.inMinutes;
        _weeklyAccuracyPercent = report.overallAccuracyPercent.round();
        _statsLoading = false;
        _statsError = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _statsLoading = false;
        _statsError = true;
      });
    }
  }

  String _fmtMinutes(int mins) {
    if (mins <= 0) return '0m';
    final h = mins ~/ 60;
    final m = mins % 60;
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final verified = widget.student.isEmailVerified;
    final initial = widget.student.fullName.isNotEmpty
        ? widget.student.fullName[0].toUpperCase()
        : '?';

    if (!verified) return _buildUnverifiedCard(initial);

    final quizzesText = _statsLoading ? '…' : _statsError ? '—' : '$_weeklyQuizzes';
    final studyText = _statsLoading ? '…' : _statsError ? '—' : _fmtMinutes(_weeklyStudyMinutes);

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Color(0x0D000000), blurRadius: 12, offset: Offset(0, 4)),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────────────────────────
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFF2196F3),
                  child: Text(
                    initial,
                    style: GoogleFonts.cairo(
                        color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.student.fullName,
                    style: GoogleFonts.cairo(
                        color: const Color(0xFF1E293B),
                        fontWeight: FontWeight.bold,
                        fontSize: 17),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1)),
              ],
            ),

            const SizedBox(height: 16),

            // ── Gamification Row ────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBF0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFE082), width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _GamStat(
                      icon: Icons.bolt_rounded,
                      color: const Color(0xFFF59E0B),
                      value: '$_xp',
                      label: 'XP'),
                  _divider(),
                  _GamStat(
                      icon: Icons.local_fire_department_rounded,
                      color: const Color(0xFFEF4444),
                      value: '$_streakDays',
                      label: 'Streak'),
                  _divider(),
                  _GamStat(
                      icon: Icons.monetization_on_rounded,
                      color: const Color(0xFFF59E0B),
                      value: '$_coins',
                      label: 'Coins'),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Weekly Stats Tiles ──────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    icon: Icons.quiz_rounded,
                    color: const Color(0xFF2196F3),
                    value: quizzesText,
                    label: 'Quizzes',
                    sublabel: 'This week',
                    isLoading: _statsLoading,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatTile(
                    icon: Icons.schedule_rounded,
                    color: const Color(0xFF8B5CF6),
                    value: studyText,
                    label: 'Study Time',
                    sublabel: 'This week',
                    isLoading: _statsLoading,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ── Weekly Accuracy ─────────────────────────────────────────
            _AccuracyRow(
              percent: _weeklyAccuracyPercent,
              isLoading: _statsLoading,
              isError: _statsError,
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 32,
        color: const Color(0xFFFFE082),
      );

  // ── Unverified card ────────────────────────────────────────────────────────

  Widget _buildUnverifiedCard(String initial) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 15),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2332),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2D3748), width: 1),
        boxShadow: const [
          BoxShadow(color: Color(0x40000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFF2D3748),
                child: Text(
                  initial,
                  style: GoogleFonts.cairo(
                      color: const Color(0xFF4A5568),
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.student.fullName,
                      style: GoogleFonts.cairo(
                          color: const Color(0xFF94A3B8),
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.student.email,
                      style: GoogleFonts.roboto(
                          color: const Color(0xFF4A5568), fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                    color: const Color(0xFF78350F),
                    borderRadius: BorderRadius.circular(20)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.mark_email_unread_outlined,
                        size: 12, color: Color(0xFFFBBF24)),
                    const SizedBox(width: 4),
                    Text(
                      'UNVERIFIED',
                      style: GoogleFonts.roboto(
                          color: const Color(0xFFFBBF24),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFF2D3748), height: 1),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.hourglass_top_rounded,
                  size: 16, color: Color(0xFF64748B)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Waiting for the student to verify their email and log in for the first time.',
                  style: GoogleFonts.roboto(
                      color: const Color(0xFF64748B), fontSize: 13, height: 1.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF14532D),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF166534), width: 1),
            ),
            child: Row(
              children: [
                const Icon(Icons.monetization_on_rounded,
                    size: 16, color: Color(0xFFFBBF24)),
                const SizedBox(width: 8),
                Text(
                  '+3 coins will be awarded on first login',
                  style: GoogleFonts.roboto(
                      color: const Color(0xFFBBF7D0),
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          if (widget.onDelete != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: widget.onDelete,
                icon: const Icon(
                  Icons.person_remove_outlined,
                  size: 15,
                  color: Color(0xFFFC8181),
                ),
                label: Text(
                  'Remove Student',
                  style: GoogleFonts.roboto(
                    color: const Color(0xFFFC8181),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF991B1B), width: 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _GamStat extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _GamStat(
      {required this.icon,
      required this.color,
      required this.value,
      required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.roboto(
              color: const Color(0xFF1E293B),
              fontWeight: FontWeight.bold,
              fontSize: 15),
        ),
        Text(
          label,
          style: GoogleFonts.roboto(
              color: const Color(0xFF94A3B8), fontSize: 10),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;
  final String sublabel;
  final bool isLoading;

  const _StatTile({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    required this.sublabel,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 17),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isLoading)
                  SizedBox(
                    height: 14,
                    width: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: color),
                  )
                else
                  Text(
                    value,
                    style: GoogleFonts.roboto(
                        color: const Color(0xFF1E293B),
                        fontWeight: FontWeight.bold,
                        fontSize: 15),
                  ),
                Text(
                  label,
                  style: GoogleFonts.roboto(
                      color: const Color(0xFF475569),
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
                Text(
                  sublabel,
                  style: GoogleFonts.roboto(
                      color: const Color(0xFF94A3B8), fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AccuracyRow extends StatelessWidget {
  final int percent;
  final bool isLoading;
  final bool isError;

  const _AccuracyRow(
      {required this.percent, this.isLoading = false, this.isError = false});

  @override
  Widget build(BuildContext context) {
    final fraction =
        isLoading || isError ? 0.0 : (percent / 100.0).clamp(0.0, 1.0);
    final Color barColor = percent >= 70
        ? const Color(0xFF22C55E)
        : percent >= 50
            ? const Color(0xFFF59E0B)
            : const Color(0xFFEF4444);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.track_changes_rounded,
                size: 15,
                color: isLoading || isError
                    ? const Color(0xFF94A3B8)
                    : barColor,
              ),
              const SizedBox(width: 6),
              Text(
                'Weekly Accuracy',
                style: GoogleFonts.roboto(
                    color: const Color(0xFF475569),
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              Text(
                isLoading ? '…' : isError ? '—' : '$percent%',
                style: GoogleFonts.roboto(
                    color: isLoading || isError
                        ? const Color(0xFF94A3B8)
                        : barColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 7,
              backgroundColor: const Color(0xFFE2E8F0),
              color: isLoading || isError ? const Color(0xFFE2E8F0) : barColor,
            ),
          ),
        ],
      ),
    );
  }
}
