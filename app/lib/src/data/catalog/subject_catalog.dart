import 'package:flutter/material.dart';

/// Identifies the plant shape rendered in [PlantWidget].
enum PlantType { tree, flower, bush, magicPlant }

/// Static definition of a subject (client-side only, not stored in DB).
class SubjectDefinition {
  final String key;
  final String name;
  final String emoji;
  final PlantType plantType;
  final Color primaryColor;
  final Color lightColor;
  final List<String> skillKeys;

  const SubjectDefinition({
    required this.key,
    required this.name,
    required this.emoji,
    required this.plantType,
    required this.primaryColor,
    required this.lightColor,
    required this.skillKeys,
  });
}

/// Catalog of all supported subjects.
/// Adding a new subject = adding one entry here — no other changes needed.
class SubjectCatalog {
  SubjectCatalog._();

  static const List<SubjectDefinition> all = [
    SubjectDefinition(
      key: 'math',
      name: 'Math',
      emoji: '🌳',
      plantType: PlantType.tree,
      primaryColor: Color(0xFF2E7D32),
      lightColor: Color(0xFFE8F5E9),
      skillKeys: ['multiplication', 'division', 'fractions', 'algebra', 'geometry'],
    ),
    SubjectDefinition(
      key: 'science',
      name: 'Science',
      emoji: '🌸',
      plantType: PlantType.flower,
      primaryColor: Color(0xFFAD1457),
      lightColor: Color(0xFFFCE4EC),
      skillKeys: ['biology', 'chemistry', 'physics', 'earth_science', 'ecology'],
    ),
    SubjectDefinition(
      key: 'history',
      name: 'History',
      emoji: '🌿',
      plantType: PlantType.bush,
      primaryColor: Color(0xFF558B2F),
      lightColor: Color(0xFFF1F8E9),
      skillKeys: ['ancient_history', 'world_wars', 'geography', 'civilizations', 'modern_history'],
    ),
    SubjectDefinition(
      key: 'english',
      name: 'English',
      emoji: '✨',
      plantType: PlantType.magicPlant,
      primaryColor: Color(0xFF6A1B9A),
      lightColor: Color(0xFFF3E5F5),
      skillKeys: ['reading', 'writing', 'grammar', 'vocabulary', 'comprehension'],
    ),
  ];

  static final Map<String, SubjectDefinition> _byKey = {
    for (final s in all) s.key: s,
  };

  static SubjectDefinition? byKey(String key) => _byKey[key];

  /// Human-readable skill name from its key.
  static String skillName(String skillKey) {
    return skillKey
        .split('_')
        .map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }
}
