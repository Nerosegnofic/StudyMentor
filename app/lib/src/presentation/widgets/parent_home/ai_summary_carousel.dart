import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/ai_summary/ai_summary_bloc.dart';
import '../../../bloc/ai_summary/ai_summary_event.dart';
import '../../../bloc/ai_summary/ai_summary_state.dart';
import '../../../../l10n/app_localizations.dart';

class AiSummaryCarousel extends StatefulWidget {
  final String parentUid;

  const AiSummaryCarousel({super.key, required this.parentUid});

  @override
  State<AiSummaryCarousel> createState() => _AiSummaryCarouselState();
}

class _AiSummaryCarouselState extends State<AiSummaryCarousel> {
  final _controller = PageController();
  int _currentPage = 0;
  Timer? _timer;

  List<String> _slides = [];

  @override
  void initState() {
    super.initState();
    context.read<AiSummaryBloc>().add(LoadAiSummaryRequested(parentUid: widget.parentUid));
    _timer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted) return;
      final next = (_currentPage + 1) % _slides.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
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
          _slides = [loc.aiSummaryNotAvailableMessage];
        }

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
              Expanded(
                child: Text(
                  loc.aiDailySummaryTitle,
                  style: GoogleFonts.cairo(
                    color: const Color(0xFF2196F3),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  loc.smartInsightsLabel,
                  style: GoogleFonts.cairo(
                    color: const Color(0xFF2196F3),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Swipeable body text ───────────────────────────────────────
          SizedBox(
            height: 64,
            child: PageView.builder(
              controller: _controller,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemCount: _slides.length,
              itemBuilder: (_, i) => Text(
                _slides[i],
                style: GoogleFonts.cairo(
                  color: const Color(0xFF475569),
                  fontSize: 14,
                  height: 1.55,
                ),
              ),
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
