import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studymentor/src/data/catalog/subject_metadata_registry.dart';

void main() {
  group('SubjectMetadataRegistry', () {
    test('returns predefined globals correctly', () {
      final mathDef = SubjectMetadataRegistry.getDefinition('math');
      expect(mathDef.name, 'Mathematics');
      expect(mathDef.emoji, '📐');
      expect(mathDef.defaultPlantType, 'tree');

      final englishDef = SubjectMetadataRegistry.getDefinition('English'); // case insensitive
      expect(englishDef.name, 'English');
      expect(englishDef.emoji, '📚');
      expect(englishDef.defaultPlantType, 'flower');
    });

    test('generates fallback metadata for unknown custom subjects', () {
      final customDef = SubjectMetadataRegistry.getDefinition('astronomy');
      
      expect(customDef.key, 'astronomy');
      expect(customDef.name, 'Astronomy');
      // Should pick some emoji from the fallback list
      expect(customDef.emoji.isNotEmpty, true);
      expect(customDef.defaultPlantType.isNotEmpty, true);
    });

    test('fallback metadata is completely deterministic', () {
      final def1 = SubjectMetadataRegistry.getDefinition('robotics');
      final def2 = SubjectMetadataRegistry.getDefinition('robotics');

      expect(def1.name, def2.name);
      expect(def1.emoji, def2.emoji);
      expect(def1.primaryColor.toARGB32(), def2.primaryColor.toARGB32());
      expect(def1.lightColor.toARGB32(), def2.lightColor.toARGB32());
      expect(def1.defaultPlantType, def2.defaultPlantType);
    });

    test('handles whitespace and varied casing smoothly', () {
      final def1 = SubjectMetadataRegistry.getDefinition('  Marine Biology  ');
      final def2 = SubjectMetadataRegistry.getDefinition('marine biology');
      
      expect(def1.name, 'Marine Biology');
      // Because it trims and lowercases, both should hash to the exact same fallback values
      expect(def1.emoji, def2.emoji);
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
