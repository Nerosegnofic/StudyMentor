// lib/src/data/repositories/auth_repository_impl.dart

import '../../domain/models/user_model.dart';
import '../../domain/models/student_model.dart';
import '../../domain/models/app_config_model.dart';
import '../../domain/models/installed_app_model.dart';
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
      await _markUserActive(uid: uid);
    }

    final profile = await dataConnect.getUserProfile(uid);
    return UserModel.fromJson(profile);
  }

  Future<void> _markUserActive({required String uid}) async {
    try {
      final profile = await dataConnect.getUserProfile(uid);
      final roleStr = profile['role'] as String;
      final role = roleStr == 'Parent' ? Role.Parent : Role.Student;

      final confirmedEmail = firebase.currentUser?.email;
      var builder = ExampleConnector.instance.upsertCurrentUser(role: role);
      if (confirmedEmail != null) {
        builder = builder.email(confirmedEmail);
      }
      await builder.execute();
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
    required String username,
  }) async {
    final parentEmail = firebase.currentUser?.email;
    final parentPassword = firebase.cachedPassword;

    if (parentEmail == null || parentPassword == null) {
      throw Exception(
        'Session expired. Please log out and log in again before adding a student.',
      );
    }

    // ── Username check FIRST — before touching Firebase Auth or the database.
    // This ensures nothing is partially created when the username is taken.
    // checkUsernameAvailable throws Exception('username-already-in-use') if
    // the username already exists, which _mapRegistrationException in
    // AuthBloc surfaces as a friendly message.
    await dataConnect.checkUsernameAvailable(username);

    try {
      await firebase.signUp(email, password);
      await dataConnect.createUserProfile(
        email: email,
        fullName: fullName,
        role: 'Student',
      );
      await dataConnect.createStudentProfile(
        parentUid: parentUid,
        username: username,
        gradeLevel: gradeLevel,
      );

      try {
        await ExampleConnector.instance.setUserInactive().execute();
      } catch (_) {}

      await firebase.sendEmailVerification();
      await firebase.signOut();
      await firebase.signInWithPassword(parentEmail, parentPassword);
    } catch (e) {
      // Registration failed after signUp() displaced the parent session.
      // Always attempt to restore it, then rethrow so AuthBloc can surface
      // the error. The username-already-in-use check above guarantees this
      // block is never reached for that specific case.
      try {
        await firebase.signOut();
        await firebase.signInWithPassword(parentEmail, parentPassword);
      } catch (_) {}
      rethrow;
    }

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
    if (authenticatedUid != linkedParentUid) throw Exception('parent-mismatch');
    return true;
  }

  @override
  Future<void> markEmailVerifiedInDatabase(String uid) async {
    await dataConnect.markEmailVerified();
  }

  // ── Profile update ────────────────────────────────────────────────────────

  @override
  Future<UserModel> updateProfile({
    String? newFullName,
    String? newEmail,
    String? currentPassword,
    String? newPassword,
  }) async {
    final user = firebase.currentUser;
    if (user == null) throw Exception('No authenticated user.');

    final profileSnapshot = await dataConnect.getUserProfile(user.uid);
    final roleStr = profileSnapshot['role'] as String;
    final role = roleStr == 'Parent' ? Role.Parent : Role.Student;

    final isChangingPassword =
        newPassword != null &&
        newPassword.isNotEmpty &&
        currentPassword != null;

    final isChangingEmail =
        newEmail != null && newEmail.isNotEmpty && newEmail != user.email;

    if ((isChangingPassword || isChangingEmail) && currentPassword != null) {
      await firebase.reauthenticate(currentPassword);
    }

    if (isChangingEmail) {
      await firebase.verifyBeforeUpdateEmail(newEmail);
    }

    if (isChangingPassword) {
      await firebase.updatePassword(newPassword);
    }

    if (newFullName != null && newFullName.isNotEmpty) {
      final builder = ExampleConnector.instance
          .upsertCurrentUser(role: role)
          .fullName(newFullName);
      await builder.execute();
    }

    await firebase.reloadUser();
    final updated = await dataConnect.getUserProfile(user.uid);
    return UserModel.fromJson(updated);
  }

  // ── Installed-App Inventory ───────────────────────────────────────────────

  @override
  Future<List<InstalledAppModel>> getInstalledAppsForStudent(
    String studentUid,
  ) async {
    final rows = await dataConnect.getInstalledAppsForStudent(studentUid);
    return rows.map(InstalledAppModel.fromJson).toList();
  }

  @override
  Future<void> syncInstalledAppsForStudent({
    required String studentUid,
    required List<InstalledAppModel> apps,
  }) async {
    await dataConnect.deleteAllInstalledAppsForStudent(studentUid);
    await Future.wait(
      apps.map(
        (app) => dataConnect.insertInstalledApp(
          studentUid: studentUid,
          packageName: app.packageName,
          appLabel: app.appLabel,
          isSystemApp: app.isSystemApp,
        ),
      ),
    );
  }

  // ── App Configuration ─────────────────────────────────────────────────────

  @override
  Future<({StudentConfigModel? config, List<AppRuleModel> rules})>
  getAppConfigForStudent(String studentUid) async {
    final result = await dataConnect.getAppConfigForStudent(studentUid);
    return (
      config: result.config,
      rules: result.rules.map(AppRuleModel.fromJson).toList(),
    );
  }

  @override
  Future<void> saveAppConfigForStudent({
    required String studentUid,
    required List<PendingAppRule> rules,
    required StudentConfigModel config,
  }) async {
    await dataConnect.upsertStudentConfig(
      studentUid: studentUid,
      config: config,
    );
    await dataConnect.deleteAllAppRulesForStudent(studentUid);
    for (final rule in rules) {
      await dataConnect.insertAppRule(
        studentUid: studentUid,
        packageName: rule.packageName,
        appLabel: rule.appLabel,
      );
    }
  }

  // ── Student Deletion ──────────────────────────────────────────────────────

  @override
  Future<void> deleteStudent({
    required String studentUid,
    required String studentEmail,
    required String studentPassword,
  }) async {
    await firebase.deleteStudentAuthAccount(
      studentEmail: studentEmail,
      studentPassword: studentPassword,
    );
    await dataConnect.deleteStudentAllData(studentUid);
  }

  // ── Student Full Name Update (parent-side) ────────────────────────────────

  @override
  Future<void> updateStudentFullName({
    required String studentUid,
    required String fullName,
  }) async {
    await dataConnect.updateStudentFullName(
      uid: studentUid,
      fullName: fullName,
    );
  }

  // ── Student Profile Update (parent-side: name + email + password) ─────────

  @override
  Future<String?> updateStudentProfile({
    required String studentUid,
    required String studentEmail,
    String? newFullName,
    String? newEmail,
    String? currentPassword,
    String? newPassword,
  }) async {
    if (newFullName != null && newFullName.isNotEmpty) {
      await dataConnect.updateStudentFullName(
        uid: studentUid,
        fullName: newFullName,
      );
    }

    final isChangingEmail =
        newEmail != null && newEmail.isNotEmpty && newEmail != studentEmail;
    final isChangingPassword = newPassword != null && newPassword.isNotEmpty;

    if ((isChangingEmail || isChangingPassword) && currentPassword != null) {
      return await firebase.updateStudentCredentials(
        studentEmail: studentEmail,
        currentPassword: currentPassword,
        newEmail: isChangingEmail ? newEmail : null,
        newPassword: isChangingPassword ? newPassword : null,
      );
    }

    return null;
  }

  // ── Parent Account Deletion ───────────────────────────────────────────────

  @override
  Future<void> deleteParentAccount({required String currentPassword}) async {
    if (firebase.currentUser == null) throw Exception('No authenticated user.');

    await firebase.reauthenticate(currentPassword);

    try {
      await dataConnect.deleteParentRecord();
    } catch (_) {}
    try {
      await ExampleConnector.instance.deleteUser().execute();
    } catch (_) {}

    await firebase.deleteCurrentUser();
  }
}
