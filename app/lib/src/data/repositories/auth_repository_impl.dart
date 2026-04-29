// lib/src/data/repositories/auth_repository_impl.dart

import '../../domain/models/user_model.dart';
import '../../domain/models/student_model.dart';
import '../../domain/repositories/auth_repository.dart';
import '../providers/firebase_auth_provider.dart';
import '../providers/dataconnect_provider.dart';
import '../../../dataconnect_generated/generated.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuthProvider firebase;
  final DataConnectProvider dataConnect;

  AuthRepositoryImpl({required this.firebase, required this.dataConnect});

  @override
  Future<UserModel> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final cred = await firebase.signUp(email, password);
    final uid = cred.user!.uid;
    await firebase.sendEmailVerification();
    await dataConnect.createUserProfile(
      email: email,
      fullName: fullName,
      role: 'Parent',
    );
    await dataConnect.createParentProfile();
    final profile = await dataConnect.getUserProfile(uid);
    return UserModel.fromJson(profile);
  }

  @override
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    await firebase.signIn(email, password);
    final uid = firebase.currentUser!.uid;

    await firebase.reloadUser();

    final isVerified = firebase.currentUser?.emailVerified ?? false;
    if (isVerified) {
      await _markUserActive(email: email, uid: uid);
    }

    final profile = await dataConnect.getUserProfile(uid);
    return UserModel.fromJson(profile);
  }

  Future<void> _markUserActive({
    required String email,
    required String uid,
  }) async {
    try {
      final profile = await dataConnect.getUserProfile(uid);
      final roleStr = profile['role'] as String;
      final role = roleStr == 'Parent' ? Role.Parent : Role.Student;
      await ExampleConnector.instance
          .upsertCurrentUser(email: email, role: role)
          .execute();
    } catch (_) {}

    try {
      await dataConnect.markEmailVerified();
    } catch (_) {}
  }

  @override
  Future<UserModel> createStudent({
    required String fullName,
    required String email,
    required String password,
    required String parentUid,
    required int gradeLevel,
  }) async {
    final parentEmail = firebase.currentUser?.email;
    final parentPassword = firebase.cachedPassword;

    if (parentEmail == null || parentPassword == null) {
      throw Exception(
        'Session expired. Please log out and log in again before adding a student.',
      );
    }

    await firebase.signUp(email, password);

    await dataConnect.createUserProfile(
      email: email,
      fullName: fullName,
      role: 'Student',
    );
    await dataConnect.createStudentProfile(
      parentUid: parentUid,
      gradeLevel: gradeLevel,
    );

    try {
      await ExampleConnector.instance.setUserInactive().execute();
    } catch (_) {}

    await firebase.sendEmailVerification();

    await firebase.signOut();
    await firebase.signInWithPassword(parentEmail, parentPassword);

    final uid = firebase.currentUser!.uid;
    final profile = await dataConnect.getUserProfile(uid);
    return UserModel.fromJson(profile);
  }

  @override
  Future<List<StudentModel>> getStudentsByParent(String parentUid) async {
    final students = await dataConnect.getStudentsByParent(parentUid);
    return students.map(StudentModel.fromJson).toList();
  }

  @override
  Future<List<StudentModel>> refreshStudentVerificationStatus(
    List<StudentModel> students,
  ) async {
    if (students.isEmpty) return students;

    final parentUid = await dataConnect.getParentUidForStudent(
      students.first.uid,
    );
    return await getStudentsByParent(parentUid);
  }

  @override
  Future<void> sendEmailVerification() => firebase.sendEmailVerification();

  @override
  Future<bool> isEmailVerified() async {
    await firebase.reloadUser();
    return firebase.currentUser?.emailVerified ?? false;
  }

  @override
  Future<void> signOut() => firebase.signOut();

  @override
  Future<void> sendPasswordReset(String email) =>
      firebase.sendPasswordReset(email);

  @override
  Future<UserModel?> getUserProfile() async {
    final user = firebase.currentUser;
    if (user == null) return null;
    final profile = await dataConnect.getUserProfile(user.uid);
    return UserModel.fromJson(profile);
  }

  @override
  Future<String> getParentFullName(String studentUid) =>
      dataConnect.getParentFullName(studentUid);

  @override
  Future<bool> verifyParentCredentials({
    required String studentUid,
    required String parentEmail,
    required String parentPassword,
  }) async {
    final linkedParentUid = await dataConnect.getParentUidForStudent(
      studentUid,
    );

    final authenticatedUid = await firebase.verifyCredentialsAndGetUid(
      parentEmail,
      parentPassword,
    );

    if (authenticatedUid == null) return false;

    if (authenticatedUid != linkedParentUid) {
      throw Exception('parent-mismatch');
    }

    return true;
  }

  @override
  Future<void> markEmailVerifiedInDatabase(String uid) async {
    await dataConnect.markEmailVerified();
  }

  // ── profile update ──────────────────────────────────────────────────────────

  @override
  Future<UserModel> updateProfile({
    String? newFullName,
    String? currentPassword,
    String? newPassword,
  }) async {
    final user = firebase.currentUser;
    if (user == null) throw Exception('No authenticated user.');

    final isChangingPassword =
        newPassword != null &&
        newPassword.isNotEmpty &&
        currentPassword != null;

    // Step 1: Reauthenticate if a password change is requested.
    // Firebase requires a recent login before sensitive operations.
    if (isChangingPassword) {
      await firebase.reauthenticate(currentPassword);
    }

    // Step 2: Update password in Firebase Auth.
    if (isChangingPassword) {
      await firebase.updatePassword(newPassword);
    }

    // Step 3: Update full name in DataConnect via UpsertCurrentUser.
    // We only call this if the name has actually changed.
    if (newFullName != null && newFullName.isNotEmpty) {
      final profile = await dataConnect.getUserProfile(user.uid);
      final roleStr = profile['role'] as String;
      final role = roleStr == 'Parent' ? Role.Parent : Role.Student;

      await ExampleConnector.instance
          .upsertCurrentUser(email: user.email!, role: role)
          .fullName(newFullName)
          .execute();
    }

    // Step 4: Return the freshly fetched profile so AuthAuthenticated is up to date.
    final updated = await dataConnect.getUserProfile(user.uid);
    return UserModel.fromJson(updated);
  }
}
