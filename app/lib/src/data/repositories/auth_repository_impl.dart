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

  /// Marks the user active in the DB and syncs their verified Firebase Auth
  /// email. This is the point where a verified email change is committed to
  /// the DB — Firebase Auth's email is the source of truth here.
  Future<void> _markUserActive({required String uid}) async {
    try {
      final profile = await dataConnect.getUserProfile(uid);
      final roleStr = profile['role'] as String;
      final role = roleStr == 'Parent' ? Role.Parent : Role.Student;

      // ── Sync the confirmed Firebase Auth email to the DB ─────────────────
      // If the user previously requested an email change and has now verified
      // it, firebase.currentUser.email will already reflect the new address.
      // Passing it here commits it to the DB at the first login after
      // verification — without ever writing an unverified address.
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

    // ── Read role FIRST, before any Firebase Auth mutations ───────────────
    // verifyBeforeUpdateEmail can invalidate the ID token; reading the DB
    // before that call guarantees a clean session.
    final profileSnapshot = await dataConnect.getUserProfile(user.uid);
    final roleStr = profileSnapshot['role'] as String;
    final role = roleStr == 'Parent' ? Role.Parent : Role.Student;

    final isChangingPassword =
        newPassword != null &&
        newPassword.isNotEmpty &&
        currentPassword != null;

    final isChangingEmail =
        newEmail != null && newEmail.isNotEmpty && newEmail != user.email;

    // Re-auth is required for both email and password changes.
    if ((isChangingPassword || isChangingEmail) && currentPassword != null) {
      await firebase.reauthenticate(currentPassword);
    }

    // Send verification to the new address. Firebase applies the change
    // only after the user clicks the link in the email. We intentionally
    // do NOT write the new email to the DB here — the DB is updated in
    // _markUserActive on the next login after verification, at which point
    // Firebase Auth's email is already the confirmed new address.
    if (isChangingEmail) {
      await firebase.verifyBeforeUpdateEmail(newEmail);
    }

    if (isChangingPassword) {
      await firebase.updatePassword(newPassword);
    }

    // Only write name changes to the DB. Email is intentionally excluded
    // to prevent the UI from showing an unverified address.
    if (newFullName != null && newFullName.isNotEmpty) {
      final builder = ExampleConnector.instance
          .upsertCurrentUser(role: role)
          .fullName(newFullName);
      await builder.execute();
    }

    // Reload before the final read to ensure a fresh token.
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
          iconBase64: app.iconBase64,
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
        iconBase64: rule.iconBase64,
      );
    }
  }
}
