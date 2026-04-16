import '../../domain/models/user_model.dart';
import '../../domain/models/student_model.dart';
import '../../domain/repositories/auth_repository.dart';
import '../providers/firebase_auth_provider.dart';
import '../providers/dataconnect_provider.dart';

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
    final profile = await dataConnect.getUserProfile(uid);
    return UserModel.fromJson(profile);
  }

  @override
  Future<UserModel> createStudent({
    required String fullName,
    required String email,
    required String password,
    required String parentUid,
  }) async {
    final parentEmail = firebase.currentUser!.email!;
    final parentPassword = firebase.cachedPassword!;

    await firebase.signUp(email, password);

    await dataConnect.createUserProfile(
      email: email,
      fullName: fullName,
      role: 'Student',
    );
    await dataConnect.createStudentProfile(parentUid: parentUid);

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
    // Step 1: Look up the parent_uid linked to this student
    final linkedParentUid =
        await dataConnect.getParentUidForStudent(studentUid);

    // Step 2: Verify the supplied credentials using a secondary auth instance
    // This returns the UID of the authenticated user, or null on failure
    final authenticatedUid = await firebase.verifyCredentialsAndGetUid(
      parentEmail,
      parentPassword,
    );

    if (authenticatedUid == null) {
      // Credentials are invalid (wrong email/password)
      return false;
    }

    // Step 3: Ensure the authenticated UID matches the linked parent
    if (authenticatedUid != linkedParentUid) {
      // Valid credentials but they belong to a different user, not the linked parent
      throw Exception('parent-mismatch');
    }

    return true;
  }
}