// test/models/user_model_test.dart
//
// Unit tests for UserModel — fromJson / toJson roundtrip and field mapping.

import 'package:flutter_test/flutter_test.dart';
import 'package:studymentor/src/domain/models/user_model.dart';

void main() {
  // ---------------------------------------------------------------------------
  // fromJson
  // ---------------------------------------------------------------------------

  group('UserModel.fromJson', () {
    test('parses all required fields correctly', () {
      final json = {
        'uid': 'uid-1',
        'email': 'user@test.com',
        'full_name': 'Test User',
        'role': 'parent',
        'is_active': true,
        'created_at': '2024-01-15T10:00:00.000',
      };

      final model = UserModel.fromJson(json);

      expect(model.uid, 'uid-1');
      expect(model.email, 'user@test.com');
      expect(model.fullName, 'Test User');
      expect(model.role, 'parent');
      expect(model.isActive, true);
      expect(model.createdAt, DateTime.parse('2024-01-15T10:00:00.000'));
    });

    test('parses student role correctly', () {
      final json = {
        'uid': 'uid-s',
        'email': 'student@test.com',
        'full_name': 'Student',
        'role': 'student',
        'is_active': true,
        'created_at': '2024-03-01T00:00:00.000',
      };

      final model = UserModel.fromJson(json);

      expect(model.role, 'student');
    });

    test('parses is_active = false correctly', () {
      final json = {
        'uid': 'uid-x',
        'email': 'x@test.com',
        'full_name': 'X',
        'role': 'parent',
        'is_active': false,
        'created_at': '2024-01-01T00:00:00.000',
      };

      expect(UserModel.fromJson(json).isActive, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // toJson
  // ---------------------------------------------------------------------------

  group('UserModel.toJson', () {
    test('serializes all fields correctly', () {
      final model = UserModel(
        uid: 'uid-1',
        email: 'user@test.com',
        fullName: 'Test User',
        role: 'parent',
        isActive: true,
        createdAt: DateTime.parse('2024-01-15T10:00:00.000'),
      );

      final json = model.toJson();

      expect(json['uid'], 'uid-1');
      expect(json['email'], 'user@test.com');
      expect(json['full_name'], 'Test User');
      expect(json['role'], 'parent');
      expect(json['is_active'], true);
      expect(json['created_at'], '2024-01-15T10:00:00.000');
    });
  });

  // ---------------------------------------------------------------------------
  // fromJson → toJson roundtrip
  // ---------------------------------------------------------------------------

  group('fromJson → toJson roundtrip', () {
    test('round-trips without data loss', () {
      final original = {
        'uid': 'uid-round',
        'email': 'round@test.com',
        'full_name': 'Round Trip',
        'role': 'student',
        'is_active': true,
        'created_at': '2024-06-01T08:30:00.000',
      };

      final model = UserModel.fromJson(original);
      final serialized = model.toJson();

      expect(serialized['uid'], original['uid']);
      expect(serialized['email'], original['email']);
      expect(serialized['full_name'], original['full_name']);
      expect(serialized['role'], original['role']);
      expect(serialized['is_active'], original['is_active']);
    });
  });
}
