// test/models/subject_summary_model_test.dart
//
// Unit tests for SubjectSummaryModel — fromJson / toJson roundtrip and defaults.

import 'package:flutter_test/flutter_test.dart';
import 'package:studymentor/src/domain/models/subject_summary_model.dart';

void main() {
  // ---------------------------------------------------------------------------
  // fromJson
  // ---------------------------------------------------------------------------

  group('SubjectSummaryModel.fromJson', () {
    test('parses all fields from a complete JSON object', () {
      final json = {
        'subject_key': 'math',
        'subject_id': 3,
        'color_hex': '#FF5722',
        'skills_count': 12,
        'mastery_percent': 75,
        'quizzes_completed': 20,
        'total_time_spent_seconds': 3600,
        'accuracy_percent': 82.5,
        'is_global': true,
        'is_selected': true,
      };

      final model = SubjectSummaryModel.fromJson(json);

      expect(model.subjectKey, 'math');
      expect(model.subjectId, 3);
      expect(model.colorHex, '#FF5722');
      expect(model.skillsCount, 12);
      expect(model.masteryPercent, 75);
      expect(model.quizzesCompleted, 20);
      expect(model.totalTimeSpent, const Duration(seconds: 3600));
      expect(model.accuracyPercent, 82.5);
      expect(model.isGlobal, isTrue);
      expect(model.isSelected, isTrue);
    });

    test('applies correct defaults when optional fields are absent', () {
      final json = {'subject_key': 'science'};

      final model = SubjectSummaryModel.fromJson(json);

      expect(model.subjectId, 0);
      expect(model.colorHex, '#2196F3');
      expect(model.skillsCount, 0);
      expect(model.masteryPercent, 0);
      expect(model.quizzesCompleted, 0);
      expect(model.totalTimeSpent, Duration.zero);
      expect(model.accuracyPercent, 0.0);
      expect(model.isGlobal, isFalse);
      expect(model.isSelected, isTrue);
    });

    test('defaults is_selected to true when null', () {
      final json = {
        'subject_key': 'english',
        'is_selected': null,
      };

      expect(SubjectSummaryModel.fromJson(json).isSelected, isTrue);
    });

    test('parses deselected subject correctly', () {
      final json = {
        'subject_key': 'arabic',
        'is_selected': false,
      };

      expect(SubjectSummaryModel.fromJson(json).isSelected, isFalse);
    });
  });

}
