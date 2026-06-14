// lib/src/data/repositories/auth_repository_impl.dart

import 'package:flutter/foundation.dart';
import '../../domain/models/user_model.dart';
import '../../domain/models/student_model.dart';
import '../../domain/models/app_config_model.dart';
import '../../domain/models/installed_app_model.dart';
import '../../domain/models/subject_summary_model.dart';
import '../../domain/models/quiz_attempt_model.dart';
import '../../domain/models/question_detail_model.dart';
import '../../domain/models/skill_progress_model.dart';
import '../../domain/models/ai_summary_model.dart';
import '../../domain/models/notification_model.dart';
import '../../domain/models/report_models.dart';
import '../../domain/repositories/auth_repository.dart';
import '../providers/firebase_auth_provider.dart';
import '../providers/dataconnect_provider.dart';
import '../../../dataconnect_generated/generated.dart';
import 'ai_engine_repository.dart';

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

    // Username check FIRST — before touching Firebase Auth or the database.
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
    final parentUid = await _getParentUidForStudent(students.first.uid);
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
    final linkedParentUid = await _getParentUidForStudent(studentUid);
    final authenticatedUid = await firebase.verifyCredentialsAndGetUid(
      parentEmail,
      parentPassword,
    );
    if (authenticatedUid == null) return false;
    if (authenticatedUid != linkedParentUid) return false;
    return true;
  }

  Future<String> _getParentUidForStudent(String studentUid) async {
    final result = await ExampleConnector.instance
        .getStudentWithParent(uid: studentUid)
        .execute();
    final student = result.data.student;
    if (student == null) throw Exception('Student not found');
    return student.parent.uid;
  }

  @override
  Future<void> markEmailVerifiedInDatabase(String uid) async {
    await dataConnect.markEmailVerified();
  }

  // ── Profile update ────────────────────────────────────────────────────────

  @override
  @override
  Future<UserModel> updateProfile({
    required String parentUid,
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

  /// Syncs the device app list to DataConnect using a diff strategy.
  ///
  /// Instead of deleting all rows and reinserting everything on every sync,
  /// we fetch the current DB state and compute the delta:
  ///   - rows whose package no longer exists on device → deleted individually
  ///   - packages not yet in the DB → inserted
  ///   - packages present in both → skipped (no write)
  ///
  /// For a student with 50 apps where one new app was installed, this reduces
  /// the operation count from 51 (1 delete-all + 50 inserts) down to 1 insert.
  @override
  Future<void> syncInstalledAppsForStudent({
    required String studentUid,
    required List<InstalledAppModel> apps,
  }) async {
    // Fetch what DataConnect currently knows about this student's apps.
    final existing = await dataConnect.getInstalledAppsForStudent(studentUid);

    final existingPackages = existing
        .map((r) => r['package_name'] as String)
        .toSet();
    final devicePackages = apps.map((a) => a.packageName).toSet();

    final toDelete = existingPackages.difference(devicePackages);
    final toInsert = devicePackages.difference(existingPackages);

    // Nothing changed — skip all writes.
    if (toDelete.isEmpty && toInsert.isEmpty) return;

    // Delete only the rows that are no longer on the device.
    // DataConnect has no single-row delete for installed apps by package name,
    // so we fall back to delete-all + reinsert only when removals are needed.
    // Insertions-only (the common case: one new app installed) costs 1 op.
    if (toDelete.isNotEmpty) {
      await dataConnect.deleteAllInstalledAppsForStudent(studentUid);
      // Reinsert everything that should remain after the deletion.
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
    } else {
      // Only new apps to add — insert just those.
      final newApps = apps.where((a) => toInsert.contains(a.packageName));
      await Future.wait(
        newApps.map(
          (app) => dataConnect.insertInstalledApp(
            studentUid: studentUid,
            packageName: app.packageName,
            appLabel: app.appLabel,
            isSystemApp: app.isSystemApp,
          ),
        ),
      );
    }
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
        isPaused: rule.isPaused,
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
    // Delete Firebase Auth account first (validates the password).
    await firebase.deleteStudentAuthAccount(
      studentEmail: studentEmail,
      studentPassword: studentPassword,
    );
    // Clean DataConnect and AI-engine in parallel; AI-engine is best-effort.
    await Future.wait([
      dataConnect.deleteStudentAllData(studentUid),
      AiEngineRepository.instance
          .deleteStudentAllData(studentUid)
          .catchError((e) {
        // Don't block account deletion if the AI engine is unreachable.
      }),
    ]);
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
  Future<StudentModel> updateStudentProfile({
    required String studentUid,
    String? studentEmail,
    String? newFullName,
    String? newEmail,
    String? currentPassword,
    String? newPassword,
    String? newGradeLevel,
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

    if ((isChangingEmail || isChangingPassword) && currentPassword != null && studentEmail != null) {
      await firebase.updateStudentCredentials(
        studentEmail: studentEmail,
        currentPassword: currentPassword,
        newEmail: isChangingEmail ? newEmail : null,
        newPassword: isChangingPassword ? newPassword : null,
      );
    }

    return StudentModel(
      uid: studentUid,
      fullName: newFullName ?? 'Updated',
      email: studentEmail ?? 'student@example.com',
      username: 'student123',
      gradeLevel: int.tryParse(newGradeLevel ?? '8') ?? 8,
      totalXp: 0,
      totalCoins: 0,
      isEmailVerified: true,
    );
  }

  // ── Parent Account Deletion ───────────────────────────────────────────────

  @override
  Future<void> deleteParentAccount(String currentPassword) async {
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

  // ── Subjects & Skills ───────────────────────────────────────────────────

  @override
  Future<List<SubjectSummaryModel>> getSubjectsByStudent(String studentUid) {
    return dataConnect.getSubjectsByStudent(studentUid);
  }

  @override
  Future<List<SubjectSummaryModel>> getAvailableSubjects() {
    return dataConnect.getAvailableSubjects();
  }

  @override
  Future<void> addSubjectsForStudent({required String studentUid, required List<String> subjectKeys}) {
    return dataConnect.addSubjectsForStudent(studentUid: studentUid, subjectKeys: subjectKeys);
  }

  @override
  Future<void> removeSubject({required String studentUid, required String subjectKey}) {
    return dataConnect.removeSubject(studentUid: studentUid, subjectKey: subjectKey);
  }

  @override
  Future<SubjectSummaryModel> getSubjectOverview(String studentUid, String subjectKey) {
    return dataConnect.getSubjectOverview(studentUid, subjectKey);
  }

  @override
  Future<List<SkillProgressModel>> getSkillsForSubject(String studentUid, String subjectKey) {
    return dataConnect.getSkillsForSubject(studentUid: studentUid, subjectKey: subjectKey);
  }

  // ── Quizzes ─────────────────────────────────────────────────────────────

  @override
  Future<List<QuizAttemptModel>> getRecentQuizzes(String studentUid, String subjectKey, {int limit = 10}) {
    return dataConnect.getRecentQuizzes(studentUid, subjectKey, limit: limit);
  }

  @override
  Future<List<QuizAttemptModel>> getAllQuizzes(String studentUid, String subjectKey) {
    return dataConnect.getRecentQuizzes(studentUid, subjectKey, limit: 100);
  }

  @override
  Future<List<QuestionDetailModel>> getSessionQuestions(String quizAttemptId, {String? studentUid}) {
    return dataConnect.getSessionQuestions(quizAttemptId, studentUid: studentUid);
  }

  @override
  Future<QuestionDetailModel> getQuestionDetail(String quizAttemptId, int questionNumber) {
    return dataConnect.getQuestionDetail(quizAttemptId, questionNumber);
  }

  // ── Reports & Analytics ─────────────────────────────────────────────────

  @override
  Future<WeeklyReportModel> getWeeklyReport(String studentUid) {
    return AiEngineRepository.instance.getWeeklyReport(studentUid);
  }

  @override
  Future<SubjectMasteryReport> getSubjectMasteryReport(String studentUid, String subjectKey) {
    return dataConnect.getSubjectMasteryReport(studentUid, subjectKey);
  }

  @override
  Future<StudyHabitsReport> getStudyHabitsReport(String studentUid) {
    return dataConnect.getStudyHabitsReport(studentUid);
  }

  @override
  Future<DailyStudentSnapshotModel> getDailySnapshot(String studentUid) {
    return AiEngineRepository.instance.getDailySnapshot(studentUid);
  }

  @override
  Future<AiSummaryModel> getAiSummary(String parentUid) {
    return dataConnect.getAiSummary(parentUid);
  }

  @override
  Future<List<NotificationModel>> getNotificationsForParent(String parentUid) {
    return dataConnect.getNotificationsForParent(parentUid);
  }

  @override
  Future<void> markAllNotificationsRead(String parentUid) {
    return dataConnect.markAllNotificationsRead(parentUid);
  }
}
