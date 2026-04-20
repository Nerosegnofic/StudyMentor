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

  /// Verifies that the provided email/password belong to the parent
  /// linked to the given student via `parent_uid`.
  /// Returns `true` if credentials are valid and match the linked parent.
  Future<bool> verifyParentCredentials({
    required String studentUid,
    required String parentEmail,
    required String parentPassword,
  });
}
