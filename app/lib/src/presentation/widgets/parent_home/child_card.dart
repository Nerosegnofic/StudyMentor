import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/models/student_model.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../data/repositories/ai_engine_repository.dart';
import '../../../bloc/snapshot/snapshot_bloc.dart';
import '../../../bloc/snapshot/snapshot_event.dart';
import '../../../bloc/snapshot/snapshot_state.dart';

class ChildCard extends StatefulWidget {
  final StudentModel student;
  final VoidCallback? onTap;

  const ChildCard({super.key, required this.student, this.onTap});

  @override
  State<ChildCard> createState() => _ChildCardState();
}

class _ChildCardState extends State<ChildCard> {
  int _xp = 0;
  int _coins = 0;
  int _streakDays = 0;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadGamification();
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
        if (mounted) _loadGamification();
      });
    }
  }

  Future<void> _loadGamification() async {
    try {
      final profile = await AiEngineRepository.instance.getGamificationProfile(widget.student.uid);
      if (mounted) {
        setState(() {
          _xp = (profile['xp_total'] as int?) ?? 0;
          _coins = (profile['coins_total'] as int?) ?? 0;
          _streakDays = (profile['current_streak'] as int?) ?? 0;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final verified = widget.student.isEmailVerified;
    final initial = widget.student.fullName.isNotEmpty
        ? widget.student.fullName[0].toUpperCase()
        : '?';

    if (!verified) {
      return _buildUnverifiedCard(initial);
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: BlocProvider<SnapshotBloc>(
        create: (context) => SnapshotBloc(
          repository: context.read<AuthRepository>(),
        )..add(LoadDailySnapshotRequested(studentUid: widget.student.uid)),
        child: BlocBuilder<SnapshotBloc, SnapshotState>(
          builder: (context, state) {
            int quizzesPassed = 0;
            int studyTimeMinutes = 0;
            int dailyAccuracyPercent = 0;

            if (state is SnapshotLoaded) {
              quizzesPassed = state.snapshot.quizzesCompletedToday;
              studyTimeMinutes = state.snapshot.totalStudyTimeToday.inMinutes;
              dailyAccuracyPercent = state.snapshot.averageAccuracyToday;
            }

            return Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0D000000),
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
                          widget.student.fullName,
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
                          value: '$_xp XP',
                          label: 'Experience',
                        ),
                        _StatCol(
                          icon: Icons.local_fire_department_rounded,
                          value: '$_streakDays Days',
                          label: 'Streak',
                        ),
                        _StatCol(
                          icon: Icons.monetization_on_rounded,
                          value: '$_coins',
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
                        RichText(
                          text: TextSpan(
                            style: GoogleFonts.roboto(
                              color: const Color(0xFF475569),
                              fontSize: 13,
                            ),
                            children: [
                              const TextSpan(text: 'Quizzes Passed: '),
                              TextSpan(
                                text: '$quizzesPassed',
                                style: const TextStyle(
                                  color: Color(0xFF1E293B),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        RichText(
                          text: TextSpan(
                            style: GoogleFonts.roboto(
                              color: const Color(0xFF475569),
                              fontSize: 13,
                            ),
                            children: [
                              const TextSpan(text: 'Study Time: '),
                              TextSpan(
                                text: '$studyTimeMinutes mins',
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
                  _AccuracyBar(accuracyPercent: dailyAccuracyPercent),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Unverified card ────────────────────────────────────────────────────────

  Widget _buildUnverifiedCard(String initial) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 15),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2332),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2D3748), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: avatar + name + badge ──────────────────────────────────
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
                    fontSize: 18,
                  ),
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
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.student.email,
                      style: GoogleFonts.roboto(
                        color: const Color(0xFF4A5568),
                        fontSize: 11,
                      ),
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
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.mark_email_unread_outlined,
                      size: 12,
                      color: Color(0xFFFBBF24),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'UNVERIFIED',
                      style: GoogleFonts.roboto(
                        color: const Color(0xFFFBBF24),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(color: Color(0xFF2D3748), height: 1),
          const SizedBox(height: 14),

          // ── Status message ──────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.hourglass_top_rounded,
                size: 16,
                color: Color(0xFF64748B),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Waiting for the student to verify their email and log in for the first time.',
                  style: GoogleFonts.roboto(
                    color: const Color(0xFF64748B),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Coin teaser ─────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2D1A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF2D4A2D), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.monetization_on_rounded,
                  size: 15,
                  color: Color(0xFFFFC107),
                ),
                const SizedBox(width: 6),
                Text(
                  '+3 coins will be awarded on first login',
                  style: GoogleFonts.roboto(
                    color: const Color(0xFF86EFAC),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
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

class _AccuracyBar extends StatelessWidget {
  final int accuracyPercent;

  const _AccuracyBar({required this.accuracyPercent});

  @override
  Widget build(BuildContext context) {
    final fraction = (accuracyPercent / 100.0).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Daily Accuracy: $accuracyPercent%',
          style: GoogleFonts.roboto(
            color: const Color(0xFF1E293B),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
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
                      color: const Color(0xFFE2E8F0),
                    ),
                    Container(
                      width: fillW,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2196F3),
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
