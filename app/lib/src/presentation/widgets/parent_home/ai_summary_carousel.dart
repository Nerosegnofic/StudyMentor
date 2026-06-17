import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../bloc/ai_summary/ai_summary_bloc.dart';
import '../../../bloc/ai_summary/ai_summary_event.dart';
import '../../../bloc/ai_summary/ai_summary_state.dart';
import '../../../domain/models/ai_summary_model.dart';
import '../../../domain/models/student_model.dart';

class AiSummaryCarousel extends StatefulWidget {
  final List<StudentModel> students;
  final void Function(StudentModel student) onChildTap;
  final int refreshKey;

  const AiSummaryCarousel({
    super.key,
    required this.students,
    required this.onChildTap,
    this.refreshKey = 0,
  });

  @override
  State<AiSummaryCarousel> createState() => _AiSummaryCarouselState();
}

class _AiSummaryCarouselState extends State<AiSummaryCarousel> {
  final _controller = PageController();
  int _currentPage = 0;
  Timer? _timer;

  List<AiSummarySlide> _slides = [];

  @override
  void initState() {
    super.initState();
    _dispatchLoad();
    _timer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted || _slides.length < 2) return;
      final next = (_currentPage + 1) % _slides.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void didUpdateWidget(covariant AiSummaryCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldUids = oldWidget.students.map((s) => s.uid).join(',');
    final newUids = widget.students.map((s) => s.uid).join(',');
    if (oldUids != newUids || oldWidget.refreshKey != widget.refreshKey) {
      _dispatchLoad();
    }
  }

  void _dispatchLoad() {
    context
        .read<AiSummaryBloc>()
        .add(LoadAiSummaryRequested(children: widget.students));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Color _severityColor(String severity) {
    switch (severity) {
      case 'good':
        return const Color(0xFF00897B); // teal
      case 'warn':
        return const Color(0xFFFFB300); // amber
      case 'high':
        return const Color(0xFFE53935); // red
      default:
        return const Color(0xFF2196F3); // info / blue
    }
  }

  StudentModel? _studentFor(String? childUid) {
    if (childUid == null) return null;
    for (final s in widget.students) {
      if (s.uid == childUid) return s;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return BlocBuilder<AiSummaryBloc, AiSummaryState>(
      builder: (context, state) {
        if (state is AiSummaryLoading || state is AiSummaryInitial) {
          return Container(
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 15),
            height: 180,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (state is AiSummaryLoaded) {
          _slides = state.summary.slides;
        } else {
          _slides = const [
            AiSummarySlide(text: "AI Summary not available.", severity: 'info'),
          ];
        }
        if (_slides.isEmpty) {
          _slides = const [
            AiSummarySlide(text: "No activity to summarize yet.", severity: 'info'),
          ];
        }
        if (_currentPage >= _slides.length) _currentPage = 0;

        return Container(
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0x4D2196F3), // rgba(33,150,243,0.30)
              width: 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A2196F3), // rgba(33,150,243,0.10)
                blurRadius: 20,
                offset: Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ───────────────────────────────────────────────────
              Row(
                children: [
                  Text(
                    '✨ AI Daily Summary',
                    style: GoogleFonts.cairo(
                      color: const Color(0xFF2196F3),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Smart Insights',
                      style: GoogleFonts.roboto(
                        color: const Color(0xFF2196F3),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Swipeable body (one slide per child + headline) ───────────
              SizedBox(
                height: 64,
                child: PageView.builder(
                  controller: _controller,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemCount: _slides.length,
                  itemBuilder: (_, i) {
                    final slide = _slides[i];
                    final student = _studentFor(slide.childUid);
                    final tappable = student != null;
                    return InkWell(
                      onTap: tappable ? () => widget.onChildTap(student) : null,
                      borderRadius: BorderRadius.circular(8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            width: 4,
                            decoration: BoxDecoration(
                              color: _severityColor(slide.severity),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                slide.text,
                                style: GoogleFonts.roboto(
                                  color: const Color(0xFF475569),
                                  fontSize: 14,
                                  height: 1.45,
                                ),
                              ),
                            ),
                          ),
                          if (tappable)
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: Color(0xFF94A3B8),
                              size: 20,
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // ── Pagination dots ───────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_slides.length, (i) {
                    final active = i == _currentPage;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 280),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 8,
                      width: active ? 20 : 8, // pill when active
                      decoration: BoxDecoration(
                        color: active
                            ? const Color(0xFF2196F3)
                            : const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}