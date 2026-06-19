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

  // ---------------------------------------------------------------------------
  // toJson
  // ---------------------------------------------------------------------------

  group('SubjectSummaryModel.toJson', () {
    test('serializes all fields correctly', () {
      const model = SubjectSummaryModel(
        subjectKey: 'math',
        subjectId: 5,
        colorHex: '#009688',
        skillsCount: 8,
        masteryPercent: 60,
        quizzesCompleted: 15,
        totalTimeSpent: Duration(seconds: 900),
        accuracyPercent: 70.0,
        isGlobal: false,
        isSelected: true,
      );

      final json = model.toJson();

      expect(json['subject_key'], 'math');
      expect(json['subject_id'], 5);
      expect(json['color_hex'], '#009688');
      expect(json['skills_count'], 8);
      expect(json['mastery_percent'], 60);
      expect(json['quizzes_completed'], 15);
      expect(json['total_time_spent_seconds'], 900);
      expect(json['accuracy_percent'], 70.0);
      expect(json['is_global'], false);
      expect(json['is_selected'], true);
    });
  });

  // ---------------------------------------------------------------------------
  // fromJson → toJson roundtrip
  // ---------------------------------------------------------------------------

  group('fromJson → toJson roundtrip', () {
    test('round-trips without data loss', () {
      final original = {
        'subject_key': 'science',
        'subject_id': 7,
        'color_hex': '#4CAF50',
        'skills_count': 6,
        'mastery_percent': 55,
        'quizzes_completed': 12,
        'total_time_spent_seconds': 1200,
        'accuracy_percent': 66.0,
        'is_global': true,
        'is_selected': false,
      };

      final model = SubjectSummaryModel.fromJson(original);
      final serialized = model.toJson();

      expect(serialized['subject_key'], original['subject_key']);
      expect(serialized['subject_id'], original['subject_id']);
      expect(serialized['mastery_percent'], original['mastery_percent']);
      expect(serialized['is_selected'], original['is_selected']);
      expect(
        serialized['total_time_spent_seconds'],
        original['total_time_spent_seconds'],
      );
    });
  });
}
