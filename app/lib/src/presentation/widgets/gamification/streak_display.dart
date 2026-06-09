import 'package:flutter/material.dart';
import 'stat_badge.dart';

/// Displays the current streak using the StatBadge component.
class StreakDisplay extends StatelessWidget {
  final int currentStreak;
  final Color accentColor;

  const StreakDisplay({
    super.key,
    required this.currentStreak,
    this.accentColor = const Color(0xFFFF9800), // Amber color for flame
  });

  @override
  Widget build(BuildContext context) {
    return StatBadge(
      emoji: '🔥',
      value: currentStreak == 1 ? '1 day' : '$currentStreak days',
      accentColor: accentColor,
    );
  }
}
