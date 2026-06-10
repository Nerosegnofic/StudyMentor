import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/garden/garden_bloc.dart';
import '../../../bloc/garden/garden_event.dart';
import '../../../bloc/garden/garden_state.dart';
import '../../../data/catalog/subject_catalog.dart';
import '../../../data/catalog/subject_metadata_registry.dart' as meta;
import '../../../domain/models/skill_progress_model.dart';
import '../../../domain/models/subject_progress_model.dart';
import '../../../services/mastery_service.dart';
import '../../../utils/growth_stage_utils.dart';
import '../../../utils/subject_xp_engine.dart';
import '../../../data/repositories/ai_engine_repository.dart';
import '../../widgets/plant_widget.dart';
import 'student_quiz.dart';
import '../../../domain/models/gamification_enums.dart';
import '../../../bloc/gamification/gamification_bloc.dart';
import '../../../domain/models/app_config_model.dart';
import '../../../domain/models/quiz_count.dart';
import '../../../bloc/auth/auth_bloc.dart';

/// Full detail page for a single subject — plant, XP, skills, strengths/weaknesses.
/// "Recent Performance" and charts are intentionally excluded from this version.
class SubjectDetailScreen extends StatefulWidget {
  final String studentUid;
  final String subjectKey;

  const SubjectDetailScreen({
    super.key,
    required this.studentUid,
    required this.subjectKey,
  });

  @override
  State<SubjectDetailScreen> createState() => _SubjectDetailScreenState();
}

class _SubjectDetailScreenState extends State<SubjectDetailScreen> {
  StudentConfigModel _config = const StudentConfigModel();

  @override
  void initState() {
    super.initState();
    context.read<GardenBloc>().add(
      LoadSubjectSkillsRequested(
        studentUid: widget.studentUid,
        subjectKey: widget.subjectKey,
      ),
    );
    _loadConfig();
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
    final subject = meta.SubjectMetadataRegistry.getDefinition(widget.subjectKey);

    return Scaffold(
      backgroundColor: subject.lightColor,
      appBar: AppBar(
        backgroundColor: subject.lightColor,
        elevation: 0,
        title: Text(
          '${subject.name} Garden',
          style: TextStyle(
            color: subject.primaryColor,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        iconTheme: IconThemeData(color: subject.primaryColor),
      ),
      body: BlocBuilder<GardenBloc, GardenState>(
        builder: (context, state) {
          if (state is GardenLoading) {
            return Center(
              child: CircularProgressIndicator(color: subject.primaryColor),
            );
          }
          if (state is GardenError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load data.\n${state.message}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }
          if (state is SubjectSkillsLoaded && state.subjectKey == widget.subjectKey) {
            return _buildContent(context, subject, state.progress, state.skills);
          }
          // Fallback: still loading or different subject key in state
          return Center(child: CircularProgressIndicator(color: subject.primaryColor));
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    meta.SubjectDefinition subject,
    SubjectProgressModel progress,
    List<SkillProgressModel> skills,
  ) {
    final stage = GrowthStageUtils.fromLevel(progress.level);
    final progressFraction = SubjectXpEngine.levelProgress(progress.totalXp);
    final xpToNext = SubjectXpEngine.xpToNextLevel(progress.totalXp);
    final nextLevel = SubjectXpEngine.xpForNextLevel(progress.level);
    final overallMastery = MasteryService.overallMastery(skills);
    final strongSkills = MasteryService.strongSkills(skills);
    final weakSkills = MasteryService.weakSkills(skills);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Plant hero ──────────────────────────────────────────────────
          _PlantHeroSection(subject: subject, stage: stage, mastery: overallMastery),
          const SizedBox(height: 20),

          // ── Growth Progress card ─────────────────────────────────────────
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Growth Progress',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 13),
                        children: [
                          TextSpan(
                            text: 'Level ${progress.level}',
                            style: const TextStyle(color: Color(0xFF8B93A7)),
                          ),
                          const TextSpan(text: '  →  '),
                          TextSpan(
                            text: 'Level ${progress.level + 1}',
                            style: TextStyle(
                              color: subject.primaryColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progressFraction,
                    minHeight: 14,
                    backgroundColor: subject.primaryColor.withOpacity(0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(subject.primaryColor),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${progress.totalXp} XP',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                    if (nextLevel != null)
                      Text(
                        '${nextLevel} XP',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                  ],
                ),
                if (xpToNext > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '$xpToNext XP more to reach the next level!',
                      style: TextStyle(
                        fontSize: 12,
                        color: subject.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Mastery health ───────────────────────────────────────────────
          _Card(
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: GrowthStageUtils.healthColor(overallMastery).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    overallMastery >= 75
                        ? Icons.local_florist_rounded
                        : overallMastery >= 50
                            ? Icons.spa_rounded
                            : Icons.energy_savings_leaf_rounded,
                    color: GrowthStageUtils.healthColor(overallMastery),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      MasteryService.masteryLabel(overallMastery),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: GrowthStageUtils.healthColor(overallMastery),
                      ),
                    ),
                    Text(
                      'Overall mastery: ${overallMastery.toStringAsFixed(0)}%',
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
            const Text(
              'Skills',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)),
            ),
            const SizedBox(height: 12),
            ...skills.map((skill) => _SkillRow(skill: skill, subjectColor: subject.primaryColor)),
            const SizedBox(height: 20),
          ],

          // ── Strengths ─────────────────────────────────────────────────────
          if (strongSkills.isNotEmpty) ...[
            _SectionHeader(
              icon: Icons.star_rounded,
              label: 'Strengths',
              color: const Color(0xFF34A853),
            ),
            const SizedBox(height: 8),
            _SkillChipRow(skills: strongSkills, color: const Color(0xFF34A853)),
            const SizedBox(height: 18),
          ],

          // ── Weaknesses ────────────────────────────────────────────────────
          if (weakSkills.isNotEmpty) ...[
            _SectionHeader(
              icon: Icons.fitness_center_rounded,
              label: 'Needs Practice',
              color: const Color(0xFFEA4335),
            ),
            const SizedBox(height: 8),
            _SkillChipRow(skills: weakSkills, color: const Color(0xFFEA4335)),
            const SizedBox(height: 24),
          ],

          // ── Practice CTA ─────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () {
                final gamificationBloc = context.read<GamificationBloc>();
                final gardenBloc = context.read<GardenBloc>();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    fullscreenDialog: true,
                    builder: (_) => MultiBlocProvider(
                      providers: [
                        BlocProvider.value(value: gamificationBloc),
                        BlocProvider.value(value: gardenBloc),
                      ],
                      child: QuizOverlayPage(
                        repository: AiEngineRepository.instance,
                        studentId: widget.studentUid,
                        contextType: QuizContext.voluntary,
                        totalQuestions: switch (_config.quizCount) {
                          Auto() => 5,
                          Fixed(:final count) => count,
                        },
                      ),
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: subject.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              icon: const Icon(Icons.play_arrow_rounded, size: 22),
              label: const Text(
                'Practice Now',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Complete quizzes to earn XP and grow your plant!',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _PlantHeroSection extends StatelessWidget {
  final meta.SubjectDefinition subject;
  final GrowthStage stage;
  final double mastery;

  const _PlantHeroSection({required this.subject, required this.stage, required this.mastery});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: subject.lightColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          PlantWidget(
            plantType: PlantType.values.firstWhere(
              (e) => e.name == subject.defaultPlantType,
              orElse: () => PlantType.tree,
            ),
            stage: stage,
            primaryColor: subject.primaryColor,
            masteryPercent: mastery,
            size: 160,
          ),
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: subject.primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                stage.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
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
            color: Colors.black.withOpacity(0.05),
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
  const _SectionHeader({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color),
        ),
      ],
    );
  }
}

class _SkillRow extends StatelessWidget {
  final SkillProgressModel skill;
  final Color subjectColor;

  const _SkillRow({required this.skill, required this.subjectColor});

  @override
  Widget build(BuildContext context) {
    final mastery = skill.masteryPercent;
    final healthColor = GrowthStageUtils.healthColor(mastery);
    final name = SubjectCatalog.skillName(skill.skillKey);
    final attempted = skill.totalAttempts > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: attempted ? healthColor.withOpacity(0.3) : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: attempted ? healthColor.withOpacity(0.12) : Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              attempted
                  ? (skill.isStrong ? Icons.emoji_events_rounded : skill.isWeak ? Icons.fitness_center_rounded : Icons.trending_up_rounded)
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
                  name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: attempted ? const Color(0xFF1A1A2E) : Colors.grey.shade400,
                  ),
                ),
                if (attempted)
                  Text(
                    '${skill.correctAnswers}/${skill.totalAttempts} correct  ·  ${mastery.toStringAsFixed(0)}%',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  )
                else
                  Text(
                    'Not started yet',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                  ),
              ],
            ),
          ),
          if (attempted)
            SizedBox(
              width: 44,
              child: Column(
                children: [
                  Text(
                    '${mastery.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: healthColor,
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

class _SkillChipRow extends StatelessWidget {
  final List<SkillProgressModel> skills;
  final Color color;

  const _SkillChipRow({required this.skills, required this.color});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: skills
          .map((s) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Text(
                  SubjectCatalog.skillName(s.skillKey),
                  style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ))
          .toList(),
    );
  }
}
