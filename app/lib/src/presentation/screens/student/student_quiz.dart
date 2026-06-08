import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/quiz/quiz_bloc.dart';
import '../../../bloc/quiz/quiz_event.dart';
import '../../../bloc/quiz/quiz_state.dart';
import '../../../data/repositories/ai_engine_repository.dart';

// ---------------------------------------------------------------------------
// QuizOverlayPage
// ---------------------------------------------------------------------------
// Full-screen Scaffold pushed by StudentScreen when the mascot overlay fires.
// It owns its own QuizBloc so it doesn't interfere with the rest of the app.
//
// Pop return value convention:
//   true  → student completed the quiz (reached results screen, tapped Done)
//   false / null → student dismissed without completing

class QuizOverlayPage extends StatelessWidget {
  final AiEngineRepository repository;
  final int studentGrade;

  const QuizOverlayPage({
    super.key,
    required this.repository,
    this.studentGrade = 5,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => QuizBloc(repository: repository),
      child: _QuizOverlayScaffold(studentGrade: studentGrade),
    );
  }
}

class _QuizOverlayScaffold extends StatelessWidget {
  final int studentGrade;
  const _QuizOverlayScaffold({required this.studentGrade});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Study Quiz',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A1F3C),
            fontSize: 18,
          ),
        ),
        // Only allow closing from the results screen or on error.
        automaticallyImplyLeading: false,
        actions: [
          BlocBuilder<QuizBloc, QuizState>(
            builder: (context, state) {
              if (state is QuizResultsLoaded || state is QuizError) {
                return IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF4A6CF7)),
                  // Results close: pop with true (completed).
                  // Error close: pop with false (did not complete).
                  onPressed: () => Navigator.of(
                    context,
                  ).pop(state is QuizResultsLoaded ? true : false),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocBuilder<QuizBloc, QuizState>(
        builder: (context, state) {
          if (state is QuizInitial) return _AutoStartPanel(studentGrade: studentGrade);
          if (state is QuizLoading) {
            return const _LoadingView(message: 'Generating your quiz…');
          }
          if (state is QuizLoaded) return _QuizActiveView(state: state);
          if (state is QuizSubmitting) {
            return const _LoadingView(message: 'Submitting answers…');
          }
          if (state is QuizResultsLoaded) return _ResultsView(state: state);
          if (state is QuizError) return _ErrorView(message: state.message);
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Auto-start panel
// ---------------------------------------------------------------------------

class _AutoStartPanel extends StatelessWidget {
  final int studentGrade;
  const _AutoStartPanel({required this.studentGrade});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.auto_awesome_rounded,
              size: 80,
              color: Color(0xFF4A6CF7),
            ),
            const SizedBox(height: 24),
            const Text(
              'Time to Practice!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1A1F3C),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Your focus time is up. Let\'s do a quick quiz to keep your brain sharp!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF8B93A7),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                context.read<QuizBloc>().add(
                  GenerateQuizEvent(
                    totalQuestions: 5,
                    studentGrade: studentGrade,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A6CF7),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(60),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Start Quiz',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tailored to your current level',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Color(0xFFA0A7BA),
              ),
            ),

            // ── ⚠️ TESTING ONLY — REMOVE BEFORE PRODUCTION RELEASE ────────
            const SizedBox(height: 32),
            const Divider(color: Color(0xFFFFCDD2)),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              // Pop with false = dismissed, not completed.
              onPressed: () => Navigator.of(context).pop(false),
              icon: const Icon(Icons.home_outlined, color: Color(0xFFE53935)),
              label: const Text(
                'Redirect to student home\n(FOR TESTING PURPOSES ONLY. DO NOT SHIP TO PRODUCTION!)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFFE53935),
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFE53935)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            // ── END TESTING BLOCK ──────────────────────────────────────────
          ],
        ),
      ),
    );
  }
}

// Keep StudentQuizScreen as an alias for backward compatibility (unused now).
class StudentQuizScreen extends StatelessWidget {
  const StudentQuizScreen({super.key});

  @override
  Widget build(BuildContext context) => const _AutoStartPanel(studentGrade: 5);
}

// ---------------------------------------------------------------------------
// Active quiz view
// ---------------------------------------------------------------------------

class _QuizActiveView extends StatefulWidget {
  final QuizLoaded state;

  const _QuizActiveView({required this.state});

  @override
  State<_QuizActiveView> createState() => _QuizActiveViewState();
}

class _QuizActiveViewState extends State<_QuizActiveView> {
  int _currentIndex = 0;
  int _hintsUsed = 0;
  DateTime? _questionStartedAt;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _questionStartedAt = DateTime.now();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  QuestionModel get _currentQuestion =>
      widget.state.quizResponse.questions[_currentIndex];

  bool get _isLastQuestion =>
      _currentIndex == widget.state.quizResponse.questions.length - 1;

  bool get _hasAnsweredCurrent =>
      widget.state.currentAnswers.containsKey(_currentQuestion.questionId);

  void _selectAnswer(BuildContext context, String option) {
    if (_hasAnsweredCurrent) return;
    final timeTaken = DateTime.now()
        .difference(_questionStartedAt ?? DateTime.now())
        .inMilliseconds;

    context.read<QuizBloc>().add(
      AnswerQuestionEvent(
        StudentAnswer(
          questionId: _currentQuestion.questionId,
          selectedOption: option,
          timeTakenMs: timeTaken,
          hintsUsed: _hintsUsed,
        ),
      ),
    );
  }

  void _goNext(BuildContext context) {
    if (!_hasAnsweredCurrent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an answer first.')),
      );
      return;
    }
    if (_isLastQuestion) {
      context.read<QuizBloc>().add(
        SubmitQuizEvent(widget.state.quizResponse.quizSessionId),
      );
    } else {
      setState(() {
        _currentIndex++;
        _hintsUsed = 0;
        _questionStartedAt = DateTime.now();
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showHint(BuildContext context) {
    final hints = _currentQuestion.hints;
    if (_hintsUsed >= hints.length) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No more hints available.')));
      return;
    }
    setState(() => _hintsUsed++);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Hint $_hintsUsed'),
        content: Text(hints[_hintsUsed - 1]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final questions = widget.state.quizResponse.questions;
    final answered = widget.state.currentAnswers;
    final total = questions.length;

    return Column(
      children: [
        // Progress bar
        LinearProgressIndicator(
          value: answered.length / total,
          backgroundColor: const Color(0xFFE8EDFF),
          valueColor: const AlwaysStoppedAnimation(Color(0xFF4A6CF7)),
          minHeight: 4,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question ${_currentIndex + 1} of $total',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Color(0xFF8B93A7),
                ),
              ),
              Text(
                '${answered.length} answered',
                style: const TextStyle(fontSize: 13, color: Color(0xFF8B93A7)),
              ),
            ],
          ),
        ),

        Expanded(
          child: PageView.builder(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: questions.length,
            itemBuilder: (context, index) {
              return _QuestionCard(
                question: questions[index],
                selectedOption:
                    answered[questions[index].questionId]?.selectedOption,
                onSelect: (opt) => _selectAnswer(context, opt),
              );
            },
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => _showHint(context),
                icon: const Icon(Icons.lightbulb_outline, size: 18),
                label: Text('Hint ($_hintsUsed)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFF9800),
                  side: const BorderSide(color: Color(0xFFFF9800)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _hasAnsweredCurrent ? () => _goNext(context) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A6CF7),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 14,
                  ),
                  elevation: 0,
                ),
                child: Text(
                  _isLastQuestion ? 'Submit' : 'Next',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final QuestionModel question;
  final String? selectedOption;
  final ValueChanged<String> onSelect;

  const _QuestionCard({
    required this.question,
    required this.selectedOption,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Difficulty chip + Topic badge
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _difficultyColor(
                    question.difficulty,
                  ).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _difficultyLabel(question.difficulty),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _difficultyColor(question.difficulty),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EDFF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFD1DBFE)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.menu_book_rounded,
                      size: 13,
                      color: Color(0xFF4A6CF7),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        question.topic,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4A6CF7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            question.questionText,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          ...question.options.map(
            (opt) => _OptionTile(
              label: opt,
              isSelected: selectedOption == opt,
              isAnswered: selectedOption != null,
              onTap: () => onSelect(opt),
            ),
          ),
          if (selectedOption != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F7FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBBD6F4)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Color(0xFF4A6CF7),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      question.explanation,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF1A1F3C),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _difficultyColor(int d) {
    switch (d) {
      case 1:
        return const Color(0xFF34A853);
      case 2:
        return const Color(0xFF4A6CF7);
      case 3:
        return const Color(0xFFFF9800);
      case 4:
        return const Color(0xFFEA4335);
      default:
        return const Color(0xFF9C27B0);
    }
  }

  String _difficultyLabel(int d) {
    switch (d) {
      case 1:
        return 'Very Easy';
      case 2:
        return 'Easy';
      case 3:
        return 'Medium';
      case 4:
        return 'Hard';
      default:
        return 'Very Hard';
    }
  }
}

class _OptionTile extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isAnswered;
  final VoidCallback onTap;

  const _OptionTile({
    required this.label,
    required this.isSelected,
    required this.isAnswered,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected
        ? const Color(0xFF4A6CF7)
        : const Color(0xFFE8EDFF);
    return GestureDetector(
      onTap: isAnswered ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4A6CF7) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 1.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            color: isSelected ? Colors.white : const Color(0xFF1A1F3C),
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Results view
// ---------------------------------------------------------------------------

class _ResultsView extends StatelessWidget {
  final QuizResultsLoaded state;

  const _ResultsView({required this.state});

  @override
  Widget build(BuildContext context) {
    final score = state.result.score;
    final pct = score.round();
    final isGood = score >= 50;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Text(
            pct >= 85
                ? '🎉'
                : pct >= 50
                ? '👍'
                : '💪',
            style: const TextStyle(fontSize: 64),
          ),
          const SizedBox(height: 16),
          Text(
            '$pct%',
            style: const TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.w900,
              color: Color(0xFF4A6CF7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${state.result.totalQuestions} questions',
            style: const TextStyle(fontSize: 14, color: Color(0xFF8B93A7)),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isGood ? const Color(0xFFE6F4EA) : const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isGood
                    ? const Color(0xFF34A853)
                    : const Color(0xFFFF9800),
              ),
            ),
            child: Text(
              state.result.feedback,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: isGood
                    ? const Color(0xFF1B5E20)
                    : const Color(0xFFE65100),
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            // Pop with true = completed successfully.
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.check_circle_outline),
            label: const Text(
              'Done',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A6CF7),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => context.read<QuizBloc>().add(ResetQuizEvent()),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text(
              'Take Another Quiz',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF4A6CF7),
              side: const BorderSide(color: Color(0xFF4A6CF7)),
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared helper views
// ---------------------------------------------------------------------------

class _LoadingView extends StatelessWidget {
  final String message;

  const _LoadingView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Color(0xFF4A6CF7)),
          const SizedBox(height: 20),
          Text(
            message,
            style: const TextStyle(color: Color(0xFF8B93A7), fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;

  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 56, color: Color(0xFFEA4335)),
            const SizedBox(height: 16),
            const Text(
              'Something went wrong',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF8B93A7), fontSize: 13),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.read<QuizBloc>().add(ResetQuizEvent()),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
