// lib/src/domain/repositories/auth_repository.dart

import '../models/user_model.dart';
import '../models/student_model.dart';
import '../models/app_config_model.dart';
import '../models/installed_app_model.dart';

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
    required String username,
  });
  Future<List<StudentModel>> getStudentsByParent(String parentUid);
  Future<String> getParentFullName(String studentUid);
  Future<List<StudentModel>> refreshStudentVerificationStatus(
    List<StudentModel> students,
  );
  Future<bool> verifyParentCredentials({
    required String studentUid,
    required String parentEmail,
    required String parentPassword,
  });
  Future<void> markEmailVerifiedInDatabase(String uid);

  /// Updates the current user's profile.
  /// [newEmail] triggers a verification email to the new address via Firebase.
  /// The DB row is updated immediately; Auth reflects it after verification.
  Future<UserModel> updateProfile({
    String? newFullName,
    String? newEmail, // ── ADDED ────────────────────────────────────
    String? currentPassword,
    String? newPassword,
  });

  Future<List<InstalledAppModel>> getInstalledAppsForStudent(String studentUid);
  Future<void> syncInstalledAppsForStudent({
    required String studentUid,
    required List<InstalledAppModel> apps,
  });
  Future<({StudentConfigModel? config, List<AppRuleModel> rules})>
  getAppConfigForStudent(String studentUid);
  Future<void> saveAppConfigForStudent({
    required String studentUid,
    required List<PendingAppRule> rules,
    required StudentConfigModel config,
  });

  Future<void> deleteStudent(String studentUid);
  Future<void> updateStudentFullName({
    required String studentUid,
    required String fullName,
  });
  Future<void> deleteParentAccount({required String currentPassword});

  /// Updates a student's account from the parent side.
  /// Returns pendingEmail if a verification email was sent, otherwise null.
  Future<String?> updateStudentProfile({
    required String studentUid,
    required String studentEmail,
    String? newFullName,
    String? newEmail,
    String? currentPassword,
    String? newPassword,
  });
}
