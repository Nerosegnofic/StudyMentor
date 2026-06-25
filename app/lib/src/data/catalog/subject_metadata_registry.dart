import 'package:flutter/material.dart';

class SubjectDefinition {
  final Color primaryColor;

  const SubjectDefinition({required this.primaryColor});
}

class SubjectMetadataRegistry {
  static final Map<String, SubjectDefinition> _globals = {
    'math':      const SubjectDefinition(primaryColor: Color(0xFF1E88E5)),
    'science':   const SubjectDefinition(primaryColor: Color(0xFF43A047)),
    'history':   const SubjectDefinition(primaryColor: Color(0xFF8D6E63)),
    'english':   const SubjectDefinition(primaryColor: Color(0xFF5E35B1)),
    'geography': const SubjectDefinition(primaryColor: Color(0xFF00ACC1)),
    'art':       const SubjectDefinition(primaryColor: Color(0xFFE53935)),
    'music':     const SubjectDefinition(primaryColor: Color(0xFFFDD835)),
  };

  static final List<Color> _fallbackPalettes = [
    const Color(0xFF2196F3), // Blue
    const Color(0xFF4CAF50), // Green
    const Color(0xFF9C27B0), // Purple
    const Color(0xFFFF9800), // Orange
    const Color(0xFF009688), // Teal
  ];

  static SubjectDefinition getDefinition(String subjectKey) {
    final keyLower = subjectKey.toLowerCase().trim();
    if (_globals.containsKey(keyLower)) return _globals[keyLower]!;
    final color = _fallbackPalettes[keyLower.hashCode.abs() % _fallbackPalettes.length];
    return SubjectDefinition(primaryColor: color);
  }

  static IconData? getSubjectIcon(String subjectKey) {
    switch (subjectKey.toLowerCase().trim()) {
      case 'math':
      case 'mathematics':
        return Icons.calculate;
      case 'science':
        return Icons.science;
      case 'history':
        return Icons.history_edu;
      case 'english':
        return Icons.menu_book;
      case 'geography':
        return Icons.public;
      case 'art':
        return Icons.palette;
      case 'music':
        return Icons.music_note;
      default:
        return null;
    }
  }
}
