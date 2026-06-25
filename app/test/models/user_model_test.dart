// test/models/user_model_test.dart
//
// Unit tests for UserModel — fromJson and field mapping.

import 'package:flutter_test/flutter_test.dart';
import 'package:studymentor/src/domain/models/user_model.dart';

void main() {
  group('UserModel.fromJson', () {
    test('parses all required fields correctly', () {
      final json = {
        'uid': 'uid-1',
        'email': 'user@test.com',
        'full_name': 'Test User',
        'role': 'parent',
      };

      final model = UserModel.fromJson(json);

      expect(model.uid, 'uid-1');
      expect(model.email, 'user@test.com');
      expect(model.fullName, 'Test User');
      expect(model.role, 'parent');
    });

    test('parses student role correctly', () {
      final json = {
        'uid': 'uid-s',
        'email': 'student@test.com',
        'full_name': 'Student',
        'role': 'student',
      };

      final model = UserModel.fromJson(json);

      expect(model.role, 'student');
    });

    test('preserves uid and email exactly as provided', () {
      final json = {
        'uid': 'special-uid-123',
        'email': 'special@domain.co.uk',
        'full_name': 'Special',
        'role': 'parent',
      };

      final model = UserModel.fromJson(json);

      expect(model.uid, 'special-uid-123');
      expect(model.email, 'special@domain.co.uk');
    });
  });
}
