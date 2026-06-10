import 'package:flutter/material.dart';
import '../../../data/repositories/ai_engine_repository.dart';
import '../../../domain/models/skill_detail_model.dart';
import '../../../utils/growth_stage_utils.dart';
import '../../widgets/plant_widget.dart';
import 'student_quiz.dart';

const _kGreen = Color(0xFF2E7D32);
const _kGreenLight = Color(0xFFE8F5E9);

class SubjectDetailScreen extends StatefulWidget {
  final String studentUid;
  final int subjectId;
  final String subjectName;
  final double masteryPercent;

  const SubjectDetailScreen({
    super.key,
    required this.studentUid,
    required this.subjectId,
    required this.subjectName,
    required this.masteryPercent,
  });

  @override
  State<SubjectDetailScreen> createState() => _SubjectDetailScreenState();
}

class _SubjectDetailScreenState extends State<SubjectDetailScreen> {
  late Future<List<SkillDetailModel>> _skillsFuture;

  @override
  void initState() {
    super.initState();
    _skillsFuture = AiEngineRepository.instance.getSubjectSkills(widget.subjectId);
  }

  @override
  Widget build(BuildContext context) {
    final stage = GrowthStageUtils.fromMastery(widget.masteryPercent);

    return Scaffold(
      backgroundColor: _kGreenLight,
      appBar: AppBar(
        backgroundColor: _kGreenLight,
        elevation: 0,
        title: Text(
          '${widget.subjectName} Garden',
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
            return const Center(child: CircularProgressIndicator(color: _kGreen));
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load skills.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }
          final skills = snapshot.data ?? [];
          return _buildContent(context, stage, skills);
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    GrowthStage stage,
    List<SkillDetailModel> skills,
  ) {
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
            masteryPercent: widget.masteryPercent,
          ),
          const SizedBox(height: 20),

          // ── Growth progress card ──────────────────────────────────────────
          _buildGrowthProgressCard(widget.masteryPercent),
          const SizedBox(height: 12),

          // ── Mastery card ─────────────────────────────────────────────────
          _Card(
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: GrowthStageUtils.healthColor(widget.masteryPercent)
                        .withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.masteryPercent >= 75
                        ? Icons.local_florist_rounded
                        : widget.masteryPercent >= 50
                            ? Icons.spa_rounded
                            : Icons.energy_savings_leaf_rounded,
                    color: GrowthStageUtils.healthColor(widget.masteryPercent),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _masteryLabel(widget.masteryPercent),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: GrowthStageUtils.healthColor(widget.masteryPercent),
                      ),
                    ),
                    Text(
                      'Overall mastery: ${widget.masteryPercent.toStringAsFixed(0)}%',
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
              style: TextStyle(
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
                label: 'Strengths',
                color: const Color(0xFF34A853)),
            const SizedBox(height: 8),
            _SkillChipRow(skills: strongSkills, color: const Color(0xFF34A853)),
            const SizedBox(height: 18),
          ],

          // ── Weaknesses ────────────────────────────────────────────────────
          if (weakSkills.isNotEmpty) ...[
            _SectionHeader(
                icon: Icons.fitness_center_rounded,
                label: 'Needs Practice',
                color: const Color(0xFFEA4335)),
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
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    fullscreenDialog: true,
                    builder: (_) => QuizOverlayPage(
                      repository: AiEngineRepository.instance,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _kGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              icon: const Icon(Icons.play_arrow_rounded, size: 22),
              label: const Text(
                'Practice Now',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrowthProgressCard(double mastery) {
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
              const Text(
                'Growth Progress',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Level $currentLevel  ',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                    ),
                    TextSpan(
                      text: isMax ? 'MAX ✨' : 'Level ${currentLevel + 1}',
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
                ? 'You\'ve reached the maximum level! 🌟'
                : '${remaining.toStringAsFixed(0)}% more to reach Level ${currentLevel + 1}!',
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

  static String _masteryLabel(double mastery) {
    if (mastery >= 80) return 'Flourishing';
    if (mastery >= 60) return 'Growing Well';
    if (mastery >= 40) return 'Making Progress';
    if (mastery >= 20) return 'Just Started';
    return 'Not Started Yet';
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
                stage.label,
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
                    .withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: GrowthStageUtils.healthColor(masteryPercent)
                      .withOpacity(0.4),
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
              ? healthColor.withOpacity(0.3)
              : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
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
                  ? healthColor.withOpacity(0.12)
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
                    '${skill.masteryPercent.toStringAsFixed(0)}% mastery  ·  ${skill.attempts} attempts',
                    style:
                        TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  )
                else
                  Text('Not started yet',
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
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withOpacity(0.3)),
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
