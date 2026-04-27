// lib/src/data/repositories/auth_repository_impl.dart
//
// Key changes:
//  • createStudent() now marks the new student's user record as isActive=false
//    immediately after creation, using UpsertCurrentUser while the student's
//    Firebase session is still active (before we sign back in as the parent).
//  • refreshStudentVerificationStatus() polls DataConnect for each student's
//    isActive flag and maps it to StudentModel.isEmailVerified.
//  • signIn() calls upsertCurrentUser with isActive=true, which is the trigger
//    that flips a student's verification status after they verify their email
//    and log in for the first time.

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

    // Force reload to get fresh emailVerified status from Firebase
    await firebase.reloadUser();

    final isVerified = firebase.currentUser?.emailVerified ?? false;
    if (isVerified) {
      await _markUserActive(email: email, uid: uid);
    }

    final profile = await dataConnect.getUserProfile(uid);
    return UserModel.fromJson(profile);
  }

  /// Upserts the user record with isActive=true.  Called after a verified
  /// sign-in so DataConnect stays in sync with Firebase Auth.
  Future<void> _markUserActive({
    required String email,
    required String uid,
  }) async {
    // We need the user's role to satisfy the UpsertCurrentUser mutation.
    try {
      final profile = await dataConnect.getUserProfile(uid);
      final roleStr = profile['role'] as String;
      final role = roleStr == 'Parent' ? Role.Parent : Role.Student;
      await ExampleConnector.instance
          .upsertCurrentUser(email: email, role: role)
          .execute();
    } catch (_) {
      // Best-effort — don't break login if this fails.
    }
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

    // 1. Create the Firebase Auth account for the student.
    await firebase.signUp(email, password);

    // 2. While signed in as the new student, create DataConnect records.
    //    isActive defaults to `true` in the schema, so we immediately
    //    upsert it to `false` to flag the account as unverified.
    await dataConnect.createUserProfile(
      email: email,
      fullName: fullName,
      role: 'Student',
    );
    await dataConnect.createStudentProfile(
      parentUid: parentUid,
      gradeLevel: gradeLevel,
    );

    // 3. Mark the student as inactive (email not yet verified).
    try {
      await ExampleConnector.instance.setUserInactive().execute();
    } catch (_) {
      // Non-fatal.
    }

    // 4. Send the verification email while still signed in as the student.
    await firebase.sendEmailVerification();

    // 5. Sign back in as the parent.
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

  /// Polls DataConnect for the current `isActive` value of each student and
  /// returns an updated list.  Only students whose `isEmailVerified` is
  /// currently `false` are re-fetched to minimise network calls.
  @override
  Future<List<StudentModel>> refreshStudentVerificationStatus(
    List<StudentModel> students,
  ) async {
    final results = <StudentModel>[];
    for (final student in students) {
      if (student.isEmailVerified) {
        // Already verified — no need to re-check.
        results.add(student);
      } else {
        try {
          final isActive = await dataConnect.getIsActiveForUid(student.uid);
          results.add(student.copyWith(isEmailVerified: isActive));
        } catch (_) {
          results.add(student);
        }
      }
    }
    return results;
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
}
