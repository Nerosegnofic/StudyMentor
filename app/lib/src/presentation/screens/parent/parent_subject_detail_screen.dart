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
import 'all_skills_screen.dart';
import 'all_quizzes_screen.dart';
import '../../../data/catalog/subject_metadata_registry.dart';

class ParentSubjectDetailScreen extends StatefulWidget {
  final String studentUid;
  final String subjectKey;
  final String subjectName;
  final Color color;

  const ParentSubjectDetailScreen({
    super.key,
    required this.studentUid,
    required this.subjectKey,
    required this.subjectName,
    required this.color,
  });

  @override
  State<ParentSubjectDetailScreen> createState() => _ParentSubjectDetailScreenState();
}

class _ParentSubjectDetailScreenState extends State<ParentSubjectDetailScreen> {
  String _activeSortMethod = "Date: Newest to Oldest";

  List<QuizAttemptModel> _sortQuizzes(List<QuizAttemptModel> quizzes) {
    final list = List<QuizAttemptModel>.from(quizzes);
    if (_activeSortMethod == "Date: Newest to Oldest") {
      list.sort((a, b) => b.attemptedAt.compareTo(a.attemptedAt));
    } else if (_activeSortMethod == "Date: Oldest to Newest") {
      list.sort((a, b) => a.attemptedAt.compareTo(b.attemptedAt));
    } else if (_activeSortMethod == "Score: Highest to Lowest") {
      list.sort((a, b) => b.correctAnswers.compareTo(a.correctAnswers));
    } else if (_activeSortMethod == "Score: Lowest to Highest") {
      list.sort((a, b) => a.correctAnswers.compareTo(b.correctAnswers));
    }
    return list;
  }

  void _showSortModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
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
                "Sort Quizzes",
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 16),
              _buildSortOptionRow(context, "Date: Newest to Oldest"),
              _buildSortOptionRow(context, "Date: Oldest to Newest"),
              _buildSortOptionRow(context, "Score: Highest to Lowest"),
              _buildSortOptionRow(context, "Score: Lowest to Highest"),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOptionRow(BuildContext context, String optionText) {
    final bool isSelected = _activeSortMethod == optionText;
    return InkWell(
      onTap: () {
        setState(() {
          _activeSortMethod = optionText;
        });
        Navigator.of(context).pop();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Color(0xFFF1F5F9),
              width: 1,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              optionText,
              style: GoogleFonts.roboto(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: const Color(0xFF1E293B),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check,
                color: Color(0xFF2196F3),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Always create our own SubjectDetailBloc so the screen is self-contained.
    // This avoids ProviderNotFoundException on Android activity restoration
    // where the route-scoped BlocProvider from the parent is lost.
    return BlocProvider<SubjectDetailBloc>(
      create: (_) => SubjectDetailBloc(
        authRepository: context.read<AuthRepository>(),
      )..add(LoadSubjectDetailRequested(
          studentUid: widget.studentUid,
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
            return Center(child: Text(state.message));
          }

          if (state is SubjectDetailLoaded) {
            return Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    children: [
                      _buildOverviewStatsCard(state.summary),
                      const SizedBox(height: 16),
                      _buildSkillsProgressCard(context, state.skills),
                      const SizedBox(height: 16),
                      _buildQuizHistorySection(state.recentQuizzes),
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
            backgroundColor: widget.color.withOpacity(0.2),
            child: Icon(
              SubjectMetadataRegistry.getSubjectIcon(widget.subjectKey) ?? Icons.book,
              color: widget.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewStatsCard(SubjectSummaryModel summary) {
    final hours = summary.totalTimeSpent.inHours;
    final minutes = summary.totalTimeSpent.inMinutes % 60;
    final timeStr = hours > 0 ? "${hours}h ${minutes}m" : "${minutes}m";

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
              _buildStatCol("${summary.accuracyPercent}%", "Accuracy"),
              Container(width: 1, height: 40, color: const Color(0xFFE2E8F0)),
              _buildStatCol("${summary.quizzesCompleted}", "Quizzes Done"),
              Container(width: 1, height: 40, color: const Color(0xFFE2E8F0)),
              _buildStatCol(timeStr, "Time Spent"),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Overall Mastery Level",
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
                      "${summary.masteryPercent}%",
                      style: GoogleFonts.roboto(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2196F3),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2F1), // Light Teal
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "Proficient", // You can calculate this based on masteryPercent if needed
                        style: GoogleFonts.roboto(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF00897B),
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
          style: GoogleFonts.roboto(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: 12,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildSkillsProgressCard(BuildContext context, List<SkillProgressModel> skills) {
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
                "Skills Progress",
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AllSkillsScreen(),
                    ),
                  );
                },
                child: Text(
                  "See All",
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2196F3),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...skills.map((skill) {
            final accuracy = skill.totalAttempts > 0 
                ? ((skill.correctAnswers / skill.totalAttempts) * 100).round()
                : 0;
            return _buildSkillRow(
              skill.skillKey, 
              accuracy, 
              isStrong: accuracy >= 80, 
              isNeedsWork: accuracy < 50 && skill.totalAttempts > 0
            );
          }).take(5), // Show top 5 skills
        ],
      ),
    );
  }

  Widget _buildSkillRow(String name, int score, {bool isStrong = false, bool isNeedsWork = false}) {
    final bool failed = score < 50;
    final bool showStrong = isStrong || score >= 80;
    final bool showNeedsWork = isNeedsWork || score < 50;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row (Text & Badge)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left Side: Skill Name and Badge
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    constraints: const BoxConstraints(maxWidth: 100),
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
                  if (showStrong) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2F1), // Light Teal
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "Strong",
                        style: GoogleFonts.roboto(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF00897B), // Teal
                        ),
                      ),
                    ),
                  ],
                  if (showNeedsWork && !showStrong) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEE), // Light Red
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "Needs Work",
                        style: GoogleFonts.roboto(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFE53935), // Red
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              // Right Side: Percentage
              Text(
                "$score%",
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: failed ? const Color(0xFFE53935) : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Bottom Row (Progress Bar)
          LayoutBuilder(
            builder: (context, constraints) {
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
                  Container(
                    width: constraints.maxWidth * (score / 100),
                    height: 8,
                    decoration: BoxDecoration(
                      color: failed ? const Color(0xFFE53935) : const Color(0xFF2196F3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              );
            }
          ),
        ],
      ),
    );
  }

  Widget _buildQuizHistorySection(List<QuizAttemptModel> recentQuizzes) {
    final sortedList = _sortQuizzes(recentQuizzes);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Quiz History",
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
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const AllQuizzesScreen(),
                      ),
                    );
                  },
                  child: Text(
                    "See All",
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2196F3),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.sort, color: Color(0xFF64748B)),
                  onPressed: () => _showSortModal(context),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...sortedList.take(10).map((q) {
          final timeStr = "${q.attemptedAt.month}/${q.attemptedAt.day}/${q.attemptedAt.year}";
          final durationStr = "${q.duration.inMinutes}m ${q.duration.inSeconds % 60}s";
          final scoreStr = "${q.correctAnswers}/${q.totalQuestions}";

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


class QuizHistoryCard extends StatefulWidget {
  final String quizAttemptId;
  final String time;
  final String tag;
  final String score;
  final String duration;
  final bool passed;
  final int totalQuestions;
  final List<int> correctAnswers;

  const QuizHistoryCard({
    super.key,
    required this.quizAttemptId,
    required this.time,
    required this.tag,
    required this.score,
    required this.duration,
    required this.passed,
    required this.totalQuestions,
    required this.correctAnswers,
  });

  @override
  State<QuizHistoryCard> createState() => _QuizHistoryCardState();
}

class _QuizHistoryCardState extends State<QuizHistoryCard> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          InkWell(
            onTap: () {
              setState(() {
                isExpanded = !isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.passed ? const Color(0xFF2196F3) : const Color(0xFFE53935),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.time,
                          style: GoogleFonts.roboto(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        widget.score,
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.duration,
                        style: GoogleFonts.roboto(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: const Color(0xFF64748B),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 8),
                  Text(
                    "Questions Attempted (${widget.totalQuestions})",
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(widget.totalQuestions, (index) {
                      final qNum = index + 1;
                      final isCorrect = widget.correctAnswers.contains(qNum);
                      return GestureDetector(
                        onTap: () => _showQuestionDetailBottomSheet(context, widget.quizAttemptId, qNum, isCorrect),
                        child: Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCorrect ? const Color(0xFF2196F3) : const Color(0xFFE53935),
                          ),
                          child: Text(
                            qNum.toString(),
                            style: GoogleFonts.roboto(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showQuestionDetailBottomSheet(BuildContext context, String quizAttemptId, int qNum, bool isCorrect) {
    final bloc = context.read<SubjectDetailBloc>();
    bloc.add(FetchQuestionDetailRequested(quizAttemptId: quizAttemptId, questionNumber: qNum));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return BlocBuilder<SubjectDetailBloc, SubjectDetailState>(
          bloc: bloc,
          builder: (context, state) {
            if (state is! SubjectDetailLoaded) {
              return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
            }
            final detailKey = '${quizAttemptId}_$qNum';
            final detail = state.questionDetails[detailKey];

            if (detail == null) {
              return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
            }

            final List<Map<String, String>> optionData = detail.options.map((opt) {
              String stateStr = 'default';
              if (opt == detail.correctAnswer && opt == detail.selectedAnswer) {
                stateStr = 'selected_correct';
              } else if (opt == detail.correctAnswer && opt != detail.selectedAnswer) {
                stateStr = 'correct_missed';
              } else if (opt != detail.correctAnswer && opt == detail.selectedAnswer) {
                stateStr = 'selected_incorrect';
              }
              return {'text': opt, 'state': stateStr};
            }).toList();

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Question $qNum",
                            style: GoogleFonts.cairo(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: detail.isCorrect ? const Color(0xFFE3F2FD) : const Color(0xFFFFEBEE),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              detail.isCorrect ? "Correct" : "Incorrect",
                              style: GoogleFonts.roboto(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: detail.isCorrect ? const Color(0xFF2196F3) : const Color(0xFFE53935),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              child: Text(
                                detail.questionText,
                                textDirection: TextDirection.rtl,
                                textAlign: TextAlign.right,
                                style: GoogleFonts.cairo(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            ...optionData.map((opt) => _buildOptionRow(opt["text"]!, opt["state"]!)),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF1F5F9),
                            foregroundColor: const Color(0xFF64748B),
                            shape: const StadiumBorder(),
                            elevation: 0,
                          ),
                          child: Text(
                            "Close",
                            style: GoogleFonts.roboto(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildOptionRow(String text, String state) {
    Color backgroundColor = Colors.white;
    Color borderColor = const Color(0xFFE2E8F0);
    Color textColor = const Color(0xFF1E293B);
    FontWeight fontWeight = FontWeight.normal;
    Widget? icon;

    if (state == 'selected_correct') {
      backgroundColor = const Color(0xFFE3F2FD);
      borderColor = const Color(0xFF2196F3);
      textColor = const Color(0xFF2196F3);
      fontWeight = FontWeight.bold;
      icon = const Icon(Icons.check_circle_outline, color: Color(0xFF2196F3), size: 20);
    } else if (state == 'selected_incorrect') {
      backgroundColor = const Color(0xFFFFEBEE);
      borderColor = const Color(0xFFE53935);
      textColor = const Color(0xFFE53935);
      fontWeight = FontWeight.bold;
      icon = const Icon(Icons.cancel_outlined, color: Color(0xFFE53935), size: 20);
    } else if (state == 'correct_missed') {
      backgroundColor = const Color(0xFFE0F2F1);
      borderColor = const Color(0xFF00897B);
      textColor = const Color(0xFF00897B);
      fontWeight = FontWeight.bold;
      icon = const Icon(Icons.check_circle_outline, color: Color(0xFF00897B), size: 20);
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: fontWeight,
                color: textColor,
              ),
            ),
          ),
          if (icon != null) ...[
            const SizedBox(width: 12),
            icon,
          ],
        ],
      ),
    );
  }
}
