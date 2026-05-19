import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../domain/models/student_model.dart';

/// Dummy stats for the card — gateway logic: quizzes, study time, accuracy.
/// Real backend fields can replace these later.
class _ChildStats {
  final int xp;
  final int streakDays;
  final int coins;
  final int quizzesPassed;       // number of quizzes passed today
  final int studyTimeMinutes;    // minutes studied today
  final int dailyAccuracyPercent; // 0-100

  const _ChildStats({
    required this.xp,
    required this.streakDays,
    required this.coins,
    required this.quizzesPassed,
    required this.studyTimeMinutes,
    required this.dailyAccuracyPercent,
  });
}

/// Resolves stats for a given student using real model fields where available,
/// falling back to spec-defined dummy data keyed by first name.
_ChildStats _resolveStats(StudentModel student) {
  // Use real backend fields if available, otherwise provide generic dummy data
  // so the dashboard always looks populated and engaging.
  return _ChildStats(
    xp: student.totalXp ?? 245,
    streakDays: 7,
    coins: student.totalCoins ?? 120,
    quizzesPassed: 14,
    studyTimeMinutes: 25,
    dailyAccuracyPercent: 88,
  );
}

class ChildCard extends StatelessWidget {
  final StudentModel student;
  final VoidCallback? onTap;

  const ChildCard({super.key, required this.student, this.onTap});

  @override
  Widget build(BuildContext context) {
    final stats = _resolveStats(student);
    final initial = student.fullName.isNotEmpty
        ? student.fullName[0].toUpperCase()
        : '?';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000), // rgba(0,0,0,0.05)
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top Row: avatar + name ──────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFF2196F3),
                  child: Text(
                    initial,
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    student.fullName,
                    style: GoogleFonts.cairo(
                      color: const Color(0xFF1E293B),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, color: Color(0xFFCBD5E1)),
              ],
            ),

            // ── Stats Grid ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _StatCol(
                    icon: Icons.star_rounded,
                    value: '${stats.xp} XP',
                    label: 'Experience',
                  ),
                  _StatCol(
                    icon: Icons.local_fire_department_rounded,
                    value: '${stats.streakDays} Days',
                    label: 'Streak',
                  ),
                  _StatCol(
                    icon: Icons.monetization_on_rounded,
                    value: '${stats.coins}',
                    label: 'Coins',
                  ),
                ],
              ),
            ),

            const Divider(color: Color(0xFFF1F5F9), height: 1),
            const SizedBox(height: 16),

            // ── Row 1: Volume data (quizzes + study time) ─────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left: Quizzes Passed
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.roboto(
                        color: const Color(0xFF475569),
                        fontSize: 13,
                      ),
                      children: [
                        const TextSpan(text: 'Quizzes Passed: '),
                        TextSpan(
                          text: '${stats.quizzesPassed}',
                          style: const TextStyle(
                            color: Color(0xFF1E293B),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Right: Study Time
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.roboto(
                        color: const Color(0xFF475569),
                        fontSize: 13,
                      ),
                      children: [
                        const TextSpan(text: 'Study Time: '),
                        TextSpan(
                          text: '${stats.studyTimeMinutes} mins',
                          style: const TextStyle(
                            color: Color(0xFF1E293B),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Row 2: Daily Accuracy Bar ──────────────────────────────
            _AccuracyBar(accuracyPercent: stats.dailyAccuracyPercent),
          ],
        ),
      ),
    );
  }
}

// ── Private sub-widgets ──────────────────────────────────────────────────────

class _StatCol extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatCol({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFFFFC107), size: 26),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.roboto(
              color: const Color(0xFFFFC107),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.roboto(
              color: const Color(0xFF475569),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

/// Daily Accuracy progress bar (replaces the old screen-time/goal bars).
class _AccuracyBar extends StatelessWidget {
  final int accuracyPercent; // 0-100

  const _AccuracyBar({required this.accuracyPercent});

  @override
  Widget build(BuildContext context) {
    final fraction = (accuracyPercent / 100.0).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label — always above bar, never hidden behind it
        Text(
          'Daily Accuracy: $accuracyPercent%',
          style: GoogleFonts.roboto(
            color: const Color(0xFF1E293B),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        // Track + fill
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            height: 10,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final fillW = constraints.maxWidth * fraction;
                return Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      color: const Color(0xFFE2E8F0), // track
                    ),
                    Container(
                      width: fillW,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2196F3), // fill
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
