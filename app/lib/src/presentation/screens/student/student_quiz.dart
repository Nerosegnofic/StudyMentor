import 'dart:async';

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
import '../../../features/mascot/mascot_cubit.dart';
import '../../../features/mascot/mascot_state.dart';
import '../../../features/mascot/mascot_widget.dart';
import '../../../features/mascot/mascot_with_bubble.dart';
import '../../../services/quiz_lock_service.dart';
import '../../../services/overlay/mascot_overlay_service.dart';
import '../../../../l10n/app_localizations.dart';

// ---------------------------------------------------------------------------
// StudyMentor design-system tokens (Student app)
// ---------------------------------------------------------------------------
const _kBg = Color(0xFFF5F7FA);
const _kGreen = Color(0xFF4CAF50);
const _kGreenLight = Color(0xFFE8F5E9);
const _kAmber = Color(0xFFFFC107);
const _kAmberLight = Color(0xFFFFF8E1);
const _kBlue = Color(0xFF2196F3);
const _kBlueLight = Color(0xFFE3F2FD);
const _kBlueBorder = Color(0xFF90CAF9);
const _kRed = Color(0xFFEA4335);
const _kInk = Color(0xFF1A1F3C);
const _kMuted = Color(0xFF8B93A7);
const _kHairline = Color(0xFFE3E8EF);
const _kDisabled = Color(0xFFCFD6E0);

// Content-aware text direction: quiz content can arrive in Arabic OR English.
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
// [restoredSession] — when non-null the BLoC is seeded with the saved quiz
// data and the student resumes at [restoredSession.currentIndex].
//
// Pop return value convention:
//   true  → student completed the quiz (reached results screen, tapped Done)
//   false / null → student dismissed without completing

class QuizOverlayPage extends StatelessWidget {
  final AiEngineRepository repository;
  final String studentId;
  final QuizContext contextType;
  final int totalQuestions;
  final bool autoLength;
  final int? subjectId;
  final int? studentGrade;

  /// Non-null when restoring a previously interrupted quiz session.
  final QuizSessionData? restoredSession;

  const QuizOverlayPage({
    super.key,
    required this.repository,
    required this.studentId,
    required this.contextType,
    this.totalQuestions = 5,
    this.autoLength = false,
    this.subjectId,
    this.studentGrade,
    this.restoredSession,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => QuizBloc(repository: repository)),
        BlocProvider(create: (_) => MascotCubit()),
      ],
      child: _QuizOverlayScaffold(
        studentId: studentId,
        contextType: contextType,
        totalQuestions: totalQuestions,
        autoLength: autoLength,
        subjectId: subjectId,
        studentGrade: studentGrade,
        restoredSession: restoredSession,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _QuizOverlayScaffold
// ---------------------------------------------------------------------------

class _QuizOverlayScaffold extends StatefulWidget {
  final String studentId;
  final QuizContext contextType;
  final int totalQuestions;
  final bool autoLength;
  final int? subjectId;
  final int? studentGrade;
  final QuizSessionData? restoredSession;

  const _QuizOverlayScaffold({
    required this.studentId,
    required this.contextType,
    required this.totalQuestions,
    this.autoLength = false,
    this.subjectId,
    this.studentGrade,
    this.restoredSession,
  });

  @override
  State<_QuizOverlayScaffold> createState() => _QuizOverlayScaffoldState();
}

class _QuizOverlayScaffoldState extends State<_QuizOverlayScaffold>
    with WidgetsBindingObserver {
  double? _preQuizMastery;
  String? _quizzedSubjectName;
  int? _quizzedSubjectId;
  bool _waitingForGardenUpdate = false;

  // Set to true once the first QuizLoaded state arrives so we only save the
  // initial session (with index=0) once, not on every answer update.
  bool _quizLockActivated = false;

  // Restored index/elapsed passed down to _QuizActiveView so initState can
  // position the student at the right question.
  int _restoredIndex = 0;
  int _restoredElapsedMs = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final restored = widget.restoredSession;
    if (restored != null) {
      _restoredIndex = restored.currentIndex;
      _restoredElapsedMs = restored.elapsedMs;
      _quizLockActivated = true; // already locked (we're restoring)
      // Dispatch restore event after the BlocProvider tree is fully built.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<QuizBloc>().add(
              RestoreQuizSessionEvent(
                quizResponse: restored.quizResponse,
                answers: restored.answers,
              ),
            );
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    if (lifecycle != AppLifecycleState.paused &&
        lifecycle != AppLifecycleState.hidden) {
      return;
    }
    // Single quiz-lock enforcement point for the whole overlay: while a quiz is
    // in progress the student must not be able to leave. This covers loading,
    // loaded AND submitting — including the gap before/after _QuizActiveView is
    // mounted — so a quick home-press during generation or submission can't
    // escape. QuizInitial (start panel / "Not now"), results and error states are
    // intentionally escapable. The native UsageTimerService tick is the fallback
    // for when the engine is suspended.
    final s = context.read<QuizBloc>().state;
    if (s is QuizLoading || s is QuizLoaded || s is QuizSubmitting) {
      MascotOverlayService.instance.bringToForeground();
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    // Use BlocBuilder at the top level so PopScope can derive canPop from state.
    return BlocBuilder<QuizBloc, QuizState>(
      builder: (context, state) {
        // Lock prevents back navigation while a quiz is actively in progress.
        final canPop = state is QuizResultsLoaded ||
            state is QuizError ||
            state is QuizInitial;

        return PopScope(
          canPop: canPop,
          child: Scaffold(
            backgroundColor: _kBg,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              title: Text(
                loc.studyQuizTitle,
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.w800,
                  color: _kInk,
                  fontSize: 18,
                ),
              ),
              automaticallyImplyLeading: false,
              actions: [
                if (state is QuizResultsLoaded || state is QuizError)
                  IconButton(
                    icon: const Icon(Icons.close, color: _kMuted),
                    onPressed: () => Navigator.of(context)
                        .pop(state is QuizResultsLoaded ? true : false),
                  ),
              ],
            ),
            body: BlocListener<QuizBloc, QuizState>(
              listener: (context, state) {
                if (state is QuizLoading || state is QuizSubmitting) {
                  context.read<MascotCubit>().startThinking();
                }

                // First QuizLoaded arrival — save initial session and activate lock.
                if (state is QuizLoaded && !_quizLockActivated) {
                  _quizLockActivated = true;
                  QuizLockService.instance.saveSession(QuizSessionData(
                    quizResponse: state.quizResponse,
                    answers: const {},
                    currentIndex: 0,
                    elapsedMs: 0,
                    studentId: widget.studentId,
                    contextType: widget.contextType,
                    totalQuestions: widget.totalQuestions,
                    autoLength: widget.autoLength,
                    subjectId: widget.subjectId,
                    studentGrade: widget.studentGrade,
                  ));
                }

                if (state is QuizResultsLoaded) {
                  // Deactivate the quiz lock as soon as results arrive.
                  QuizLockService.instance.clearSession();

                  _quizzedSubjectId = state.quizResponse.selectedSubjectId;
                  _quizzedSubjectName = state.quizResponse.selectedSubjectName;

                  final gardenState = context.read<GardenBloc>().state;
                  if (gardenState is GardenLoaded) {
                    _preQuizMastery = gardenState.plants
                        .where((p) => p.subjectId == _quizzedSubjectId)
                        .map((p) => p.masteryPercent)
                        .firstOrNull;
                  }
                  _waitingForGardenUpdate = true;

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
                    final delta =
                        pre != null ? newMastery - pre : null;

                    final message = (delta != null && delta > 0.05)
                        ? loc.masteryUpdateMessage(
                            _quizzedSubjectName ?? '',
                            pre!.toStringAsFixed(0),
                            newMastery.toStringAsFixed(0),
                            delta.toStringAsFixed(1),
                          )
                        : loc.masteryUpdatedSimpleMessage(
                            _quizzedSubjectName ?? '');

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(message),
                        duration: const Duration(seconds: 3),
                        backgroundColor: _kGreen,
                      ),
                    );
                  }
                },
                child: _buildBody(context, state),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, QuizState state) {
    final loc = AppLocalizations.of(context);
    if (state is QuizInitial) {
      return _AutoStartPanel(
        totalQuestions: widget.totalQuestions,
        autoLength: widget.autoLength,
        subjectId: widget.subjectId,
        studentGrade: widget.studentGrade,
        contextType: widget.contextType,
      );
    }
    if (state is QuizLoading) {
      return _LoadingView(message: loc.generatingQuizMessage);
    }
    if (state is QuizLoaded) {
      return _QuizActiveView(
        state: state,
        initialIndex: _restoredIndex,
        initialElapsedMs: _restoredElapsedMs,
        studentId: widget.studentId,
        contextType: widget.contextType,
        totalQuestions: widget.totalQuestions,
        autoLength: widget.autoLength,
        subjectId: widget.subjectId,
        studentGrade: widget.studentGrade,
      );
    }
    if (state is QuizSubmitting) {
      return _LoadingView(message: loc.submittingAnswersMessage);
    }
    if (state is QuizResultsLoaded) {
      return _ResultsView(state: state, studentId: widget.studentId);
    }
    if (state is QuizError) return _ErrorView(message: state.message);
    return const SizedBox.shrink();
  }
}

// ---------------------------------------------------------------------------
// Auto-start panel
// ---------------------------------------------------------------------------

class _AutoStartPanel extends StatelessWidget {
  final int totalQuestions;
  final bool autoLength;
  final int? subjectId;
  final int? studentGrade;
  final QuizContext contextType;

  const _AutoStartPanel({
    required this.totalQuestions,
    required this.contextType,
    this.autoLength = false,
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
            MascotWidget(state: MascotState.idle, size: 120),
            const SizedBox(height: 24),
            Text(
              loc.timeToPracticeTitle,
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
              loc.quizPromptMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
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
                        autoLength: autoLength,
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
                loc.startQuizButton,
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              loc.tailoredToLevelMessage,
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: _kMuted,
              ),
            ),
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
      const _AutoStartPanel(
          totalQuestions: 5, contextType: QuizContext.voluntary);
}

// ---------------------------------------------------------------------------
// Active quiz view
// ---------------------------------------------------------------------------

class _QuizActiveView extends StatefulWidget {
  final QuizLoaded state;

  // Restore position — 0 and 0 for fresh quizzes.
  final int initialIndex;
  final int initialElapsedMs;

  // Quiz params forwarded for session persistence.
  final String studentId;
  final QuizContext contextType;
  final int totalQuestions;
  final bool autoLength;
  final int? subjectId;
  final int? studentGrade;

  const _QuizActiveView({
    required this.state,
    required this.initialIndex,
    required this.initialElapsedMs,
    required this.studentId,
    required this.contextType,
    required this.totalQuestions,
    required this.autoLength,
    this.subjectId,
    this.studentGrade,
  });

  @override
  State<_QuizActiveView> createState() => _QuizActiveViewState();
}

class _QuizActiveViewState extends State<_QuizActiveView>
    with WidgetsBindingObserver {
  late int _currentIndex;
  int _hintsUsed = 0;

  String? _selectedOption;
  bool _revealed = false;

  DateTime? _questionStartedAt;
  // Timestamp set when the app enters the background mid-question. On resume,
  // _questionStartedAt is shifted forward by the background duration so that
  // timeTakenMs sent to the BKT engine reflects actual thinking time only.
  DateTime? _questionBackgroundedAt;
  final PageController _pageController = PageController();

  // Counts only active foreground time; paused whenever the app leaves
  // the foreground (background, lock screen, app switch).
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _ticker;

  // Elapsed time from a restored session. Added to the stopwatch value so
  // the timer display is continuous across interruptions.
  late int _extraElapsedMs;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _extraElapsedMs = widget.initialElapsedMs;

    // If restoring to a question that was already answered, show it as
    // revealed so the student sees the result before advancing.
    final savedAnswer =
        widget.state.currentAnswers[_currentQuestion.questionId];
    if (savedAnswer != null) {
      _selectedOption = savedAnswer.selectedOption;
      _revealed = true;
    }

    _questionStartedAt = DateTime.now();
    WidgetsBinding.instance.addObserver(this);
    _stopwatch.start();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });

    // PageController requires the widget to be laid out before we can jump.
    if (_currentIndex > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pageController.hasClients) {
          _pageController.jumpToPage(_currentIndex);
        }
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<MascotCubit>().startThinking();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopwatch.stop();
    _ticker?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        _stopwatch.stop();
        _questionBackgroundedAt = DateTime.now();
        _persistSession(context);
        // Foreground-recovery (bringToForeground) is handled once at the
        // _QuizOverlayScaffold level so it also covers the loading/submitting
        // states; here we only pause the stopwatch and persist progress.
        break;
      case AppLifecycleState.resumed:
        _stopwatch.start();
        // Shift _questionStartedAt forward by the time spent in the background
        // so that timeTakenMs for the current question excludes background idle.
        if (_questionBackgroundedAt != null && _questionStartedAt != null) {
          final backgrounded = DateTime.now().difference(_questionBackgroundedAt!);
          _questionStartedAt = _questionStartedAt!.add(backgrounded);
        }
        _questionBackgroundedAt = null;
        break;
      default:
        break;
    }
  }

  Duration get _totalElapsed =>
      Duration(milliseconds: _extraElapsedMs + _stopwatch.elapsedMilliseconds);

  String _formatElapsed(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  QuestionModel get _currentQuestion =>
      widget.state.quizResponse.questions[_currentIndex];

  bool get _isLastQuestion =>
      _currentIndex == widget.state.quizResponse.questions.length - 1;

  void _selectOption(String option) {
    if (_revealed) return;
    setState(() => _selectedOption = option);
  }

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

    // Save after the bloc has processed the answer (next frame).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _persistSession(context);
    });

    final isCorrect = _selectedOption == _currentQuestion.correctAnswer;
    context.read<MascotCubit>().react(isCorrect);
  }

  void _advance(BuildContext context) {
    if (_isLastQuestion) {
      // Clear the persistent session before submitting — quiz is finishing.
      QuizLockService.instance.clearSession();
      context.read<QuizBloc>().add(SubmitQuizEvent(
        widget.state.quizResponse.quizSessionId,
        totalElapsedMs: _totalElapsed.inMilliseconds,
      ));
      return;
    }
    context.read<MascotCubit>().startThinking();
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
    // Save the updated index after advancing.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _persistSession(context);
    });
  }

  // Persists the current session state to SharedPreferences via QuizLockService.
  void _persistSession(BuildContext context) {
    final blocState = context.read<QuizBloc>().state;
    if (blocState is! QuizLoaded) return;
    QuizLockService.instance.saveSession(QuizSessionData(
      quizResponse: blocState.quizResponse,
      answers: blocState.currentAnswers,
      currentIndex: _currentIndex,
      elapsedMs: _extraElapsedMs + _stopwatch.elapsedMilliseconds,
      studentId: widget.studentId,
      contextType: widget.contextType,
      totalQuestions: widget.totalQuestions,
      autoLength: widget.autoLength,
      subjectId: widget.subjectId,
      studentGrade: widget.studentGrade,
    ));
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
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: _kAmberLight,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.lightbulb_rounded,
                                color: _kAmber,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              loc.hintNumberTitle(hintNumber),
                              style: GoogleFonts.cairo(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: _kInk,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Directionality(
                          textDirection: _dirOf(hintText),
                          child: Text(
                            hintText,
                            textAlign: TextAlign.start,
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              height: 1.5,
                              color: _kInk,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  MascotWidget(state: MascotState.thinking, size: 72),
                ],
              ),
              const SizedBox(height: 20),
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
                    loc.gotItButton,
                    style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
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
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  BlocBuilder<MascotCubit, MascotState>(
                    builder: (context, mascotState) =>
                        MascotWidget(state: mascotState, size: 56),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    loc.questionOfTotalLabel(_currentIndex + 1, total),
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: _kMuted,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _kGreenLight,
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: _kGreen.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer_outlined,
                        size: 14, color: _kGreen),
                    const SizedBox(width: 4),
                    Text(
                      _formatElapsed(_totalElapsed),
                      style: GoogleFonts.cairo(
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
                    : answered[questions[index].questionId]
                        ?.selectedOption,
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
    final loc = AppLocalizations.of(context);
    final hintsExhausted = _hintsUsed >= _currentQuestion.hints.length;

    final String label;
    final VoidCallback? onPrimary;
    if (!_revealed) {
      label = loc.submitButton;
      onPrimary =
          _selectedOption != null ? () => _submitAnswer(context) : null;
    } else if (_isLastQuestion) {
      label = loc.finishButton;
      onPrimary = () => _advance(context);
    } else {
      label = loc.nextButton;
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
              loc.hintCountLabel(_hintsUsed),
              style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
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
              style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
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
          ...question.options.map(
            (opt) => _OptionTile(
              label: opt,
              isSelected: selectedOption == opt,
              isCorrect: opt == question.correctAnswer,
              revealed: revealed,
              onTap: () => onSelect(opt),
            ),
          ),
          if (revealed)
            _SolutionCard(
                question: question, isCorrect: isCorrectSelection),
        ],
      ),
    );
  }

  Widget _difficultyPill(AppLocalizations loc) {
    final color = _difficultyColor(question.difficulty);
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _difficultyLabel(loc, question.difficulty),
        style: GoogleFonts.cairo(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _skillChip() {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
      bg = _kGreen;
      border = _kGreen;
      fg = Colors.white;
      icon = Icons.check_circle;
      iconColor = Colors.white;
      emphasize = true;
    } else if (isSelected) {
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
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                    fontWeight:
                        emphasize ? FontWeight.w700 : FontWeight.w500,
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
// Solution / explanation card
// ---------------------------------------------------------------------------

class _SolutionCard extends StatelessWidget {
  final QuestionModel question;
  final bool isCorrect;

  const _SolutionCard({required this.question, required this.isCorrect});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final accent = isCorrect ? _kGreen : _kAmber;
    final bg = isCorrect ? _kGreenLight : _kAmberLight;
    final mascotEmotion =
        isCorrect ? MascotState.happy : MascotState.sad;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isCorrect
                          ? Icons.check_circle
                          : Icons.lightbulb_rounded,
                      size: 18,
                      color: accent,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isCorrect
                          ? loc.correctExclamationLabel
                          : loc.solutionLabel,
                      style: GoogleFonts.cairo(
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
                    loc.correctAnswerLabel,
                    style: GoogleFonts.cairo(
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
          ),
          const SizedBox(width: 12),
          MascotWidget(state: mascotEmotion, size: 72),
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
    final mascotState = score >= 85
        ? MascotState.celebration
        : score >= 50
            ? MascotState.happy
            : MascotState.sad;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          MascotWidget(state: mascotState, size: 140),
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
            loc.questionsCountLabel(state.result.totalQuestions),
            style: GoogleFonts.cairo(fontSize: 14, color: _kMuted),
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
              loc.doneButton,
              style: GoogleFonts.cairo(
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
              loc.takeAnotherQuizButton,
              style: GoogleFonts.cairo(
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: MascotWithBubble(
          state: MascotState.thinking,
          mascotSize: 100,
          message: message,
        ),
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
            Text(
              AppLocalizations.of(context).somethingWentWrongTitle,
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _kInk,
              ),
            ),
            const SizedBox(height: 16),
            MascotWithBubble(
              state: MascotState.sad,
              mascotSize: 90,
              message: message,
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
                AppLocalizations.of(context).tryAgainButton,
                style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
