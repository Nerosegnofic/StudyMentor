import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../bloc/subject_detail/subject_detail_bloc.dart';
import '../../bloc/subject_detail/subject_detail_event.dart';
import '../../bloc/subject_detail/subject_detail_state.dart';
import '../../../l10n/app_localizations.dart';

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
    final loc = AppLocalizations.of(context);
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
            onTap: () => setState(() => isExpanded = !isExpanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    widget.passed ? Icons.check_circle : Icons.cancel,
                    color: widget.passed
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFFE53935),
                    size: 18,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      widget.time,
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        widget.score,
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.duration,
                        style: GoogleFonts.cairo(
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
                    loc.questionsAttemptedLabel(widget.totalQuestions),
                    style: GoogleFonts.cairo(
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
                        onTap: () => _showQuestionDetailBottomSheet(
                            context, widget.quizAttemptId, qNum, isCorrect),
                        child: Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCorrect
                                ? const Color(0xFF4CAF50)
                                : const Color(0xFFE53935),
                          ),
                          child: Text(
                            qNum.toString(),
                            style: GoogleFonts.cairo(
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

  void _showQuestionDetailBottomSheet(
      BuildContext context, String quizAttemptId, int qNum, bool isCorrect) {
    final bloc = context.read<SubjectDetailBloc>();
    final detailKey = '${quizAttemptId}_$qNum';
    final currentState = bloc.state;
    // Batch-fetch all questions for this session if any are missing from cache
    if (currentState is! SubjectDetailLoaded ||
        currentState.questionDetails[detailKey] == null) {
      bloc.add(FetchSessionQuestionsRequested(quizAttemptId: quizAttemptId));
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final loc = AppLocalizations.of(sheetContext);
        return BlocBuilder<SubjectDetailBloc, SubjectDetailState>(
          bloc: bloc,
          builder: (_, state) {
            if (state is! SubjectDetailLoaded) {
              return const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()));
            }
            final detailKey = '${quizAttemptId}_$qNum';
            final detail = state.questionDetails[detailKey];

            if (detail == null) {
              return const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()));
            }

            final optionData = detail.options.map((opt) {
              String stateStr = 'default';
              if (opt == detail.correctAnswer &&
                  opt == detail.selectedAnswer) {
                stateStr = 'selected_correct';
              } else if (opt == detail.correctAnswer &&
                  opt != detail.selectedAnswer) {
                stateStr = 'correct_missed';
              } else if (opt != detail.correctAnswer &&
                  opt == detail.selectedAnswer) {
                stateStr = 'selected_incorrect';
              }
              return {'text': opt, 'state': stateStr};
            }).toList();

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(sheetContext).size.height * 0.8,
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            loc.questionNumberLabel(qNum),
                            style: GoogleFonts.cairo(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: detail.isCorrect
                                  ? const Color(0xFFE8F5E9)
                                  : const Color(0xFFFFEBEE),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              detail.isCorrect ? loc.correctLabel : loc.incorrectLabel,
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: detail.isCorrect
                                    ? const Color(0xFF4CAF50)
                                    : const Color(0xFFE53935),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
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
                            ...optionData.map((opt) =>
                                _buildOptionRow(opt['text']!, opt['state']!)),
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
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF1F5F9),
                            foregroundColor: const Color(0xFF64748B),
                            shape: const StadiumBorder(),
                            elevation: 0,
                          ),
                          child: Text(
                            loc.commonClose,
                            style: GoogleFonts.cairo(
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
      backgroundColor = const Color(0xFFE8F5E9);
      borderColor = const Color(0xFF4CAF50);
      textColor = const Color(0xFF4CAF50);
      fontWeight = FontWeight.bold;
      icon = const Icon(Icons.check_circle_outline,
          color: Color(0xFF4CAF50), size: 20);
    } else if (state == 'selected_incorrect') {
      backgroundColor = const Color(0xFFFFEBEE);
      borderColor = const Color(0xFFE53935);
      textColor = const Color(0xFFE53935);
      fontWeight = FontWeight.bold;
      icon = const Icon(Icons.cancel_outlined,
          color: Color(0xFFE53935), size: 20);
    } else if (state == 'correct_missed') {
      backgroundColor = const Color(0xFFE8F5E9);
      borderColor = const Color(0xFF4CAF50);
      textColor = const Color(0xFF4CAF50);
      fontWeight = FontWeight.bold;
      icon = const Icon(Icons.check_circle_outline,
          color: Color(0xFF4CAF50), size: 20);
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
