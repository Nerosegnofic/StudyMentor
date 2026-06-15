import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../domain/models/skill_progress_model.dart';
import '../../../../l10n/app_localizations.dart';

class AllSkillsScreen extends StatefulWidget {
  final List<SkillProgressModel> skills;
  final String studentUid;
  final String subjectKey;

  const AllSkillsScreen({
    super.key,
    required this.skills,
    required this.studentUid,
    required this.subjectKey,
  });

  @override
  State<AllSkillsScreen> createState() => _AllSkillsScreenState();
}

class _AllSkillsScreenState extends State<AllSkillsScreen> {
  String _sortMethod = 'masteryLowestFirst';

  List<SkillProgressModel> get _sortedSkills {
    final list = List<SkillProgressModel>.from(widget.skills);
    if (_sortMethod == 'masteryHighestFirst') {
      list.sort((a, b) => b.masteryPercent.compareTo(a.masteryPercent));
    } else if (_sortMethod == 'aToZ') {
      list.sort((a, b) => a.skillKey.compareTo(b.skillKey));
    } else {
      // masteryLowestFirst (default)
      list.sort((a, b) => a.masteryPercent.compareTo(b.masteryPercent));
    }
    return list;
  }

  ({String label, Color bgColor, Color textColor}) _masteryTier(int pct) {
    final loc = AppLocalizations.of(context);
    if (pct >= 80) {
      return (
        label: loc.masteryTierAdvanced,
        bgColor: const Color(0xFFBBDEFB),
        textColor: const Color(0xFF0D47A1)
      );
    }
    if (pct >= 60) {
      return (
        label: loc.masteryTierProficient,
        bgColor: const Color(0xFFB2DFDB),
        textColor: const Color(0xFF00695C)
      );
    }
    if (pct >= 40) {
      return (
        label: loc.masteryTierDeveloping,
        bgColor: const Color(0xFFFFE0B2),
        textColor: const Color(0xFFBF360C)
      );
    }
    return (
      label: loc.masteryTierBeginner,
      bgColor: const Color(0xFFFFCDD2),
      textColor: const Color(0xFFC62828)
    );
  }

  Color _borderColor(double pct) {
    if (pct >= 80) return const Color(0xFF0D47A1);
    if (pct >= 60) return const Color(0xFF00695C);
    if (pct >= 40) return const Color(0xFFBF360C);
    return const Color(0xFFC62828);
  }

  String _recommendation(SkillProgressModel skill) {
    final loc = AppLocalizations.of(context);
    if (skill.totalAttempts == 0) {
      return loc.recommendationNotStarted;
    }
    final pct = skill.masteryPercent;
    if (pct < 30) {
      return loc.recommendationUrgent;
    }
    if (pct < 50) {
      return loc.recommendationProgress;
    }
    if (pct < 75) {
      return loc.recommendationOnTrack;
    }
    return loc.recommendationStrong;
  }

  void _showSortModal() {
    final loc = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                loc.sortSkillsTitle,
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 16),
              _buildSortOption(ctx, 'masteryLowestFirst', loc.sortMasteryLowestFirst),
              _buildSortOption(ctx, 'masteryHighestFirst', loc.sortMasteryHighestFirst),
              _buildSortOption(ctx, 'aToZ', loc.sortAZLabel),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOption(BuildContext ctx, String optionValue, String optionLabel) {
    final bool isSelected = _sortMethod == optionValue;
    return InkWell(
      onTap: () {
        setState(() => _sortMethod = optionValue);
        Navigator.of(ctx).pop();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: const BoxDecoration(
          border:
              Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              optionLabel,
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal,
                color: const Color(0xFF1E293B),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check, color: Color(0xFF2196F3), size: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final skills = _sortedSkills;
    final advancedCount =
        widget.skills.where((s) => s.masteryPercent >= 80).length;
    final proficientCount = widget.skills
        .where((s) => s.masteryPercent >= 60 && s.masteryPercent < 80)
        .length;
    final developingCount = widget.skills
        .where((s) => s.masteryPercent >= 40 && s.masteryPercent < 60)
        .length;
    final beginnerCount = widget.skills
        .where((s) => s.masteryPercent < 40)
        .length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          _buildHeader(context),
          _buildStatStrip(
            advancedCount: advancedCount,
            proficientCount: proficientCount,
            developingCount: developingCount,
            beginnerCount: beginnerCount,
          ),
          Expanded(
            child: ListView.builder(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: skills.length,
              itemBuilder: (_, i) {
                final skill = skills[i];
                return _SkillDetailCard(
                  skill: skill,
                  masteryTier: _masteryTier(skill.masteryPercent.round()),
                  borderColor: _borderColor(skill.masteryPercent),
                  recommendation: _recommendation(skill),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatStrip({
    required int advancedCount,
    required int proficientCount,
    required int developingCount,
    required int beginnerCount,
  }) {
    final loc = AppLocalizations.of(context);
    final stats = <({int count, String label, Color color})>[
      (count: widget.skills.length, label: loc.statTotalLabel, color: const Color(0xFF1565C0)),
      if (advancedCount > 0)
        (count: advancedCount, label: loc.masteryTierAdvanced, color: const Color(0xFF1565C0)),
      if (proficientCount > 0)
        (count: proficientCount, label: loc.masteryTierProficient, color: const Color(0xFF00897B)),
      if (developingCount > 0)
        (count: developingCount, label: loc.masteryTierDeveloping, color: const Color(0xFFE65100)),
      if (beginnerCount > 0)
        (count: beginnerCount, label: loc.masteryTierBeginner, color: const Color(0xFFE53935)),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            for (int i = 0; i < stats.length; i++) ...[
              if (i > 0)
                Container(
                    width: 1,
                    color: const Color(0xFFE2E8F0)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${stats[i].count}',
                        style: GoogleFonts.cairo(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: stats[i].color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        stats[i].label,
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          color: const Color(0xFF94A3B8),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: const Color(0xFF2196F3),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        bottom: 16,
        left: 16,
        right: 16,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Text(
            AppLocalizations.of(context).allSkillsTitle,
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.sort, color: Colors.white),
            onPressed: _showSortModal,
          ),
        ],
      ),
    );
  }
}

class _SkillDetailCard extends StatelessWidget {
  final SkillProgressModel skill;
  final ({String label, Color bgColor, Color textColor}) masteryTier;
  final Color borderColor;
  final String recommendation;

  const _SkillDetailCard({
    required this.skill,
    required this.masteryTier,
    required this.borderColor,
    required this.recommendation,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final accuracy = skill.totalAttempts > 0
        ? ((skill.correctAnswers / skill.totalAttempts) * 100).round()
        : 0;
    final lastPracticed = skill.lastPracticedAt != null
        ? '${skill.lastPracticedAt!.month}/${skill.lastPracticedAt!.day}/${skill.lastPracticedAt!.year}'
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: BorderDirectional(start: BorderSide(width: 4, color: borderColor)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.05),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  skill.skillKey,
                  textDirection: TextDirection.rtl,
                  style: GoogleFonts.cairo(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: masteryTier.bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  masteryTier.label,
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: masteryTier.textColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (_, constraints) => Stack(
              children: [
                Container(
                  width: constraints.maxWidth,
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOut,
                  width: constraints.maxWidth * (accuracy / 100),
                  height: 8,
                  decoration: BoxDecoration(
                    color: borderColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                loc.correctOfAttemptsLabel(skill.correctAnswers, skill.totalAttempts),
                style: GoogleFonts.cairo(
                    fontSize: 12, color: const Color(0xFF64748B)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: masteryTier.bgColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$accuracy%',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: masteryTier.textColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            lastPracticed != null
                ? loc.lastPracticedLabel(lastPracticed)
                : loc.neverPracticedLabel,
            style: GoogleFonts.cairo(
                fontSize: 11, color: const Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border(
                left: BorderSide(width: 3, color: borderColor),
              ),
            ),
            child: Text(
              recommendation,
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: const Color(0xFF475569),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
