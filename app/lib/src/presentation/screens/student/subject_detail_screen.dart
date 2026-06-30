import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/repositories/ai_engine_repository.dart';
import '../../../data/providers/dataconnect_provider.dart';
import '../../../domain/models/skill_detail_model.dart';
import '../../../utils/growth_stage_utils.dart';
import '../../widgets/plant_widget.dart';
import 'student_quiz.dart';
import '../../../domain/models/gamification_enums.dart';
import '../../../bloc/gamification/gamification_bloc.dart';
import '../../../domain/models/app_config_model.dart';
import '../../../domain/models/quiz_count.dart';
import '../../../bloc/auth/auth_bloc.dart';
import '../../../bloc/garden/garden_bloc.dart';
import '../../../bloc/garden/garden_state.dart';
import '../../../features/mascot/mascot_state.dart';
import '../../../features/mascot/mascot_with_bubble.dart';
import '../../../../l10n/app_localizations.dart';

// ── Design tokens (Study Mentor student palette) ─────────────────────────────
const _cloud = Color(0xFFF5F7FA); // scaffold background (Soft Cloud)
const _green = Color(0xFF4CAF50); // primary action / growth
const _greenDark = Color(0xFF43A047); // hero gradient top
const _greenLight = Color(0xFFE8F5E9); // progress-track / chip fills
const _ink = Color(0xFF1F2937); // primary text
const _muted = Color(0xFF8B93A7); // secondary text
const _danger = Color(0xFFEA4335); // weaknesses / needs-practice

class SubjectDetailScreen extends StatefulWidget {
  final String studentUid;

  final int subjectId;
  final String subjectName;
  final double masteryPercent;

  /// Optional override — injected in tests to avoid the Firebase singleton.
  final AiEngineRepository? repository;

  const SubjectDetailScreen({
    super.key,
    required this.studentUid,
    required this.subjectId,
    required this.subjectName,
    required this.masteryPercent,
    this.repository,
  });

  @override
  State<SubjectDetailScreen> createState() => _SubjectDetailScreenState();
}

class _SubjectDetailScreenState extends State<SubjectDetailScreen> {
  late AiEngineRepository _repo;
  late Future<List<SkillDetailModel>> _skillsFuture;
  StudentConfigModel _config = const StudentConfigModel();
  late double _masteryPercent;

  /// Student's grade level (set by the parent) — used to size generated quizzes.
  /// Null until loaded; falls back to 5 in the quiz request.
  int? _studentGrade;

  /// Ingestion state for THIS subject ("processing" | "ready" | "failed"), or null
  /// when there are no documents / not yet loaded. Drives the Practice gate so the
  /// student can't launch a quiz while the curriculum is still being prepared.
  String? _subjectState;

  /// Bounded poll that runs ONLY while this subject is still `processing`, so the
  /// Practice button flips from "Preparing…" to enabled live (no need to leave/re-open
  /// the screen). Cancelled as soon as the subject is no longer processing, and on dispose.
  Timer? _statusPoll;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? AiEngineRepository.instance;
    _masteryPercent = widget.masteryPercent;
    _skillsFuture = _repo.getSubjectSkills(widget.subjectId);
    _loadConfig();
    _loadGrade();
    _loadSubjectState();
  }

  @override
  void dispose() {
    _statusPoll?.cancel();
    super.dispose();
  }

  Future<void> _loadSubjectState() async {
    try {
      // Student side → no studentUid (the JWT uid is the student).
      final statuses = await _repo.getSubjectsStatus();
      if (!mounted) return;
      final match = statuses.where((s) => s.subjectId == widget.subjectId);
      final newState = match.isEmpty ? null : match.first.state;
      setState(() => _subjectState = newState);

      // Keep polling while preparing; stop the moment it's ready/failed/absent.
      if (newState == 'processing') {
        _statusPoll ??= Timer.periodic(
          const Duration(seconds: 12),
          (_) => _loadSubjectState(),
        );
      } else {
        _statusPoll?.cancel();
        _statusPoll = null;
      }
    } catch (_) {
      // Best-effort gate; on failure leave Practice enabled (server 409 is the backstop).
    }
  }

  Future<void> _loadGrade() async {
    try {
      final profile = await DataConnectProvider().getStudentProfile(widget.studentUid);
      if (mounted) {
        setState(() => _studentGrade = profile['grade_level'] as int?);
      }
    } catch (_) {}
  }

  Future<void> _loadConfig() async {
    try {
      final repo = context.read<AuthBloc>().repository;
      final (:config, :rules) = await repo.getAppConfigForStudent(widget.studentUid);
      if (mounted && config != null) {
        setState(() {
          _config = config;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final stage = GrowthStageUtils.fromMastery(_masteryPercent);

    return BlocListener<GardenBloc, GardenState>(
      listener: (context, state) {
        if (state is GardenLoaded) {
          final plant = state.plants.where((p) => p.subjectId == widget.subjectId).firstOrNull;
          // Only refetch skills when this subject's mastery actually changed —
          // the garden bloc can re-emit GardenLoaded for unrelated reasons.
          if (plant != null &&
              mounted &&
              plant.masteryPercent != _masteryPercent) {
            setState(() {
              _masteryPercent = plant.masteryPercent;
              _skillsFuture = _repo.getSubjectSkills(widget.subjectId);
            });
          }
        }
      },
      child: Scaffold(
        backgroundColor: _cloud,
        // Immersive gradient hero (flat bottom) replaces the AppBar + plant hero.
        // The header depends only on already-available state, so it paints
        // immediately; only the skills sections wait on the network (see the
        // FutureBuilder in _buildContent).
        body: Column(
          children: [
            _HeroHeader(
              title: loc.subjectGardenTitle(widget.subjectName),
              stage: stage,
              masteryPercent: _masteryPercent,
              onBack: () => Navigator.of(context).maybePop(),
            ),
            Expanded(child: _buildContent(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Growth progress card ──────────────────────────────────────────
          _buildGrowthProgressCard(loc, _masteryPercent),
          const SizedBox(height: 12),

          // ── Mastery card ─────────────────────────────────────────────────
          _Card(
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: GrowthStageUtils.healthColor(_masteryPercent)
                        .withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _masteryPercent >= 75
                        ? Icons.local_florist_rounded
                        : _masteryPercent >= 50
                            ? Icons.spa_rounded
                            : Icons.energy_savings_leaf_rounded,
                    color: GrowthStageUtils.healthColor(_masteryPercent),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _masteryLabel(loc, _masteryPercent),
                        style: GoogleFonts.cairo(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: GrowthStageUtils.healthColor(_masteryPercent),
                        ),
                      ),
                      Text(
                        loc.overallMasteryLabel(_masteryPercent.toStringAsFixed(0)),
                        style: GoogleFonts.cairo(fontSize: 12, color: _muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Skills sections (the only part that waits on the network) ─────
          _buildSkillsSection(context, loc),

          // ── Practice CTA ─────────────────────────────────────────────────
          // Gated while the subject's curriculum is still ingesting: the student
          // can't start a quiz before skills exist. The server 409 is the backstop.
          Builder(builder: (context) {
            final isPreparing = _subjectState == 'processing';
            return SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: isPreparing
                    ? null
                    : () async {
                        final gamificationBloc = context.read<GamificationBloc>();
                        final gardenBloc = context.read<GardenBloc>();
                        // Voluntary practice quizzes never grant reward time —
                        // only forced quizzes unlock app time. XP/coins/mastery
                        // are still awarded server-side on submission, so the
                        // quiz result is not needed here.
                        await Navigator.of(context).push<bool?>(
                          MaterialPageRoute<bool?>(
                            fullscreenDialog: true,
                            builder: (_) => MultiBlocProvider(
                              providers: [
                                BlocProvider.value(value: gamificationBloc),
                                BlocProvider.value(value: gardenBloc),
                              ],
                              child: QuizOverlayPage(
                                repository: _repo,
                                studentId: widget.studentUid,
                                contextType: QuizContext.voluntary,
                                subjectId: widget.subjectId,
                                studentGrade: _studentGrade,
                                totalQuestions: switch (_config.quizCount) {
                                  Auto() => 5,
                                  Fixed(:final count) => count,
                                },
                                autoLength: _config.quizCount is Auto,
                              ),
                            ),
                          ),
                        );
                        // Refresh the skills list so updated mastery shows.
                        if (mounted) {
                          setState(() {
                            _skillsFuture = _repo.getSubjectSkills(widget.subjectId);
                          });
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFCED4DA),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                icon: Icon(
                  isPreparing ? Icons.hourglass_top_rounded : Icons.play_arrow_rounded,
                  size: 22,
                ),
                label: Text(
                  isPreparing
                      ? loc.subjectPreparingPracticeDisabled
                      : loc.practiceNowButton,
                  style: GoogleFonts.cairo(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  /// The all-skills / strengths / weaknesses sections — the only part of the
  /// screen that depends on the networked skills fetch. Wrapped in its own
  /// FutureBuilder so the hero, growth, mastery, and Practice CTA above paint
  /// immediately while the list loads.
  Widget _buildSkillsSection(BuildContext context, AppLocalizations loc) {
    return FutureBuilder<List<SkillDetailModel>>(
      future: _skillsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 28),
            child: Center(
                child: CircularProgressIndicator(strokeWidth: 2, color: _green)),
          );
        }
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: MascotWithBubble(
              state: MascotState.sad,
              message: loc.loadSkillsErrorMessage,
            ),
          );
        }

        final skills = snapshot.data ?? [];
        final strongSkills = skills.where((s) => s.isStrong).toList();
        final weakSkills = skills.where((s) => s.isWeak).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Skills overview ──────────────────────────────────────────
            if (skills.isNotEmpty) ...[
              Text(
                loc.skillsTitle,
                style: GoogleFonts.cairo(
                    fontSize: 16, fontWeight: FontWeight.w800, color: _ink),
              ),
              const SizedBox(height: 12),
              ...skills.map((s) => _SkillRow(skill: s)),
              const SizedBox(height: 20),
            ],

            // ── Strengths ────────────────────────────────────────────────
            if (strongSkills.isNotEmpty) ...[
              _SectionHeader(
                  icon: Icons.star_rounded,
                  label: loc.strengthsTitle,
                  color: _green),
              const SizedBox(height: 8),
              _SkillChipRow(skills: strongSkills, color: _green),
              const SizedBox(height: 18),
            ],

            // ── Weaknesses ───────────────────────────────────────────────
            if (weakSkills.isNotEmpty) ...[
              _SectionHeader(
                  icon: Icons.fitness_center_rounded,
                  label: loc.needsPracticeTitle,
                  color: _danger),
              const SizedBox(height: 8),
              _SkillChipRow(skills: weakSkills, color: _danger),
              const SizedBox(height: 24),
            ],
          ],
        );
      },
    );
  }

  Widget _buildGrowthProgressCard(AppLocalizations loc, double mastery) {
    const levelStep = 20.0; // 100% / 5 levels
    final currentLevel = (mastery / levelStep).floor().clamp(0, 4) + 1;
    final isMax = currentLevel >= 5;
    final levelStart = (currentLevel - 1) * levelStep;
    final levelEnd = currentLevel * levelStep;
    final progress = isMax ? 1.0 : ((mastery - levelStart) / levelStep).clamp(0.0, 1.0);
    final remaining = (levelEnd - mastery).clamp(0.0, levelStep);

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                loc.growthProgressTitle,
                style: GoogleFonts.cairo(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                ),
              ),
              _LevelPill(label: loc.levelNumberLabel(currentLevel)),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: _greenLight,
              valueColor: const AlwaysStoppedAnimation<Color>(_green),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${mastery.toStringAsFixed(0)}%',
                style: GoogleFonts.cairo(fontSize: 12, color: _muted),
              ),
              if (!isMax)
                Text(
                  '${levelEnd.toStringAsFixed(0)}%',
                  style: GoogleFonts.cairo(fontSize: 12, color: _muted),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            isMax
                ? loc.maxLevelReachedMessage
                : loc.percentMoreToLevelMessage(remaining.toStringAsFixed(0), currentLevel + 1),
            style: GoogleFonts.cairo(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _green,
            ),
          ),
        ],
      ),
    );
  }

  static String _masteryLabel(AppLocalizations loc, double mastery) {
    if (mastery >= 80) return loc.flourishingLabel;
    if (mastery >= 60) return loc.masteryGrowingWellLabel;
    if (mastery >= 40) return loc.masteryMakingProgressLabel;
    if (mastery > 0)   return loc.masteryJustStartedLabel;
    return loc.masteryNotStartedYetLabel;
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Full-bleed gradient hero band with a flat bottom edge. Carries the back
/// button, subject title, the growth-stage plant, and stage/mastery chips —
/// replacing both the old AppBar and the separate plant card.
class _HeroHeader extends StatelessWidget {
  final String title;
  final GrowthStage stage;
  final double masteryPercent;
  final VoidCallback onBack;

  const _HeroHeader({
    required this.title,
    required this.stage,
    required this.masteryPercent,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_greenDark, _green],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 16),
          child: Column(
            children: [
              // Back button + centered title.
              Row(
                children: [
                  IconButton(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 18),
                    tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  ),
                  Expanded(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // balances the back button
                ],
              ),
              const SizedBox(height: 4),
              // Plant + stage/mastery chips. The stack is full-width and the
              // chips are inset by 8 on top of the header's 8px padding (= 16px
              // total) so their outer edges line up with the body cards below.
              SizedBox(
                width: double.infinity,
                height: 150,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PlantWidget(stage: stage, size: 140),
                    Positioned(
                      top: 0,
                      left: 8,
                      child: _GlassChip(text: stage.label(loc)),
                    ),
                    Positioned(
                      top: 0,
                      right: 8,
                      child: _GlassChip(text: '${masteryPercent.toStringAsFixed(0)}%'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Translucent-white pill used for the stage/mastery badges on the green hero.
class _GlassChip extends StatelessWidget {
  final String text;
  const _GlassChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: GoogleFonts.cairo(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Soft-amber level pill matching the rank card's gamification accent.
class _LevelPill extends StatelessWidget {
  final String label;
  const _LevelPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFE082)),
      ),
      child: Text(
        label,
        style: GoogleFonts.cairo(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF8D6E00),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SectionHeader(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Text(label,
            style: GoogleFonts.cairo(
                fontSize: 15, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}

class _SkillRow extends StatelessWidget {
  final SkillDetailModel skill;
  const _SkillRow({required this.skill});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final healthColor = GrowthStageUtils.healthColor(skill.masteryPercent);
    final attempted = !skill.isUntouched;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: attempted
              ? healthColor.withValues(alpha: 0.3)
              : const Color(0xFFE3E8EF),
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 1)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: attempted
                  ? healthColor.withValues(alpha: 0.12)
                  : const Color(0xFFF1F3F7),
              shape: BoxShape.circle,
            ),
            child: Icon(
              attempted
                  ? (skill.isStrong
                      ? Icons.emoji_events_rounded
                      : skill.isWeak
                          ? Icons.fitness_center_rounded
                          : Icons.trending_up_rounded)
                  : Icons.lock_outline_rounded,
              color: attempted ? healthColor : Colors.grey.shade400,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  skill.name,
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: attempted ? _ink : Colors.grey.shade400,
                  ),
                ),
                if (attempted)
                  Text(
                    loc.masteryAttemptsLabel(
                        skill.masteryPercent.toStringAsFixed(0), skill.attempts),
                    style: GoogleFonts.cairo(fontSize: 11, color: _muted),
                  )
                else
                  Text(loc.skillNotStartedLabel,
                      style: GoogleFonts.cairo(
                          fontSize: 11, color: Colors.grey.shade400)),
              ],
            ),
          ),
          if (attempted)
            Text(
              '${skill.masteryPercent.toStringAsFixed(0)}%',
              style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: healthColor),
            ),
        ],
      ),
    );
  }
}

class _SkillChipRow extends StatelessWidget {
  final List<SkillDetailModel> skills;
  final Color color;
  const _SkillChipRow({required this.skills, required this.color});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: skills
          .map((s) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Text(
                  s.name,
                  style: GoogleFonts.cairo(
                      fontSize: 11,
                      color: color,
                      fontWeight: FontWeight.w600),
                ),
              ))
          .toList(),
    );
  }
}
