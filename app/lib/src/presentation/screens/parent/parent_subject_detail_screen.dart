import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../bloc/subject_detail/subject_detail_bloc.dart';
import '../../../bloc/subject_detail/subject_detail_event.dart';
import '../../../bloc/subject_detail/subject_detail_state.dart';
import '../../../domain/models/quiz_attempt_model.dart';
import '../../../domain/models/skill_progress_model.dart';
import '../../../domain/models/subject_summary_model.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../widgets/quiz_history_card.dart';
import 'all_skills_screen.dart';
import 'all_quizzes_screen.dart';
import '../../../data/catalog/subject_metadata_registry.dart';
import '../../../../l10n/app_localizations.dart';
import '../../utils/error_localizer.dart';

const int _kPreviewQuizCount = 10;

class ParentSubjectDetailScreen extends StatefulWidget {
  final String studentUid;
  final int subjectId;
  final String subjectKey;
  final String subjectName;
  final Color color;

  const ParentSubjectDetailScreen({
    super.key,
    required this.studentUid,
    required this.subjectId,
    required this.subjectKey,
    required this.subjectName,
    required this.color,
  });

  @override
  State<ParentSubjectDetailScreen> createState() =>
      _ParentSubjectDetailScreenState();
}

class _ParentSubjectDetailScreenState
    extends State<ParentSubjectDetailScreen> {
  String _activeSortMethod = 'scoreLowestToHighest';

  ({String label, Color bgColor, Color textColor}) _masteryTier(int pct) {
    final loc = AppLocalizations.of(context);
    if (pct >= 80) {
      return (
        label: loc.masteryTierAdvanced,
        bgColor: const Color(0xFFE3F2FD),
        textColor: const Color(0xFF1565C0)
      );
    }
    if (pct >= 60) {
      return (
        label: loc.masteryTierProficient,
        bgColor: const Color(0xFFE0F2F1),
        textColor: const Color(0xFF00897B)
      );
    }
    if (pct >= 40) {
      return (
        label: loc.masteryTierDeveloping,
        bgColor: const Color(0xFFFFF3E0),
        textColor: const Color(0xFFE65100)
      );
    }
    return (
      label: loc.masteryTierBeginner,
      bgColor: const Color(0xFFFFEBEE),
      textColor: const Color(0xFFE53935)
    );
  }

  List<QuizAttemptModel> _sortQuizzes(List<QuizAttemptModel> quizzes) {
    final list = List<QuizAttemptModel>.from(quizzes);
    if (_activeSortMethod == 'dateNewestToOldest') {
      list.sort((a, b) => b.attemptedAt.compareTo(a.attemptedAt));
    } else if (_activeSortMethod == 'dateOldestToNewest') {
      list.sort((a, b) => a.attemptedAt.compareTo(b.attemptedAt));
    } else if (_activeSortMethod == 'scoreHighestToLowest') {
      list.sort((a, b) {
        final aR =
            a.totalQuestions > 0 ? a.correctAnswers / a.totalQuestions : 0.0;
        final bR =
            b.totalQuestions > 0 ? b.correctAnswers / b.totalQuestions : 0.0;
        return bR.compareTo(aR);
      });
    } else {
      // scoreLowestToHighest (default)
      list.sort((a, b) {
        final aR =
            a.totalQuestions > 0 ? a.correctAnswers / a.totalQuestions : 0.0;
        final bR =
            b.totalQuestions > 0 ? b.correctAnswers / b.totalQuestions : 0.0;
        return aR.compareTo(bR);
      });
    }
    return list;
  }

  void _showSortModal(BuildContext context) {
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
                loc.sortQuizzesTitle,
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 16),
              _buildSortOptionRow(
                  ctx, 'dateNewestToOldest', loc.sortDateNewestToOldest),
              _buildSortOptionRow(
                  ctx, 'dateOldestToNewest', loc.sortDateOldestToNewest),
              _buildSortOptionRow(
                  ctx, 'scoreHighestToLowest', loc.sortScoreHighestToLowest),
              _buildSortOptionRow(
                  ctx, 'scoreLowestToHighest', loc.sortScoreLowestToHighest),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOptionRow(
      BuildContext context, String optionValue, String optionLabel) {
    final bool isSelected = _activeSortMethod == optionValue;
    return InkWell(
      onTap: () {
        setState(() => _activeSortMethod = optionValue);
        Navigator.of(context).pop();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1),
          ),
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
    return BlocProvider<SubjectDetailBloc>(
      create: (_) => SubjectDetailBloc(
        authRepository: context.read<AuthRepository>(),
      )..add(LoadSubjectDetailRequested(
          studentUid: widget.studentUid,
          subjectId: widget.subjectId,
          subjectKey: widget.subjectKey,
        )),
      child: Builder(builder: (ctx) => _buildScaffold(ctx)),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: BlocBuilder<SubjectDetailBloc, SubjectDetailState>(
        builder: (context, state) {
          if (state is SubjectDetailLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is SubjectDetailError) {
            return Center(child: Text(localizeError(state.message, AppLocalizations.of(context))));
          }
          if (state is SubjectDetailLoaded) {
            return Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8, horizontal: 16),
                    children: [
                      _buildOverviewStatsCard(state.summary),
                      const SizedBox(height: 16),
                      _buildSkillsProgressCard(context, state.skills),
                      const SizedBox(height: 16),
                      _buildQuizHistorySection(context, state.recentQuizzes),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
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
            widget.subjectName,
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          CircleAvatar(
            backgroundColor: widget.color.withValues(alpha: 0.2),
            child: Icon(
              SubjectMetadataRegistry.getSubjectIcon(widget.subjectKey) ??
                  Icons.book,
              color: widget.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewStatsCard(SubjectSummaryModel summary) {
    final loc = AppLocalizations.of(context);
    final hours = summary.totalTimeSpent.inHours;
    final minutes = summary.totalTimeSpent.inMinutes % 60;
    final timeStr = hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';
    final tier = _masteryTier(summary.masteryPercent.round());

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.05),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatCol('${summary.accuracyPercent}%', loc.accuracyLabel),
              Container(
                  width: 1, height: 40, color: const Color(0xFFE2E8F0)),
              _buildStatCol(
                  '${summary.quizzesCompleted}', loc.quizzesDoneLabel),
              Container(
                  width: 1, height: 40, color: const Color(0xFFE2E8F0)),
              _buildStatCol(timeStr, loc.timeSpentLabel),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  loc.overallMasteryLevelLabel,
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${summary.masteryPercent}%',
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2196F3),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: tier.bgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        tier.label,
                        style: GoogleFonts.cairo(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: tier.textColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCol(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.cairo(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 12,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildSkillsProgressCard(
      BuildContext context, List<SkillProgressModel> skills) {
    final loc = AppLocalizations.of(context);
    // Weakest 3 attempted skills; fall back to first 3 if none attempted yet
    final attempted = skills
        .where((s) => s.totalAttempts > 0)
        .toList()
      ..sort((a, b) => a.masteryPercent.compareTo(b.masteryPercent));
    final preview =
        attempted.isEmpty ? skills.take(3).toList() : attempted.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.05),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                loc.skillsProgressTitle,
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AllSkillsScreen(
                      skills: skills,
                      studentUid: widget.studentUid,
                      subjectKey: widget.subjectKey,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      loc.seeAllLabel,
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2196F3),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_ios,
                        size: 12, color: Color(0xFF2196F3)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...preview.map((skill) {
            final accuracy = skill.totalAttempts > 0
                ? ((skill.correctAnswers / skill.totalAttempts) * 100).round()
                : 0;
            return _buildSkillRow(skill.skillKey, accuracy);
          }),
        ],
      ),
    );
  }

  Widget _buildSkillRow(String name, int score) {
    final bool failed = score < 50;
    final Color borderColor = score >= 75
        ? const Color(0xFF4CAF50)
        : score >= 50
            ? const Color(0xFFFFB300)
            : const Color(0xFFE53935);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          border: BorderDirectional(
              start: BorderSide(width: 3, color: borderColor)),
        ),
        padding: const EdgeInsetsDirectional.only(start: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    name,
                    textDirection: TextDirection.rtl,
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$score%',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: failed
                        ? const Color(0xFFE53935)
                        : const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (_, constraints) {
                return Stack(
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
                      width: constraints.maxWidth * (score / 100),
                      height: 8,
                      decoration: BoxDecoration(
                        color: failed
                            ? const Color(0xFFE53935)
                            : const Color(0xFF2196F3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizHistorySection(
      BuildContext context, List<QuizAttemptModel> recentQuizzes) {
    final loc = AppLocalizations.of(context);
    final sortedList = _sortQuizzes(recentQuizzes);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              loc.quizHistoryTitle,
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BlocProvider.value(
                        value: context.read<SubjectDetailBloc>(),
                        child: AllQuizzesScreen(quizzes: recentQuizzes),
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        loc.seeAllLabel,
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2196F3),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_ios,
                          size: 12, color: Color(0xFF2196F3)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon:
                      const Icon(Icons.sort, color: Color(0xFF64748B)),
                  onPressed: () => _showSortModal(context),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...sortedList.take(_kPreviewQuizCount).map((q) {
          final timeStr =
              '${q.attemptedAt.month}/${q.attemptedAt.day}/${q.attemptedAt.year}';
          final durationStr =
              '${q.duration.inMinutes}m ${q.duration.inSeconds % 60}s';
          final scoreStr = '${q.correctAnswers}/${q.totalQuestions}';

          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: QuizHistoryCard(
              quizAttemptId: q.id,
              time: timeStr,
              tag: q.skillTag,
              score: scoreStr,
              duration: durationStr,
              passed: q.passed,
              totalQuestions: q.totalQuestions,
              correctAnswers: q.correctAnswerNumbers,
            ),
          );
        }),
      ],
    );
  }
}
