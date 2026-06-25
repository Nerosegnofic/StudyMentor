import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
import '../../../features/mascot/mascot_loading_view.dart';
import '../../../../l10n/app_localizations.dart';

const _kGreen = Color(0xFF2E7D32);
const _kGreenLight = Color(0xFFE8F5E9);

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
          if (plant != null && mounted) {
            setState(() {
              _masteryPercent = plant.masteryPercent;
              _skillsFuture = _repo.getSubjectSkills(widget.subjectId);
            });
          }
        }
      },
      child: Scaffold(
        backgroundColor: _kGreenLight,
        appBar: AppBar(
          backgroundColor: _kGreenLight,
          elevation: 0,
          title: Text(
            loc.subjectGardenTitle(widget.subjectName),
            style: const TextStyle(
              color: _kGreen,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          iconTheme: const IconThemeData(color: _kGreen),
        ),
        body: FutureBuilder<List<SkillDetailModel>>(
          future: _skillsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: MascotLoadingView(message: loc.commonLoading),
              );
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: MascotWithBubble(
                    state: MascotState.sad,
                    message: loc.loadSkillsErrorMessage,
                  ),
                ),
              );
            }

            final skills = snapshot.data ?? [];
            return _buildContent(context, stage, skills);
          },
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    GrowthStage stage,
    List<SkillDetailModel> skills,
  ) {
    final loc = AppLocalizations.of(context);
    final strongSkills = skills.where((s) => s.isStrong).toList();
    final weakSkills = skills.where((s) => s.isWeak).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Plant hero ──────────────────────────────────────────────────
          _PlantHeroSection(

            subjectName: widget.subjectName,
            stage: stage,
            masteryPercent: _masteryPercent,
          ),
          const SizedBox(height: 20),

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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _masteryLabel(loc, _masteryPercent),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: GrowthStageUtils.healthColor(_masteryPercent),
                      ),
                    ),
                    Text(
                      loc.overallMasteryLabel(_masteryPercent.toStringAsFixed(0)),
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Skills overview ──────────────────────────────────────────────
          if (skills.isNotEmpty) ...[
            Text(
              loc.skillsTitle,
              style: const TextStyle(

                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E)),
            ),
            const SizedBox(height: 12),
            ...skills.map((s) => _SkillRow(skill: s)),

            const SizedBox(height: 20),
          ],

          // ── Strengths ─────────────────────────────────────────────────────
          if (strongSkills.isNotEmpty) ...[
            _SectionHeader(
                icon: Icons.star_rounded,
                label: loc.strengthsTitle,
                color: const Color(0xFF34A853)),
            const SizedBox(height: 8),
            _SkillChipRow(skills: strongSkills, color: const Color(0xFF34A853)),
            const SizedBox(height: 18),
          ],

          // ── Weaknesses ────────────────────────────────────────────────────
          if (weakSkills.isNotEmpty) ...[
            _SectionHeader(
                icon: Icons.fitness_center_rounded,
                label: loc.needsPracticeTitle,
                color: const Color(0xFFEA4335)),
            const SizedBox(height: 8),
            _SkillChipRow(skills: weakSkills, color: const Color(0xFFEA4335)),
            const SizedBox(height: 24),
          ],

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
                  backgroundColor: _kGreen,
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
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            );
          }),
        ],
      ),
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
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${loc.levelNumberLabel(currentLevel)}  ',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                    ),
                    TextSpan(
                      text: isMax ? loc.maxLevelBadge : loc.levelNumberLabel(currentLevel + 1),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _kGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(_kGreen),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${mastery.toStringAsFixed(0)}%',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
              if (!isMax)
                Text(
                  '${levelEnd.toStringAsFixed(0)}%',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            isMax
                ? loc.maxLevelReachedMessage
                : loc.percentMoreToLevelMessage(remaining.toStringAsFixed(0), currentLevel + 1),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _kGreen,
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

class _PlantHeroSection extends StatelessWidget {
  final String subjectName;
  final GrowthStage stage;
  final double masteryPercent;

  const _PlantHeroSection({

    required this.subjectName,
    required this.stage,
    required this.masteryPercent,

  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: _kGreenLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          PlantWidget(stage: stage, size: 160),
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _kGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                stage.label(loc),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: GrowthStageUtils.healthColor(masteryPercent)
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: GrowthStageUtils.healthColor(masteryPercent)
                      .withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                '${masteryPercent.toStringAsFixed(0)}%',
                style: TextStyle(
                  color: GrowthStageUtils.healthColor(masteryPercent),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
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
            style: TextStyle(
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: attempted
              ? healthColor.withValues(alpha: 0.3)
              : Colors.grey.shade200,
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
                  : Colors.grey.shade100,
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
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: attempted
                        ? const Color(0xFF1A1A2E)
                        : Colors.grey.shade400,
                  ),
                ),
                if (attempted)
                  Text(
                    loc.masteryAttemptsLabel(
                        skill.masteryPercent.toStringAsFixed(0), skill.attempts),
                    style:
                        TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  )
                else
                  Text(loc.skillNotStartedLabel,
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade400)),
              ],
            ),
          ),
          if (attempted)
            Text(
              '${skill.masteryPercent.toStringAsFixed(0)}%',
              style: TextStyle(
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
                  style: TextStyle(
                      fontSize: 11,
                      color: color,
                      fontWeight: FontWeight.w600),
                ),
              ))

          .toList(),
    );
  }
}
