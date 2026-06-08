import 'package:flutter/material.dart';

/// A small pill-shaped badge showing an icon/emoji + value.
/// Used in the top nav bar for XP, Coins, and Level display.
class StatBadge extends StatelessWidget {
  /// Either an emoji string (e.g. '⚡') or null if [icon] is used.
  final String? emoji;

  /// Material icon — used when [emoji] is null.
  final IconData? icon;

  /// The value to display (e.g. '120', 'Lv.3').
  final String value;

  /// Accent color for the icon and border.
  final Color accentColor;

  /// Optional background color override.
  final Color? backgroundColor;

  const StatBadge({
    super.key,
    this.emoji,
    this.icon,
    required this.value,
    required this.accentColor,
    this.backgroundColor,
  }) : assert(emoji != null || icon != null, 'Provide either emoji or icon');

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? accentColor.withValues(alpha: 0.10);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (emoji != null)
            Text(emoji!, style: const TextStyle(fontSize: 14))
          else
            Icon(icon, size: 14, color: accentColor),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }
}
