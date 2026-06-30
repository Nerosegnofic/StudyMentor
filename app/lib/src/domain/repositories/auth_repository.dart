// lib/src/domain/repositories/auth_repository.dart

import '../models/user_model.dart';
import '../models/student_model.dart';
import '../models/app_config_model.dart';
import '../models/installed_app_model.dart';
import '../models/subject_summary_model.dart';
import '../models/quiz_attempt_model.dart';
import '../models/question_detail_model.dart';
import '../models/skill_progress_model.dart';
import '../models/ai_summary_model.dart';
import '../models/notification_model.dart';
import '../models/report_models.dart';

abstract class AuthRepository {
  Future<UserModel> signUp({
    required String fullName,
    required String email,
    required String password,
  });
  Future<UserModel> signIn({required String email, required String password});
  Future<void> sendEmailVerification();
  Future<bool> isEmailVerified();

  /// Returns the cached email-verification status WITHOUT a Firebase reload.
  /// Safe to use right after [signIn] (which already reloads the user) to avoid
  /// a redundant second network round-trip on the login path.
  bool isEmailVerifiedCached();
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
  Future<String> getParentUidForStudent(String studentUid);
  Future<bool> verifyParentCredentials({
    required String studentUid,
    required String parentEmail,
    required String parentPassword,
  });
  Future<void> markEmailVerifiedInDatabase(String uid);



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

  Future<void> deleteStudent({
    required String studentUid,
    required String studentEmail,
    required String studentPassword,
  });

  // ── Subjects & Skills ───────────────────────────────────────────────────
  Future<List<SubjectSummaryModel>> getSubjectsByStudent(String studentUid);
  Future<List<SubjectSummaryModel>> getAvailableSubjects(String studentUid);
  Future<void> addSubjectsForStudent({required String studentUid, required List<String> subjectKeys});
  Future<void> removeSubject({required String studentUid, required String subjectKey});
  Future<void> setSubjectSelection({required String studentUid, required int subjectId, required bool isSelected});
  Future<void> removeStudentSubjectData({required String studentUid, required int subjectId});

  Future<SubjectSummaryModel> getSubjectOverview(String studentUid, int subjectId, String subjectKey);
  Future<List<SkillProgressModel>> getSkillsForSubject(String studentUid, int subjectId, String subjectKey);

  // ── Quizzes ─────────────────────────────────────────────────────────────
  Future<List<QuizAttemptModel>> getRecentQuizzes(String studentUid, int subjectId, String subjectKey, {int limit = 10});
  Future<List<QuizAttemptModel>> getAllQuizzes(String studentUid, int subjectId, String subjectKey);
  Future<List<QuestionDetailModel>> getSessionQuestions(String quizAttemptId, {String? studentUid});

  // ── Reports & Analytics ──────────────────────────────────────────────────
  Future<WeeklyReportModel> getWeeklyReport(String studentUid);
  Future<List<SubjectChipModel>> getReportSubjects(String studentUid);
  Future<SubjectMasteryReport> getSubjectMasteryReport(String studentUid, int subjectId, {double? knownTotalMasteryPercent});
  Future<StudyHabitsReport> getStudyHabitsReport(String studentUid);
  // Dashboard additions
  Future<AiSummaryModel> getAiSummary(List<StudentModel> children);

  // ── Notifications ──────────────────────────────────────────────────────────
  Future<List<NotificationModel>> getNotificationsForParent(String parentUid);
  Future<List<NotificationModel>> getNotificationsForStudent(String studentUid);
  Future<void> markAllNotificationsRead(String parentUid);
  Future<void> markAllStudentNotificationsRead(String studentUid);
  Future<void> toggleParentNotificationRead(String id, {required bool isRead});
  Future<void> toggleStudentNotificationRead(String id, {required bool isRead});
  Future<void> deleteParentNotification(String id);
  Future<void> deleteStudentNotification(String id);

  // ── Profile management ──────────────────────────────────────────────────
  Future<UserModel> updateProfile({
    required String parentUid,
    String? newFullName,
    String? newEmail,
    String? currentPassword,
    String? newPassword,
  });
  Future<void> deleteParentAccount(String currentPassword);

  Future<StudentModel> updateStudentProfile({
    required String studentUid,
    String? studentEmail,
    String? newFullName,
    String? newEmail,
    String? currentPassword,
    String? newPassword,
    String? newGradeLevel,
  });
}
