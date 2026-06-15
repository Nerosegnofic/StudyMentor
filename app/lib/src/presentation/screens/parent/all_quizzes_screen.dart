import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../domain/models/quiz_attempt_model.dart';
import '../../widgets/quiz_history_card.dart';
import '../../../../l10n/app_localizations.dart';

class AllQuizzesScreen extends StatefulWidget {
  final List<QuizAttemptModel> quizzes;

  const AllQuizzesScreen({super.key, required this.quizzes});

  @override
  State<AllQuizzesScreen> createState() => _AllQuizzesScreenState();
}

class _AllQuizzesScreenState extends State<AllQuizzesScreen> {
  String _sortMethod = 'scoreLowestToHighest';

  List<QuizAttemptModel> get _sortedQuizzes {
    final list = List<QuizAttemptModel>.from(widget.quizzes);
    if (_sortMethod == 'dateNewestToOldest') {
      list.sort((a, b) => b.attemptedAt.compareTo(a.attemptedAt));
    } else if (_sortMethod == 'dateOldestToNewest') {
      list.sort((a, b) => a.attemptedAt.compareTo(b.attemptedAt));
    } else if (_sortMethod == 'scoreHighestToLowest') {
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
                loc.sortQuizzesTitle,
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 16),
              _buildSortOption(ctx, 'dateNewestToOldest', loc.sortDateNewestToOldest),
              _buildSortOption(ctx, 'dateOldestToNewest', loc.sortDateOldestToNewest),
              _buildSortOption(ctx, 'scoreHighestToLowest', loc.sortScoreHighestToLowest),
              _buildSortOption(ctx, 'scoreLowestToHighest', loc.sortScoreLowestToHighest),
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
    final loc = AppLocalizations.of(context);
    final quizzes = _sortedQuizzes;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: quizzes.isEmpty
                ? Center(
                    child: Text(
                      loc.noQuizzesYetMessage,
                      style: GoogleFonts.cairo(
                          color: const Color(0xFF64748B), fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    itemCount: quizzes.length,
                    itemBuilder: (_, i) {
                      final q = quizzes[i];
                      final timeStr =
                          '${q.attemptedAt.month}/${q.attemptedAt.day}/${q.attemptedAt.year}';
                      final durationStr =
                          '${q.duration.inMinutes}m ${q.duration.inSeconds % 60}s';
                      final scoreStr =
                          '${q.correctAnswers}/${q.totalQuestions}';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
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
                    },
                  ),
          ),
        ],
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
            AppLocalizations.of(context).allQuizzesTitle,
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
