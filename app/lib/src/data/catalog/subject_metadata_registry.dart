import 'package:flutter/material.dart';

class SubjectDefinition {
  final String key;
  final String name;
  final String emoji;
  final Color primaryColor;
  final Color lightColor;
  final String defaultPlantType;

  const SubjectDefinition({
    required this.key,
    required this.name,
    required this.emoji,
    required this.primaryColor,
    required this.lightColor,
    required this.defaultPlantType,
  });
}

class SubjectMetadataRegistry {
  static final Map<String, SubjectDefinition> _globals = {
    'math': const SubjectDefinition(
      key: 'math',
      name: 'Mathematics',
      emoji: '📐',
      primaryColor: Color(0xFF1E88E5), // Blue 600
      lightColor: Color(0xFFBBDEFB),   // Blue 100
      defaultPlantType: 'tree',
    ),
    'science': const SubjectDefinition(
      key: 'science',
      name: 'Science',
      emoji: '🔬',
      primaryColor: Color(0xFF43A047), // Green 600
      lightColor: Color(0xFFC8E6C9),   // Green 100
      defaultPlantType: 'bush',
    ),
    'history': const SubjectDefinition(
      key: 'history',
      name: 'History',
      emoji: '🏛️',
      primaryColor: Color(0xFF8D6E63), // Brown 400
      lightColor: Color(0xFFD7CCC8),   // Brown 100
      defaultPlantType: 'tree',
    ),
    'english': const SubjectDefinition(
      key: 'english',
      name: 'English',
      emoji: '📚',
      primaryColor: Color(0xFF5E35B1), // Deep Purple 600
      lightColor: Color(0xFFD1C4E9),   // Deep Purple 100
      defaultPlantType: 'flower',
    ),
    'geography': const SubjectDefinition(
      key: 'geography',
      name: 'Geography',
      emoji: '🌍',
      primaryColor: Color(0xFF00ACC1), // Cyan 600
      lightColor: Color(0xFFB2EBF2),   // Cyan 100
      defaultPlantType: 'bush',
    ),
    'art': const SubjectDefinition(
      key: 'art',
      name: 'Art',
      emoji: '🎨',
      primaryColor: Color(0xFFE53935), // Red 600
      lightColor: Color(0xFFFFCDD2),   // Red 100
      defaultPlantType: 'flower',
    ),
    'music': const SubjectDefinition(
      key: 'music',
      name: 'Music',
      emoji: '🎵',
      primaryColor: Color(0xFFFDD835), // Yellow 600
      lightColor: Color(0xFFFFF9C4),   // Yellow 100
      defaultPlantType: 'flower',
    ),
  };

  static final List<String> _fallbackEmojis = [
    '🌱', '🪴', '📖', '🧠', '🧩', '🚀', '🌿', '🌲', '🎓', '💡'
  ];

  static final List<String> _fallbackPlantTypes = [
    'tree', 'bush', 'flower'
  ];

  static final List<MapEntry<Color, Color>> _fallbackPalettes = [
    const MapEntry(Color(0xFF2196F3), Color(0xFFBBDEFB)), // Blue
    const MapEntry(Color(0xFF4CAF50), Color(0xFFC8E6C9)), // Green
    const MapEntry(Color(0xFF9C27B0), Color(0xFFE1BEE7)), // Purple
    const MapEntry(Color(0xFFFF9800), Color(0xFFFFE0B2)), // Orange
    const MapEntry(Color(0xFF009688), Color(0xFFB2DFDB)), // Teal
  ];

  static String _toTitleCase(String text) {
    if (text.isEmpty) return text;
    return text.split(RegExp(r'[_\s-]+')).map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  static SubjectDefinition getDefinition(String subjectKey) {
    final keyLower = subjectKey.toLowerCase().trim();

    // 1. Predefined Globals
    if (_globals.containsKey(keyLower)) {
      return _globals[keyLower]!;
    }

    // 2. Deterministic Generation (The Fallback)
    final int hash = keyLower.hashCode.abs();
    
    final String name = _toTitleCase(keyLower);
    final String emoji = _fallbackEmojis[hash % _fallbackEmojis.length];
    
    final String defaultPlantType = _fallbackPlantTypes[hash % _fallbackPlantTypes.length];
    
    final palette = _fallbackPalettes[hash % _fallbackPalettes.length];

    return SubjectDefinition(
      key: subjectKey,
      name: name,
      emoji: emoji,
      primaryColor: palette.key,
      lightColor: palette.value,
      defaultPlantType: defaultPlantType,
    );
  }

  static IconData? getSubjectIcon(String subjectKey) {
    final keyLower = subjectKey.toLowerCase().trim();
    switch (keyLower) {
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
