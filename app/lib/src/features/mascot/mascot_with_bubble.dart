import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'mascot_state.dart';
import 'mascot_widget.dart';
import '../../../l10n/app_localizations.dart';

Map<MascotState, String> _mascotDefaultMessages(AppLocalizations loc) => {
  MascotState.idle: loc.mascotIdleMessage,
  MascotState.happy: loc.mascotHappyMessage,
  MascotState.thinking: loc.mascotThinkingMessage,
  MascotState.sad: loc.mascotSadMessage,
  MascotState.celebration: loc.mascotCelebrationMessage,
};

/// Speech-bubble color theme per [MascotState] — follows the Study Mentor
/// design system: Primary Green for positive/growth states, Accent Amber
/// for gentle caution (sad), Secondary Blue for informational (thinking).
class _BubbleTheme {
  final Color background;
  final Color border;
  final Color text;
  const _BubbleTheme({
    required this.background,
    required this.border,
    required this.text,
  });
}

const _greenTheme = _BubbleTheme(
  background: Color(0xFFE8F5E9),
  border: Color(0xFF4CAF50), // Primary Green
  text: Color(0xFF1B5E20),
);

const _amberTheme = _BubbleTheme(
  background: Color(0xFFFFF8E1),
  border: Color(0xFFFFC107), // Accent Amber
  text: Color(0xFF8D6E00),
);

const Map<MascotState, _BubbleTheme> _kBubbleThemes = {
  MascotState.idle: _greenTheme,
  MascotState.happy: _greenTheme,
  MascotState.celebration: _greenTheme,
  MascotState.thinking: _greenTheme,
  MascotState.sad: _amberTheme,
};

/// Which side the mascot sits on relative to its speech bubble.
enum MascotBubbleSide { left, right }

/// Convenience widget combining a [MascotWidget] with a speech bubble in a
/// single horizontal layout.
///
/// The bubble always sits BESIDE the mascot — never stacked above it — so
/// every empty/error/loading state in the app shares the same conversational
/// layout instead of a generic centered icon + caption.
class MascotWithBubble extends StatelessWidget {
  final MascotState state;

  /// If null, falls back to [kMascotDefaultMessages] for [state].
  final String? message;

  final double mascotSize;
  final MascotBubbleSide side;

  /// Shows a small green spinner badge on the mascot's corner — used for
  /// loading states instead of a separate, disconnected progress indicator.
  /// Replaces the app's old purple [CircularProgressIndicator] everywhere a
  /// loading state pairs with the mascot.
  final bool showLoadingSpinner;

  const MascotWithBubble({
    super.key,
    required this.state,
    this.message,
    this.mascotSize = 72,
    this.side = MascotBubbleSide.left,
    this.showLoadingSpinner = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = _kBubbleThemes[state] ?? _greenTheme;
    final text = message ?? _mascotDefaultMessages(AppLocalizations.of(context))[state] ?? '';

    final mascot = !showLoadingSpinner
        ? MascotWidget(state: state, size: mascotSize)
        : Stack(
            clipBehavior: Clip.none,
            children: [
              MascotWidget(state: state, size: mascotSize),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Color(0xFF4CAF50), // Primary Green
                    ),
                  ),
                ),
              ),
            ],
          );

    final bubble = Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: theme.background,
          // Sharp corner on the side facing the mascot mimics a speech-
          // bubble tail without needing a custom painter.
          borderRadius: side == MascotBubbleSide.left
              ? const BorderRadius.only(
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                )
              : const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
          border: Border.all(color: theme.border.withValues(alpha: 0.35)),
        ),
        child: Text(
          text,
          textAlign: TextAlign.start,
          style: GoogleFonts.cairo(
            fontSize: 13,
            color: theme.text,
            height: 1.45,
          ),
        ),
      ),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: side == MascotBubbleSide.left
          ? [mascot, const SizedBox(width: 12), bubble]
          : [bubble, const SizedBox(width: 12), mascot],
    );
  }
}
