import 'dart:convert';
import 'package:flutter/material.dart';

/// A circular app-icon bubble used for monitored ("watched") apps.
///
/// Renders the real app icon (Base64 PNG) when available, otherwise a
/// first-letter avatar. Extracted from the old private `_AppIcon` in
/// student_home.dart so the home rule list and the new strip share one widget.
class AppIconBubble extends StatelessWidget {
  /// Base64-encoded PNG of the app icon, or null/empty for the letter fallback.
  final String? iconBase64;

  /// Human-readable app name — used for the first-letter fallback.
  final String label;

  /// Outer diameter of the bubble.
  final double size;

  /// Border color of the ring.
  final Color borderColor;

  /// When true the bubble is faded to read as "sleeping / resting".
  final bool dimmed;

  const AppIconBubble({
    super.key,
    required this.iconBase64,
    required this.label,
    this.size = 44,
    this.borderColor = const Color(0xFF4CAF50),
    this.dimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    final innerRadius = (size / 2) - 3;
    return Opacity(
      opacity: dimmed ? 0.45 : 1.0,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: 2),
        ),
        child: _buildAvatar(innerRadius),
      ),
    );
  }

  Widget _buildAvatar(double radius) {
    if (iconBase64 != null && iconBase64!.isNotEmpty) {
      try {
        return CircleAvatar(
          backgroundImage: MemoryImage(base64Decode(iconBase64!)),
          backgroundColor: const Color(0xFFE8EDFF),
          radius: radius,
        );
      } catch (_) {/* fall through to letter avatar */}
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFE8EDFF),
      child: Text(
        label.isNotEmpty ? label[0].toUpperCase() : '?',
        style: TextStyle(
          color: const Color(0xFF2196F3),
          fontWeight: FontWeight.w700,
          fontSize: radius * 0.8,
        ),
      ),
    );
  }
}