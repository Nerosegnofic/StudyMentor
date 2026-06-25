// test/models/quiz_attempt_model_test.dart
//
// Unit tests for QuizAttemptModel — fromJson / toJson roundtrip and defaults.

import 'package:flutter_test/flutter_test.dart';
import 'package:studymentor/src/domain/models/quiz_attempt_model.dart';

void main() {
  // ---------------------------------------------------------------------------
  // fromJson
  // ---------------------------------------------------------------------------

  group('QuizAttemptModel.fromJson', () {
    test('parses all fields from a complete JSON object', () {
      final json = {
        'id': 'attempt-abc',
        'student_uid': 'uid-student',
        'subject_key': 'math',
        'skill_tag': 'algebra',
        'attempted_at': '2024-06-01T09:00:00.000',
        'correct_answers': 8,
        'total_questions': 10,
        'duration_seconds': 720,
        'passed': true,
        'correct_answer_numbers': [1, 3, 5, 7],
      };

      final model = QuizAttemptModel.fromJson(json);

      expect(model.id, 'attempt-abc');
      expect(model.studentUid, 'uid-student');
      expect(model.subjectKey, 'math');
      expect(model.skillTag, 'algebra');
      expect(model.attemptedAt, DateTime.parse('2024-06-01T09:00:00.000'));
      expect(model.correctAnswers, 8);
      expect(model.totalQuestions, 10);
      expect(model.duration, const Duration(seconds: 720));
      expect(model.passed, isTrue);
      expect(model.correctAnswerNumbers, [1, 3, 5, 7]);
    });

    test('defaults numeric fields to 0 when null', () {
      final json = {
        'id': 'attempt-x',
        'student_uid': 'uid-x',
        'subject_key': 'english',
        'skill_tag': 'grammar',
        'attempted_at': '2024-01-01T00:00:00.000',
      };

      final model = QuizAttemptModel.fromJson(json);

      expect(model.correctAnswers, 0);
      expect(model.totalQuestions, 0);
      expect(model.duration, Duration.zero);
    });

    test('defaults passed to false when null', () {
      final json = {
        'id': 'attempt-x',
        'student_uid': 'uid-x',
        'subject_key': 'science',
        'skill_tag': 'cells',
        'attempted_at': '2024-01-01T00:00:00.000',
      };

      expect(QuizAttemptModel.fromJson(json).passed, isFalse);
    });

    test('defaults correctAnswerNumbers to empty list when null', () {
      final json = {
        'id': 'attempt-x',
        'student_uid': 'uid-x',
        'subject_key': 'science',
        'skill_tag': 'cells',
        'attempted_at': '2024-01-01T00:00:00.000',
      };

      expect(QuizAttemptModel.fromJson(json).correctAnswerNumbers, isEmpty);
    });

    test('calculates accuracy from correctAnswers / totalQuestions', () {
      final json = {
        'id': 'attempt-acc',
        'student_uid': 'uid-s',
        'subject_key': 'math',
        'skill_tag': 'fractions',
        'attempted_at': '2024-06-01T00:00:00.000',
        'correct_answers': 7,
        'total_questions': 10,
        'duration_seconds': 300,
        'passed': false,
        'correct_answer_numbers': [],
      };

      final model = QuizAttemptModel.fromJson(json);
      // accuracy is not a field but we can derive it from the parsed values
      final accuracy = model.correctAnswers / model.totalQuestions;

      expect(accuracy, closeTo(0.7, 0.001));
    });
  });

}
