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
  Future<UserModel> updateProfile({
    String? newFullName,
    String? currentPassword,
    String? newPassword,
  });

  // ── Installed-App Inventory ───────────────────────────────────────────────

  /// Returns the installed-app inventory for [studentUid] from DataConnect.
  /// Called by the parent's app-picker.
  Future<List<InstalledAppModel>> getInstalledAppsForStudent(String studentUid);

  /// Replaces the student's entire inventory in DataConnect with [apps].
  /// Called by the student device on login and on dirty-flag resume.
  Future<void> syncInstalledAppsForStudent({
    required String studentUid,
    required List<InstalledAppModel> apps,
  });

  // ── App Configuration ─────────────────────────────────────────────────────

  /// Fetches all saved app rules for a given student.
  /// Called by both the parent config screen and the student device.
  Future<List<AppRuleModel>> getAppRulesForStudent(String studentUid);

  /// Saves (replaces) all app rules for a student.
  ///
  /// The strategy is delete-all + re-insert so the parent always gets a
  /// clean save regardless of what changed. Steps:
  ///  1. Upsert the AppConfig record (creates it if it does not exist).
  ///  2. Delete all existing AppRule rows for this student.
  ///  3. Insert each rule in [rules] one by one.
  Future<void> saveAppRulesForStudent({
    required String studentUid,
    required List<PendingAppRule> rules,
  });
}
