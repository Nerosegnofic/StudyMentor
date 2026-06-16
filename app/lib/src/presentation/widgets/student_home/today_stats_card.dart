import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../domain/models/report_models.dart';
import 'questions_ring.dart';

/// The "Today" card: a subject-segmented questions ring (hero) plus a row of
/// three profile-style icon-chip stats (Studied · Streak · Accuracy).
class TodayStatsCard extends StatelessWidget {
  final List<SubjectQuestionCount> questionsBySubject;
  final Duration studyTime;
  final int streak;
  final int accuracyPercent;

  const TodayStatsCard({
    super.key,
    required this.questionsBySubject,
    required this.studyTime,
    required this.streak,
    required this.accuracyPercent,
  });

  static const Color _ink = Color(0xFF1F2937);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today',
            style: GoogleFonts.cairo(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: _ink,
            ),
          ),
          const SizedBox(height: 16),
          Center(child: QuestionsRing(segments: questionsBySubject)),
          const SizedBox(height: 18),
          Divider(height: 1, color: Colors.grey.shade100),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _stat(
                  icon: Icons.schedule_rounded,
                  iconBg: const Color(0xFFE3F2FD),
                  iconColor: const Color(0xFF2196F3),
                  value: _formatStudyTime(studyTime),
                  label: 'Studied',
                ),
              ),
              Expanded(
                child: _stat(
                  icon: Icons.local_fire_department_rounded,
                  iconBg: const Color(0xFFFFEBEE),
                  iconColor: const Color(0xFFF44336),
                  value: '$streak',
                  label: 'Day streak',
                ),
              ),
              Expanded(
                child: _stat(
                  icon: Icons.track_changes_rounded,
                  iconBg: const Color(0xFFE8F5E9),
                  iconColor: const Color(0xFF43A047),
                  value: '$accuracyPercent%',
                  label: 'Accuracy',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: _ink,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.roboto(fontSize: 11, color: Colors.grey.shade500),
        ),
      ],
    );
  }

  /// 25m → "25m", 65m → "1h 5m", 0 → "0m"
  String _formatStudyTime(Duration d) {
    final m = d.inMinutes;
    if (m <= 0) return '0m';
    if (m < 60) return '${m}m';
    final h = m ~/ 60;
    final rem = m % 60;
    return rem > 0 ? '${h}h ${rem}m' : '${h}h';
  }
}