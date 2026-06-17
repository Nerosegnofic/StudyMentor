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
  Future<void> signOut();
  Future<void> sendPasswordReset(String email);
  Future<UserModel?> getUserProfile();
  Future<UserModel> createStudent({
    required String fullName,
    required String email,
    required String password,
    required String parentUid,
    required int gradeLevel,
    required String username,
  });
  Future<List<StudentModel>> getStudentsByParent(String parentUid);
  Future<String> getParentFullName(String studentUid);
  Future<String> getParentUidForStudent(String studentUid);
  Future<List<StudentModel>> refreshStudentVerificationStatus(
    List<StudentModel> students,
  );
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

  Future<void> updateStudentFullName({
    required String studentUid,
    required String fullName,
  });


  // ── Subjects & Skills ───────────────────────────────────────────────────
  Future<List<SubjectSummaryModel>> getSubjectsByStudent(String studentUid);
  Future<List<SubjectSummaryModel>> getAvailableSubjects(String studentUid);
  Future<void> addSubjectsForStudent({required String studentUid, required List<String> subjectKeys});
  Future<void> removeSubject({required String studentUid, required String subjectKey});
  Future<void> setSubjectSelection({required String studentUid, required int subjectId, required bool isSelected});
  Future<void> removeStudentSubjectData({required String studentUid, required int subjectId});

  Future<SubjectSummaryModel> getSubjectOverview(String studentUid, String subjectKey);
  Future<List<SkillProgressModel>> getSkillsForSubject(String studentUid, String subjectKey);
  
  // ── Quizzes ─────────────────────────────────────────────────────────────
  Future<List<QuizAttemptModel>> getRecentQuizzes(String studentUid, String subjectKey, {int limit = 10});
  Future<List<QuizAttemptModel>> getAllQuizzes(String studentUid, String subjectKey);
  Future<List<QuestionDetailModel>> getSessionQuestions(String quizAttemptId, {String? studentUid});
  Future<QuestionDetailModel> getQuestionDetail(String quizAttemptId, int questionNumber);

  // ── Reports & Analytics ──────────────────────────────────────────────────
  Future<WeeklyReportModel> getWeeklyReport(String studentUid);
  Future<List<SubjectChipModel>> getReportSubjects(String studentUid);
  Future<SubjectMasteryReport> getSubjectMasteryReport(String studentUid, int subjectId);
  Future<StudyHabitsReport> getStudyHabitsReport(String studentUid);
  Future<DailyStudentSnapshotModel> getDailySnapshot(String studentUid);
  
  // Dashboard additions
  Future<AiSummaryModel> getAiSummary(List<StudentModel> children);
  Future<List<NotificationModel>> getNotificationsForParent(String parentUid);
  Future<void> markAllNotificationsRead(String parentUid);

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
