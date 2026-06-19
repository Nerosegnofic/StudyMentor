// test/models/student_model_test.dart
//
// Unit tests for StudentModel — fromJson, copyWith, and optional fields.

import 'package:flutter_test/flutter_test.dart';
import 'package:studymentor/src/domain/models/student_model.dart';

void main() {
  // ---------------------------------------------------------------------------
  // fromJson
  // ---------------------------------------------------------------------------

  group('StudentModel.fromJson', () {
    test('parses all fields from a complete JSON object', () {
      final json = {
        'uid': 'uid-student',
        'full_name': 'Ali Hassan',
        'email': 'ali@school.com',
        'grade_level': 6,
        'total_xp': 450,
        'total_coins': 30,
        'is_email_verified': true,
        'created_at': '2024-01-10T00:00:00.000',
        'last_active_at': '2024-06-01T12:00:00.000',
      };

      final model = StudentModel.fromJson(json);

      expect(model.uid, 'uid-student');
      expect(model.fullName, 'Ali Hassan');
      expect(model.email, 'ali@school.com');
      expect(model.gradeLevel, 6);
      expect(model.totalXp, 450);
      expect(model.totalCoins, 30);
      expect(model.isEmailVerified, true);
      expect(model.createdAt, DateTime.parse('2024-01-10T00:00:00.000'));
      expect(
        model.lastActiveAt,
        DateTime.parse('2024-06-01T12:00:00.000'),
      );
    });

    test('defaults optional fields to null / false when absent', () {
      final json = {
        'uid': 'uid-minimal',
        'full_name': 'Minimal',
        'email': 'min@test.com',
      };

      final model = StudentModel.fromJson(json);

      expect(model.gradeLevel, isNull);
      expect(model.totalXp, isNull);
      expect(model.totalCoins, isNull);
      expect(model.isEmailVerified, isFalse);
      expect(model.createdAt, isNull);
      expect(model.lastActiveAt, isNull);
    });

    test('defaults is_email_verified to false when null in JSON', () {
      final json = {
        'uid': 'uid-x',
        'full_name': 'X',
        'email': 'x@test.com',
        'is_email_verified': null,
      };

      expect(StudentModel.fromJson(json).isEmailVerified, isFalse);
    });

    test('parses zero values for xp and coins', () {
      final json = {
        'uid': 'uid-zero',
        'full_name': 'Zero',
        'email': 'zero@test.com',
        'total_xp': 0,
        'total_coins': 0,
      };

      final model = StudentModel.fromJson(json);

      expect(model.totalXp, 0);
      expect(model.totalCoins, 0);
    });
  });

  // ---------------------------------------------------------------------------
  // copyWith
  // ---------------------------------------------------------------------------

  group('StudentModel.copyWith', () {
    final base = StudentModel(
      uid: 'uid-base',
      fullName: 'Original',
      email: 'original@test.com',
      isEmailVerified: false,
    );

    test('updates fullName while preserving other fields', () {
      final updated = base.copyWith(fullName: 'Updated');

      expect(updated.fullName, 'Updated');
      expect(updated.uid, 'uid-base');
      expect(updated.email, 'original@test.com');
      expect(updated.isEmailVerified, isFalse);
    });

    test('updates email while preserving other fields', () {
      final updated = base.copyWith(email: 'new@test.com');

      expect(updated.email, 'new@test.com');
      expect(updated.fullName, 'Original');
    });

    test('updates isEmailVerified to true', () {
      final updated = base.copyWith(isEmailVerified: true);

      expect(updated.isEmailVerified, isTrue);
      expect(updated.uid, base.uid);
    });

    test('returns unchanged model when no arguments provided', () {
      final copy = base.copyWith();

      expect(copy.uid, base.uid);
      expect(copy.fullName, base.fullName);
      expect(copy.email, base.email);
      expect(copy.isEmailVerified, base.isEmailVerified);
    });
  });
}
