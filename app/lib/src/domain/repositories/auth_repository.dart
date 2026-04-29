// lib/src/domain/repositories/auth_repository.dart

import '../models/user_model.dart';
import '../models/student_model.dart';

abstract class AuthRepository {
  Future<UserModel> signUp({
    required String fullName,
    required String email,
    required String password,
  });
  Future<UserModel> signIn({required String email, required String password});
  Future<void> sendEmailVerification();
  Future<bool> isEmailVerified();
  Future<void> signOut();
  Future<void> sendPasswordReset(String email);
  Future<UserModel?> getUserProfile();
  Future<UserModel> createStudent({
    required String fullName,
    required String email,
    required String password,
    required String parentUid,
    required int gradeLevel,
  });
  Future<List<StudentModel>> getStudentsByParent(String parentUid);
  Future<String> getParentFullName(String studentUid);

  /// Refreshes the email-verification status for each student in [students].
  Future<List<StudentModel>> refreshStudentVerificationStatus(
    List<StudentModel> students,
  );

  /// Verifies parent credentials for a given student.
  Future<bool> verifyParentCredentials({
    required String studentUid,
    required String parentEmail,
    required String parentPassword,
  });

  Future<void> markEmailVerifiedInDatabase(String uid);

  /// Updates the current user's profile.
  ///
  /// - [newFullName]: if provided, updates the display name in DataConnect.
  /// - [currentPassword]: required when [newPassword] is provided; used to
  ///   reauthenticate with Firebase before changing the password.
  /// - [newPassword]: if provided (along with [currentPassword]), updates the
  ///   Firebase Auth password.
  ///
  /// Returns the updated [UserModel] so the BLoC can refresh [AuthAuthenticated].
  Future<UserModel> updateProfile({
    String? newFullName,
    String? currentPassword,
    String? newPassword,
  });
}
