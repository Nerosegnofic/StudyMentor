import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../bloc/quiz/quiz_bloc.dart';
import '../../../bloc/quiz/quiz_event.dart';
import '../../../bloc/quiz/quiz_state.dart';
import '../../../data/repositories/ai_engine_repository.dart';
import '../../../domain/models/gamification_enums.dart';
import '../../../bloc/gamification/gamification_bloc.dart';
import '../../../bloc/gamification/gamification_event.dart';
import '../../../bloc/garden/garden_bloc.dart';
import '../../../bloc/garden/garden_event.dart';
import '../../../bloc/garden/garden_state.dart';
import '../../../../l10n/app_localizations.dart';

// ---------------------------------------------------------------------------
// Study Mentor design-system tokens (Student app)
// ---------------------------------------------------------------------------
// Kept file-local to mirror the existing convention in subject_detail_screen.dart
// (which defines `_kGreen` / `_kGreenLight`). Reference these instead of inline hex.
const _kBg = Color(0xFFF5F7FA); // Soft Cloud scaffold
const _kGreen = Color(0xFF4CAF50); // primary actions / growth
const _kGreenLight = Color(0xFFE8F5E9); // progress track, good-result bg
const _kAmber = Color(0xFFFFC107); // hint / gamification highlight
const _kAmberLight = Color(0xFFFFF8E1); // needs-improvement bg
const _kBlue = Color(0xFF2196F3); // informational (skill chip, explanation)
const _kBlueLight = Color(0xFFE3F2FD);
const _kBlueBorder = Color(0xFF90CAF9);
const _kRed = Color(0xFFEA4335); // wrong-answer reveal
const _kInk = Color(0xFF1A1F3C); // heading text
const _kMuted = Color(0xFF8B93A7); // secondary text
const _kHairline = Color(0xFFE3E8EF); // neutral card border
const _kDisabled = Color(0xFFCFD6E0); // disabled button fill

// Content-aware text direction: quiz content can arrive in Arabic OR English,
// so direction is detected per-field (Arabic Unicode block → RTL, else LTR).
// Inline Latin numbers are handled by the Unicode bidi algorithm.
TextDirection _dirOf(String s) =>
    RegExp(r'[؀-ۿ]').hasMatch(s)
        ? TextDirection.rtl
        : TextDirection.ltr;

// ---------------------------------------------------------------------------
// QuizOverlayPage
// ---------------------------------------------------------------------------
// Full-screen Scaffold pushed by StudentScreen when the mascot overlay fires,
// or by SubjectDetailScreen when the student taps "Practice Now".
//
// [subjectId] — optional. When provided the backend generates a quiz
// specifically for that subject. When null the backend auto-selects the
// highest-priority subject based on BKT mastery data.
//
// Pop return value convention:
//   true  → student completed the quiz (reached results screen, tapped Done)
//   false / null → student dismissed without completing

class QuizOverlayPage extends StatelessWidget {
  final AiEngineRepository repository;

  final String studentId;
  final QuizContext contextType;
  final int totalQuestions;
  final int? subjectId;

  /// The student's grade level (from their profile); null falls back to 5.
  final int? studentGrade;


  const QuizOverlayPage({
    super.key,
    required this.repository,
    required this.studentId,
    required this.contextType,
    this.totalQuestions = 5,
    this.subjectId,
    this.studentGrade,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => QuizBloc(repository: repository),

      child: _QuizOverlayScaffold(
        studentId: studentId,
        contextType: contextType,
        totalQuestions: totalQuestions,
        subjectId: subjectId,
        studentGrade: studentGrade,
      ),

    );
  }
}


class _QuizOverlayScaffold extends StatefulWidget {


  final String studentId;
  final QuizContext contextType;
  final int totalQuestions;
  final int? subjectId;
  final int? studentGrade;

  const _QuizOverlayScaffold({
    required this.studentId,
    required this.contextType,
    required this.totalQuestions,
    this.subjectId,
    this.studentGrade,
  });


  @override
  State<_QuizOverlayScaffold> createState() => _QuizOverlayScaffoldState();
}

class _QuizOverlayScaffoldState extends State<_QuizOverlayScaffold> {
  // Captured when quiz results arrive; used to compute the mastery delta.
  double? _preQuizMastery;
  String? _quizzedSubjectName;
  int? _quizzedSubjectId;
  bool _waitingForGardenUpdate = false;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Study Quiz',
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.w800,
            color: _kInk,
            fontSize: 18,
          ),
        ),
        automaticallyImplyLeading: false,
        actions: [
          BlocBuilder<QuizBloc, QuizState>(
            builder: (context, state) {
              if (state is QuizResultsLoaded || state is QuizError) {
                return IconButton(
                  icon: const Icon(Icons.close, color: _kMuted),
                  onPressed: () => Navigator.of(context)
                      .pop(state is QuizResultsLoaded ? true : false),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),


      body: BlocListener<QuizBloc, QuizState>(
        listener: (context, state) {
          if (state is QuizResultsLoaded) {
                _quizzedSubjectId = state.quizResponse.selectedSubjectId;
                _quizzedSubjectName = state.quizResponse.selectedSubjectName;

                // Snapshot mastery BEFORE the reload so we can show a delta.
                final gardenState = context.read<GardenBloc>().state;
                if (gardenState is GardenLoaded) {
                  _preQuizMastery = gardenState.plants
                      .where((p) => p.subjectId == _quizzedSubjectId)
                      .map((p) => p.masteryPercent)
                      .firstOrNull;
                }
                _waitingForGardenUpdate = true;

                // NOTE: quiz reward processing (which drives the level-up
                // celebration) is intentionally NOT dispatched here. It now
                // fires when the student leaves the results screen (taps Done /
                // Take Another) so the level-up appears AFTER they've seen the
                // result — see _ResultsView.

                context.read<GardenBloc>().add(
                      LoadGardenRequested(studentUid: widget.studentId),
                    );
              }
            },
          child: BlocListener<GardenBloc, GardenState>(
            listener: (context, state) {
              if (state is GardenLoaded && _waitingForGardenUpdate) {
                _waitingForGardenUpdate = false;
                if (_quizzedSubjectId == null || !mounted) return;

                final plant = state.plants
                    .where((p) => p.subjectId == _quizzedSubjectId)
                    .firstOrNull;
                if (plant == null) return;

                final newMastery = plant.masteryPercent;
                final pre = _preQuizMastery;
                final delta = pre != null ? newMastery - pre : null;

                final message = (delta != null && delta > 0.05)
                    ? loc.masteryUpdateMessage(
                        _quizzedSubjectName ?? '',
                        pre!.toStringAsFixed(0),
                        newMastery.toStringAsFixed(0),
                        delta.toStringAsFixed(1),
                      )
                    : loc.masteryUpdatedSimpleMessage(_quizzedSubjectName ?? '');

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(message),
                    duration: const Duration(seconds: 3),
                    backgroundColor: _kGreen,
                  ),
                );
              }
            },

        child: BlocBuilder<QuizBloc, QuizState>(
          builder: (context, state) {
            if (state is QuizInitial) {
              return _AutoStartPanel(
                totalQuestions: widget.totalQuestions,
                subjectId: widget.subjectId,
                studentGrade: widget.studentGrade,
                contextType: widget.contextType,
              );
            }
            if (state is QuizLoading) {
              return _LoadingView(message: loc.generatingQuizMessage);
            }
            if (state is QuizLoaded) return _QuizActiveView(state: state);
            if (state is QuizSubmitting) {
              return _LoadingView(message: loc.submittingAnswersMessage);
            }
            if (state is QuizResultsLoaded) {
              return _ResultsView(state: state, studentId: widget.studentId);
            }
            if (state is QuizError) return _ErrorView(message: state.message);
            return const SizedBox.shrink();
          },
        ),
      ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Auto-start panel
// ---------------------------------------------------------------------------

class _AutoStartPanel extends StatelessWidget {

  final int totalQuestions;
  final int? subjectId;
  final int? studentGrade;
  final QuizContext contextType;

  const _AutoStartPanel({
    required this.totalQuestions,
    required this.contextType,
    this.subjectId,
    this.studentGrade,
  });


  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.auto_awesome_rounded,
              size: 80,
              color: _kGreen,
            ),
            const SizedBox(height: 24),
            Text(
              'Time to Practice!',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: _kInk,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your focus time is up. Let\'s do a quick quiz to keep your brain sharp!',
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                fontSize: 15,
                color: _kMuted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                context.read<QuizBloc>().add(
                  GenerateQuizEvent(
                    totalQuestions: totalQuestions,
                    subjectId: subjectId,
                    studentGrade: studentGrade ?? 5,
                    quizContext: contextType,
                  ),
                );

              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _kGreen,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(60),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 0,
              ),
              child: Text(
                'Start Quiz',
                style: GoogleFonts.roboto(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Tailored to your current level',
              style: GoogleFonts.roboto(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: _kMuted,
              ),
            ),

            // ── ⚠️ TESTING ONLY — REMOVE BEFORE PRODUCTION RELEASE ────────
            const SizedBox(height: 32),
            const Divider(color: Color(0xFFFFCDD2)),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(false),
              icon: const Icon(Icons.home_outlined, color: Color(0xFFE53935)),
              label: Text(
                'Redirect to student home\n(FOR TESTING PURPOSES ONLY. DO NOT SHIP TO PRODUCTION!)',
                textAlign: TextAlign.center,
                style: GoogleFonts.roboto(
                  fontSize: 11,
                  color: const Color(0xFFE53935),
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFE53935)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
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

  Widget build(BuildContext context) =>
      const _AutoStartPanel(totalQuestions: 5, contextType: QuizContext.voluntary);

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

  // Tentative selection for the current question — re-changeable until the
  // student taps Submit. `_revealed` flips once the answer is committed.
  String? _selectedOption;
  bool _revealed = false;

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

  // Local-only: lets the student re-pick before committing.
  void _selectOption(String option) {
    if (_revealed) return;
    setState(() => _selectedOption = option);
  }

  // Commits the answer to the BLoC (for progress + final submission) and
  // reveals the correct/wrong colouring + the solution card.
  void _submitAnswer(BuildContext context) {
    if (_selectedOption == null) return;
    final timeTaken = DateTime.now()
        .difference(_questionStartedAt ?? DateTime.now())
        .inMilliseconds;

    context.read<QuizBloc>().add(
          AnswerQuestionEvent(
            StudentAnswer(
              questionId: _currentQuestion.questionId,
              selectedOption: _selectedOption!,
              timeTakenMs: timeTaken,
              hintsUsed: _hintsUsed,
            ),
          ),
        );
    setState(() => _revealed = true);
  }

  void _advance(BuildContext context) {
    if (_isLastQuestion) {
      context.read<QuizBloc>().add(
            SubmitQuizEvent(widget.state.quizResponse.quizSessionId),
          );
      return;
    }
    setState(() {
      _currentIndex++;
      _hintsUsed = 0;
      _selectedOption = null;
      _revealed = false;
      _questionStartedAt = DateTime.now();
    });
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _showHint(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final hints = _currentQuestion.hints;
    if (_hintsUsed >= hints.length) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.noMoreHintsMessage)));
      return;
    }
    setState(() => _hintsUsed++);
    final hintText = hints[_hintsUsed - 1];
    final hintNumber = _hintsUsed;

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: _kAmberLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lightbulb_rounded,
                  color: _kAmber,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Hint $hintNumber',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _kInk,
                ),
              ),
              const SizedBox(height: 10),
              Directionality(
                textDirection: _dirOf(hintText),
                child: Text(
                  hintText,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 15,
                    height: 1.5,
                    color: _kInk,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kAmber,
                    foregroundColor: _kInk,
                    elevation: 0,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Got it',
                    style: GoogleFonts.roboto(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final questions = widget.state.quizResponse.questions;
    final answered = widget.state.currentAnswers;
    final total = questions.length;

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: answered.length / total,
            backgroundColor: _kGreenLight,
            valueColor: const AlwaysStoppedAnimation(_kGreen),
            minHeight: 4,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question ${_currentIndex + 1} of $total',
                style: GoogleFonts.roboto(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: _kMuted,
                ),
              ),
              Text(
                '${answered.length} answered',
                style: GoogleFonts.roboto(fontSize: 13, color: _kMuted),
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
              final isCurrent = index == _currentIndex;
              return _QuestionCard(
                question: questions[index],
                selectedOption: isCurrent
                    ? _selectedOption
                    : answered[questions[index].questionId]?.selectedOption,
                revealed: isCurrent ? _revealed : true,
                onSelect: _selectOption,
              );
            },
          ),
        ),
        _buildBottomBar(context),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final hintsExhausted = _hintsUsed >= _currentQuestion.hints.length;

    final String label;
    final VoidCallback? onPrimary;
    if (!_revealed) {
      label = 'Submit';
      onPrimary = _selectedOption != null ? () => _submitAnswer(context) : null;
    } else if (_isLastQuestion) {
      label = 'Finish';
      onPrimary = () => _advance(context);
    } else {
      label = 'Next';
      onPrimary = () => _advance(context);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed: (_revealed || hintsExhausted)
                ? null
                : () => _showHint(context),
            icon: const Icon(Icons.lightbulb_outline, size: 18),
            label: Text(
              'Hint ($_hintsUsed)',
              style: GoogleFonts.roboto(fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: _kAmber,
              side: const BorderSide(color: _kAmber),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: onPrimary,
            style: ElevatedButton.styleFrom(
              backgroundColor: _kGreen,
              foregroundColor: Colors.white,
              disabledBackgroundColor: _kDisabled,
              disabledForegroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 14,
              ),
              elevation: 0,
            ),
            child: Text(
              label,
              style: GoogleFonts.roboto(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final QuestionModel question;
  final String? selectedOption;
  final bool revealed;
  final ValueChanged<String> onSelect;

  const _QuestionCard({
    required this.question,
    required this.selectedOption,
    required this.revealed,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isCorrectSelection = selectedOption == question.correctAnswer;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── White question card ────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _difficultyPill(loc),
                    _skillChip(),
                  ],
                ),
                const SizedBox(height: 16),
                Directionality(
                  textDirection: _dirOf(question.questionText),
                  child: Text(
                    question.questionText,
                    textAlign: TextAlign.start,
                    style: GoogleFonts.cairo(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      height: 1.5,
                      color: _kInk,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // ── Answer options (uniform full-width) ─────────────────────────
          ...question.options.map(
            (opt) => _OptionTile(
              label: opt,
              isSelected: selectedOption == opt,
              isCorrect: opt == question.correctAnswer,
              revealed: revealed,
              onTap: () => onSelect(opt),
            ),
          ),
          // ── Solution / explanation (after submit) ───────────────────────
          if (revealed) _SolutionCard(question: question, isCorrect: isCorrectSelection),
        ],
      ),
    );
  }

  Widget _difficultyPill(AppLocalizations loc) {
    final color = _difficultyColor(question.difficulty);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _difficultyLabel(loc, question.difficulty),
        style: GoogleFonts.roboto(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _skillChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _kBlueLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kBlueBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.menu_book_rounded, size: 13, color: _kBlue),
          const SizedBox(width: 6),
          Flexible(
            child: Directionality(
              textDirection: _dirOf(question.topic),
              child: Text(
                question.topic,
                style: GoogleFonts.cairo(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _kBlue,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _difficultyColor(int d) {
    switch (d) {
      case 1:
        return _kGreen;
      case 2:
        return _kBlue;
      case 3:
        return _kAmber;
      case 4:
        return _kRed;
      default:
        return const Color(0xFF9C27B0);
    }
  }

  String _difficultyLabel(AppLocalizations loc, int d) {
    switch (d) {
      case 1:
        return loc.veryEasyLabel;
      case 2:
        return loc.easyLabel;
      case 3:
        return loc.mediumLabel;
      case 4:
        return loc.hardLabel;
      default:
        return loc.veryHardLabel;
    }
  }
}

class _OptionTile extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isCorrect;
  final bool revealed;
  final VoidCallback onTap;

  const _OptionTile({
    required this.label,
    required this.isSelected,
    required this.isCorrect,
    required this.revealed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Resolve the visual treatment for the four reachable states.
    late final Color bg;
    late final Color border;
    late final Color fg;
    late final IconData icon;
    late final Color iconColor;
    var emphasize = false;

    if (!revealed) {
      if (isSelected) {
        bg = _kGreenLight;
        border = _kGreen;
        fg = _kInk;
        icon = Icons.radio_button_checked;
        iconColor = _kGreen;
        emphasize = true;
      } else {
        bg = Colors.white;
        border = _kHairline;
        fg = _kInk;
        icon = Icons.radio_button_unchecked;
        iconColor = _kMuted;
      }
    } else if (isCorrect) {
      // The correct option is always highlighted green, even if not chosen.
      bg = _kGreen;
      border = _kGreen;
      fg = Colors.white;
      icon = Icons.check_circle;
      iconColor = Colors.white;
      emphasize = true;
    } else if (isSelected) {
      // The student's wrong pick.
      bg = _kRed;
      border = _kRed;
      fg = Colors.white;
      icon = Icons.cancel;
      iconColor = Colors.white;
      emphasize = true;
    } else {
      bg = Colors.white;
      border = _kHairline;
      fg = _kMuted;
      icon = Icons.radio_button_unchecked;
      iconColor = _kDisabled;
    }

    return GestureDetector(
      onTap: revealed ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border, width: 1.5),
        ),
        child: Directionality(
          textDirection: _dirOf(label),
          child: Row(
            children: [
              Icon(icon, size: 22, color: iconColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.start,
                  style: GoogleFonts.cairo(
                    fontSize: 15,
                    color: fg,
                    fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Solution / explanation card (shown after the answer is submitted)
// ---------------------------------------------------------------------------

class _SolutionCard extends StatelessWidget {
  final QuestionModel question;
  final bool isCorrect;

  const _SolutionCard({required this.question, required this.isCorrect});

  @override
  Widget build(BuildContext context) {
    final accent = isCorrect ? _kGreen : _kAmber;
    final bg = isCorrect ? _kGreenLight : _kAmberLight;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                isCorrect ? Icons.check_circle : Icons.lightbulb_rounded,
                size: 18,
                color: accent,
              ),
              const SizedBox(width: 8),
              Text(
                isCorrect ? 'Correct!' : 'Solution',
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
            ],
          ),
          if (!isCorrect) ...[
            const SizedBox(height: 12),
            Text(
              'Correct answer',
              style: GoogleFonts.roboto(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _kMuted,
              ),
            ),
            const SizedBox(height: 4),
            Directionality(
              textDirection: _dirOf(question.correctAnswer),
              child: Text(
                question.correctAnswer,
                textAlign: TextAlign.start,
                style: GoogleFonts.cairo(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _kInk,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Directionality(
            textDirection: _dirOf(question.explanation),
            child: Text(
              question.explanation,
              textAlign: TextAlign.start,
              style: GoogleFonts.cairo(
                fontSize: 13,
                height: 1.5,
                color: _kInk,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Results view
// ---------------------------------------------------------------------------

class _ResultsView extends StatelessWidget {
  final QuizResultsLoaded state;
  final String studentId;

  const _ResultsView({required this.state, required this.studentId});

  // Processes the quiz rewards (XP / coins / level-up). Dispatched only when the
  // student leaves the results screen, so the level-up celebration appears
  // after they've seen the result rather than on top of it.
  void _processRewards(BuildContext context) {
    context.read<GamificationBloc>().add(
          ProcessQuizRewardsRequested(
            studentId: studentId,
            rewards: state.result.rewards,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
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
            style: GoogleFonts.cairo(
              fontSize: 56,
              fontWeight: FontWeight.w800,
              color: _kGreen,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${state.result.totalQuestions} questions',
            style: GoogleFonts.roboto(fontSize: 14, color: _kMuted),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isGood ? _kGreenLight : _kAmberLight,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isGood ? _kGreen : _kAmber,
              ),
            ),
            child: Directionality(
              textDirection: _dirOf(state.result.feedback),
              child: Text(
                state.result.feedback,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontSize: 15,
                  height: 1.5,
                  color: isGood
                      ? const Color(0xFF1B5E20)
                      : const Color(0xFFE65100),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              _processRewards(context);
              Navigator.of(context).pop(true);
            },
            icon: const Icon(Icons.check_circle_outline),
            label: Text(
              'Done',
              style: GoogleFonts.roboto(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kGreen,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              _processRewards(context);
              context.read<QuizBloc>().add(ResetQuizEvent());
            },
            icon: const Icon(Icons.refresh_rounded),
            label: Text(
              'Take Another Quiz',
              style: GoogleFonts.roboto(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: _kGreen,
              side: const BorderSide(color: _kGreen),
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
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
          const CircularProgressIndicator(color: _kGreen),
          const SizedBox(height: 20),
          Text(
            message,
            style: GoogleFonts.roboto(color: _kMuted, fontSize: 15),
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
    final loc = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 56, color: _kRed),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _kInk,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(color: _kMuted, fontSize: 13),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () =>
                  context.read<QuizBloc>().add(ResetQuizEvent()),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                'Try Again',
                style: GoogleFonts.roboto(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
