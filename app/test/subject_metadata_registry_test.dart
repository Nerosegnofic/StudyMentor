import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studymentor/src/data/catalog/subject_metadata_registry.dart';

void main() {
  group('SubjectMetadataRegistry', () {
    test('returns a primary color for predefined globals', () {
      final mathDef = SubjectMetadataRegistry.getDefinition('math');
      expect(mathDef.primaryColor, isNotNull);

      final englishDef = SubjectMetadataRegistry.getDefinition('English');
      expect(englishDef.primaryColor, isNotNull);
    });

    test('generates fallback for unknown custom subjects', () {
      final customDef = SubjectMetadataRegistry.getDefinition('astronomy');
      expect(customDef.primaryColor, isNotNull);
    });

    test('fallback primary color is deterministic', () {
      final def1 = SubjectMetadataRegistry.getDefinition('robotics');
      final def2 = SubjectMetadataRegistry.getDefinition('robotics');

      expect(def1.primaryColor.toARGB32(), def2.primaryColor.toARGB32());
    });

    test('handles whitespace and varied casing smoothly', () {
      final def1 = SubjectMetadataRegistry.getDefinition('  Marine Biology  ');
      final def2 = SubjectMetadataRegistry.getDefinition('marine biology');

      expect(def1.primaryColor.toARGB32(), def2.primaryColor.toARGB32());
    });

    test('getSubjectIcon returns correct representative icons for global keys', () {
      expect(SubjectMetadataRegistry.getSubjectIcon('math'), Icons.calculate);
      expect(SubjectMetadataRegistry.getSubjectIcon('Mathematics'), Icons.calculate);
      expect(SubjectMetadataRegistry.getSubjectIcon('science'), Icons.science);
      expect(SubjectMetadataRegistry.getSubjectIcon('history'), Icons.history_edu);
      expect(SubjectMetadataRegistry.getSubjectIcon('english'), Icons.menu_book);
      expect(SubjectMetadataRegistry.getSubjectIcon('geography'), Icons.public);
      expect(SubjectMetadataRegistry.getSubjectIcon('art'), Icons.palette);
      expect(SubjectMetadataRegistry.getSubjectIcon('music'), Icons.music_note);
      expect(SubjectMetadataRegistry.getSubjectIcon('unknown_custom_subject'), isNull);
    });
  });
}
