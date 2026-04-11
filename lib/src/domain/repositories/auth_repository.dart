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
  });
  Future<List<StudentModel>> getStudentsByParent(String parentUid);
  Future<String> getParentFullName(String studentUid);
}
