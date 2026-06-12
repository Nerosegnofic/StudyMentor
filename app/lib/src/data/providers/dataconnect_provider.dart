// lib/src/data/providers/dataconnect_provider.dart

import 'package:firebase_data_connect/firebase_data_connect.dart';
import '../../../dataconnect_generated/generated.dart';
import '../../domain/models/app_config_model.dart';
import '../../domain/models/user_model.dart';
import '../../domain/models/student_model.dart';
import '../../domain/models/quiz_count.dart';
import '../../domain/models/subject_progress_model.dart';
import '../../domain/models/skill_progress_model.dart';
import '../../domain/models/report_models.dart';
import '../../domain/models/subject_summary_model.dart';
import '../../domain/models/quiz_attempt_model.dart';
import '../../domain/models/question_detail_model.dart';
import '../../domain/models/ai_summary_model.dart';
import '../../domain/models/notification_model.dart';
import '../catalog/subject_metadata_registry.dart';
import '../repositories/ai_engine_repository.dart';

class DataConnectProvider {
  final _connector = ExampleConnector.instance;

  Future<void> createUserProfile({
    required String email,
    required String fullName,
    required String role,
  }) async {
    await _connector
        .insertUser(
          email: email,
          fullName: fullName,
          role: role == 'Parent' ? Role.Parent : Role.Student,
        )
        .execute();
  }

  Future<void> createParentProfile() async {
    await _connector.insertParent().execute();
  }

  // Throws Exception('username-already-in-use') if the username is taken.
  Future<void> checkUsernameAvailable(String username) async {
    final existing = await _connector
        .getStudentByUsername(username: username)
        .execute();
    if (existing.data.students.isNotEmpty) {
      throw Exception('username-already-in-use');
    }
  }

  Future<void> createStudentProfile({
    required String parentUid,
    required String username,
    required int gradeLevel,
  }) async {
    await _connector
        .insertStudent(parentUid: parentUid, username: username)
        .gradeLevel(gradeLevel)
        .execute();
  }

  Future<Map<String, dynamic>> getUserProfile(String uid) async {
    final result = await _connector.getUserByUid(uid: uid).execute();
    final user = result.data.user;
    if (user == null) throw Exception('User not found in DataConnect');
    final createdAt = DateTime.fromMillisecondsSinceEpoch(
      user.createdAt.seconds * 1000,
    );
    return {
      'uid': user.uid,
      'email': user.email,
      'full_name': user.fullName,
      'role': user.role.stringValue,
      'is_active': user.isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Future<List<Map<String, dynamic>>> getStudentsByParent(
    String parentUid,
  ) async {
    final result = await _connector
        .getStudentsByParent(parentUid: parentUid)
        .execute();
    return result.data.students
        .map(
          (s) => {
            'uid': s.uid,
            'username': s.username,
            'full_name': s.user.fullName,
            'email': s.user.email,
            'grade_level': s.gradeLevel,
            'is_email_verified': s.user.isEmailVerified,
          },
        )
        .toList();
  }

  Future<String> getParentFullName(String studentUid) async {
    final result = await _connector
        .getStudentWithParent(uid: studentUid)
        .execute();
    final student = result.data.student;
    if (student == null) throw Exception('Student not found');
    return student.parent.user.fullName;
  }

  Future<String> getEmailForUid(String uid) async {
    final result = await _connector.getUserByUid(uid: uid).execute();
    final user = result.data.user;
    if (user == null) throw Exception('User not found in DataConnect');
    return user.email;
  }

  Future<bool> getIsActiveForUid(String uid) async {
    final result = await _connector.getUserByUid(uid: uid).execute();
    final user = result.data.user;
    if (user == null) return false;
    return user.isActive;
  }

  Future<void> markEmailVerified() async {
    await ExampleConnector.instance.markEmailVerified().execute();
  }

  // ── App Rules ─────────────────────────────────────────────────────────────

  Future<({StudentConfigModel? config, List<Map<String, dynamic>> rules})>
  getAppConfigForStudent(String studentUid) async {
    final result = await _connector
        .getAppConfigForStudent(studentUid: studentUid)
        .execute(fetchPolicy: QueryFetchPolicy.serverOnly);

    final raw = result.data.studentConfig;
    final config = raw == null
        ? null
        : StudentConfigModel(
            usageHours: raw.usageHours,
            usageMinutes: raw.usageMinutes,
            cooldownHours: raw.cooldownHours,
            cooldownMinutes: raw.cooldownMinutes,
            quizCount: QuizCount.fromJson(raw.quizCount),
          );

    final rules = result.data.appRules
        .map(
          (r) => {
            'id': r.id,
            'package_name': r.packageName,
            'app_label': r.appLabel,
            'is_paused': r.isPaused,
          },
        )
        .toList();

    return (config: config, rules: rules);
  }

  Future<void> deleteAllAppRulesForStudent(String studentUid) async {
    await _connector
        .deleteAllAppRulesForStudent(studentUid: studentUid)
        .execute();
  }

  Future<void> insertAppRule({
    required String studentUid,
    required String packageName,
    required String appLabel,
    bool isPaused = false,
  }) async {
    await _connector
        .insertAppRule(
          studentUid: studentUid,
          packageName: packageName,
          appLabel: appLabel,
        )
        .isPaused(isPaused)
        .execute();
  }

  Future<void> upsertStudentConfig({
    required String studentUid,
    required StudentConfigModel config,
  }) async {
    await _connector
        .upsertStudentConfig(
          studentUid: studentUid,
          usageHours: config.usageHours,
          usageMinutes: config.usageMinutes,
          cooldownHours: config.cooldownHours,
          cooldownMinutes: config.cooldownMinutes,
          quizCount: config.quizCount.toJson(),
        )
        .execute();
  }

  // ── Installed-App Inventory ───────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getInstalledAppsForStudent(
    String studentUid,
  ) async {
    final result = await _connector
        .getInstalledAppsForStudent(studentUid: studentUid)
        .execute();
    return result.data.installedApps
        .map(
          (a) => {
            'package_name': a.packageName,
            'app_label': a.appLabel,
            'is_system_app': a.isSystemApp,
          },
        )
        .toList();
  }

  Future<void> deleteAllInstalledAppsForStudent(String studentUid) async {
    await _connector
        .deleteAllInstalledAppsForStudent(studentUid: studentUid)
        .execute();
  }

  Future<void> insertInstalledApp({
    required String studentUid,
    required String packageName,
    required String appLabel,
    required bool isSystemApp,
  }) async {
    await _connector
        .insertInstalledApp(
          studentUid: studentUid,
          packageName: packageName,
          appLabel: appLabel,
          isSystemApp: isSystemApp,
        )
        .execute();
  }

  // ── Student Profile ───────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getStudentProfile(String uid) async {
    final result = await _connector.getStudentProfile(uid: uid).execute();
    final s = result.data.student;
    if (s == null) throw Exception('Student not found');
    return {
      'uid': s.uid,
      'username': s.username,
      'grade_level': s.gradeLevel,
    };
  }

  // ── Student Settings ──────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getStudentSettings(String studentUid) async {
    final result = await _connector
        .getStudentSettings(studentUid: studentUid)
        .execute();
    final s = result.data.studentSettings;
    if (s == null) return null;
    return {
      'notifications_enabled': s.notificationsEnabled,
      'sound_effects_enabled': s.soundEffectsEnabled,
      'background_music_enabled': s.backgroundMusicEnabled,
    };
  }

  Future<void> upsertStudentSettings({
    required String studentUid,
    required bool notificationsEnabled,
    required bool soundEffectsEnabled,
    required bool backgroundMusicEnabled,
  }) async {
    await _connector
        .upsertStudentSettings(
          studentUid: studentUid,
          notificationsEnabled: notificationsEnabled,
          soundEffectsEnabled: soundEffectsEnabled,
          backgroundMusicEnabled: backgroundMusicEnabled,
        )
        .execute();
  }

  // ── Avatar Shop ───────────────────────────────────────────────────────────

  Future<Set<String>> getStudentOwnedItems(String studentUid) async {
    final result = await _connector
        .getStudentOwnedItems(studentUid: studentUid)
        .execute();
    return result.data.studentOwnedItems.map((e) => e.itemId).toSet();
  }

  Future<Map<String, dynamic>?> getStudentAvatar(String studentUid) async {
    final result = await _connector
        .getStudentAvatar(studentUid: studentUid)
        .execute();
    final a = result.data.studentAvatar;
    if (a == null) return null;
    return {
      'gender': a.gender,
      'skin_tone': a.skinTone,
      'equipped_hair': a.equippedHair,
      'equipped_outfit': a.equippedOutfit,
      'equipped_bottom': a.equippedBottom,
      'equipped_shoes': a.equippedShoes,
      'equipped_accessory': a.equippedAccessory,
      'equipped_background': a.equippedBackground,
      'equipped_special': a.equippedSpecial,
      'avatar_config': a.avatarConfig,
    };
  }

  Future<void> insertStudentOwnedItem({
    required String studentUid,
    required String itemId,
  }) async {
    await _connector
        .insertStudentOwnedItem(studentUid: studentUid, itemId: itemId)
        .execute();
  }

  Future<void> upsertStudentAvatar({
    required String studentUid,
    required String gender,
    required String skinTone,
    String? equippedHair,
    String? equippedOutfit,
    String? equippedBottom,
    String? equippedShoes,
    String? equippedAccessory,
    String? equippedBackground,
    String? equippedSpecial,
    String? avatarConfig,
  }) async {
    await _connector
        .upsertStudentAvatar(
          studentUid: studentUid,
          gender: gender,
          skinTone: skinTone,
        )
        .equippedHair(equippedHair)
        .equippedOutfit(equippedOutfit)
        .equippedBottom(equippedBottom)
        .equippedShoes(equippedShoes)
        .equippedAccessory(equippedAccessory)
        .equippedBackground(equippedBackground)
        .equippedSpecial(equippedSpecial)
        .avatarConfig(avatarConfig)
        .execute();
  }

  // ── Student Account Deletion (parent-side) ────────────────────────────────

  Future<void> deleteStudentAllData(String studentUid) async {
    await Future.wait([
      _connector
          .deleteAllOwnedItemsForStudent(studentUid: studentUid)
          .execute(),
      _connector.deleteStudentAvatar(studentUid: studentUid).execute(),
      _connector.deleteStudentSettings(studentUid: studentUid).execute(),
      _connector.deleteStudentConfig(studentUid: studentUid).execute(),
      _connector.deleteAllAppRulesForStudent(studentUid: studentUid).execute(),
      _connector
          .deleteAllInstalledAppsForStudent(studentUid: studentUid)
          .execute(),
    ]);
    await _connector.deleteStudentRecord(uid: studentUid).execute();
    await _connector.deleteUserRecord(uid: studentUid).execute();
  }

  // ── Student Name Update (parent-side) ────────────────────────────────────

  Future<void> updateStudentFullName({
    required String uid,
    required String fullName,
  }) async {
    await _connector
        .updateStudentFullName(uid: uid, fullName: fullName)
        .execute();
  }

  // ── Parent Account Deletion ───────────────────────────────────────────────

  Future<void> deleteParentRecord() async {
    await _connector.deleteParentRecord().execute();
  }

  // ── Support Tickets ───────────────────────────────────────────────────────

  Future<void> insertSupportTicket({
    required String userId,
    required String userName,
    required String issueType,
    required String message,
  }) async {
    await _connector
        .insertSupportTicket(
          userId: userId,
          userName: userName,
          issueType: issueType,
          message: message,
        )
        .execute();
  }

  // ── Garden System ─────────────────────────────────────────────────────────

  Future<List<SubjectProgressModel>> getAllSubjectProgress(
    String studentUid,
  ) async {
    final result = await _connector
        .getAllSubjectProgress(studentUid: studentUid)
        .execute();
    return result.data.subjectProgresses.map((r) {
      return SubjectProgressModel(
        studentUid: r.studentUid,
        subjectKey: r.subjectKey,
        totalXp: r.totalXp,
        level: r.level,
        updatedAt: DateTime.fromMillisecondsSinceEpoch(
          r.updatedAt.seconds * 1000,
          isUtc: true,
        ),
      );
    }).toList();
  }

  Future<List<SkillProgressModel>> getSkillsForSubject({
    required String studentUid,
    required String subjectKey,
  }) async {
    final subject = SubjectMetadataRegistry.getDefinition(subjectKey);
    
    // Simulate real data from DataConnect
    int index = 0;
    final mockSkills = ['basics', 'intermediate', 'advanced'];
    return mockSkills.map((key) {
      index++;
      final isStrong = index % 3 == 0;
      return SkillProgressModel(
        studentUid: studentUid,
        subjectKey: subjectKey,
        skillKey: key,
        correctAnswers: isStrong ? 20 : 5,
        wrongAnswers: isStrong ? 2 : 10,
        totalAttempts: isStrong ? 22 : 15,
        lastPracticedAt: DateTime.now().subtract(Duration(days: index)),
      );
    }).toList();
  }

  // ── Subjects & Quizzes Mocked for Sprint 2 ────────────────────────────────

  Future<List<SubjectSummaryModel>> getSubjectsByStudent(String studentUid) async {
    final progresses = await getAllSubjectProgress(studentUid);
    return progresses.map((p) {
      final def = SubjectMetadataRegistry.getDefinition(p.subjectKey);
      return SubjectSummaryModel(
        subjectKey: p.subjectKey,
        colorHex: '#${def.primaryColor.value.toRadixString(16).substring(2).toUpperCase()}',
        skillsCount: 0,
        masteryPercent: 0,
        quizzesCompleted: 0,
        totalTimeSpent: Duration.zero,
        accuracyPercent: 0,
      );
    }).toList();
  }

  Future<List<SubjectSummaryModel>> getAvailableSubjects() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final globalKeys = ['math', 'science', 'history', 'english', 'geography', 'art', 'music'];
    return globalKeys.map((key) {
      final def = SubjectMetadataRegistry.getDefinition(key);
      return SubjectSummaryModel(
        subjectKey: def.key,
        colorHex: '#${def.primaryColor.value.toRadixString(16).substring(2).toUpperCase()}',
        skillsCount: 3,
        masteryPercent: 0,
        quizzesCompleted: 0,
        totalTimeSpent: Duration.zero,
        accuracyPercent: 0,
      );
    }).toList();
  }

  Future<void> addSubjectsForStudent({required String studentUid, required List<String> subjectKeys}) async {
    for (final key in subjectKeys) {
      await upsertSubjectProgress(
        studentUid: studentUid,
        subjectKey: key,
        totalXp: 0,
        level: 1,
      );
    }
    // Create Subject rows in AI engine so assigned subjects appear in the garden.
    try {
      await AiEngineRepository.instance.ensureSubjects(subjectKeys, studentUid);
    } catch (e) {
      print('Failed to sync subjects to AI engine: $e');
    }
  }

  Future<void> removeSubject({required String studentUid, required String subjectKey}) async {
    // 1. Remove from DataConnect
    await _connector.deleteSubjectProgress(
      studentUid: studentUid,
      subjectKey: subjectKey,
    ).execute();

    // 2. Delete subject from AI engine (garden, skills, embeddings, etc.)
    // Backend returns 404 for global subjects — caught and ignored below.
    try {
      await AiEngineRepository.instance.deleteSubject(subjectKey, studentUid);
    } catch (e) {
      print('AI engine subject delete skipped or failed: $e');
    }
  }

  Future<SubjectSummaryModel> getSubjectOverview(String studentUid, String subjectKey) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final subject = SubjectMetadataRegistry.getDefinition(subjectKey);
    final colorHex = '#${subject.primaryColor.value.toRadixString(16).substring(2).toUpperCase()}';
        
    return SubjectSummaryModel(
      subjectKey: subjectKey,
      colorHex: colorHex,
      skillsCount: 3,
      masteryPercent: 88,
      quizzesCompleted: 24,
      totalTimeSpent: const Duration(hours: 5, minutes: 10),
      accuracyPercent: 85.5,
    );
  }

  Future<List<QuizAttemptModel>> getRecentQuizzes(String studentUid, String subjectKey, {int limit = 10}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return List.generate(limit, (index) {
      final isPassed = index % 3 != 0;
      return QuizAttemptModel(
        id: 'quiz_$index',
        studentUid: studentUid,
        subjectKey: subjectKey,
        skillTag: 'Fractions',
        attemptedAt: DateTime.now().subtract(Duration(days: index)),
        correctAnswers: isPassed ? 4 : 2,
        totalQuestions: 5,
        duration: Duration(minutes: 2, seconds: 15 + index * 10),
        passed: isPassed,
        correctAnswerNumbers: isPassed ? [1, 2, 4, 5] : [1, 3],
      );
    });
  }

  Future<QuestionDetailModel> getQuestionDetail(String quizAttemptId, int questionNumber) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return QuestionDetailModel(
      quizAttemptId: quizAttemptId,
      questionNumber: questionNumber,
      isCorrect: true,
      questionText: 'What is 8 x 7?',
      options: const ['54', '56', '64', '42'],
      selectedAnswer: '56',
      correctAnswer: '56',
    );
  }

  // ── Reports & Analytics (Mocked for Sprint 3) ───────────────────────────

  Future<WeeklyReportModel> getWeeklyReport(String studentUid) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return WeeklyReportModel(
      studentUid: studentUid,
      weekStartDate: DateTime.now().subtract(const Duration(days: 7)),
      overallAccuracyPercent: 85.0,
      totalQuizzes: 12,
      totalStudyTime: const Duration(hours: 4, minutes: 30),
      currentStreakDays: 3,
      longestStreakDays: 7,
      accuracyTrend: const [
        WeeklyAccuracyPoint(weekLabel: 'W1', accuracy: 70),
        WeeklyAccuracyPoint(weekLabel: 'W2', accuracy: 72),
        WeeklyAccuracyPoint(weekLabel: 'W3', accuracy: 78),
        WeeklyAccuracyPoint(weekLabel: 'W4', accuracy: 80),
        WeeklyAccuracyPoint(weekLabel: 'W5', accuracy: 82),
        WeeklyAccuracyPoint(weekLabel: 'This Wk', accuracy: 85),
      ],
      subjectAllocations: const [
        SubjectTimeAllocation(subjectKey: 'math', percentage: 45.0, colorHex: '#2E7D32'),
        SubjectTimeAllocation(subjectKey: 'science', percentage: 30.0, colorHex: '#AD1457'),
        SubjectTimeAllocation(subjectKey: 'english', percentage: 25.0, colorHex: '#6A1B9A'),
      ],
      aiInsightText: "Ahmed is showing great progress in Mathematics, improving his accuracy by 5% this week. He is still struggling slightly with fractions, but his consistency is excellent. Keep encouraging daily practice!",
    );
  }

  Future<SubjectMasteryReport> getSubjectMasteryReport(String studentUid, String subjectKey) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return SubjectMasteryReport(
      subjectKey: subjectKey,
      totalMasteryPercent: 88.0,
      masteryLabel: 'Proficient',
      strongSkills: const [], // Mocked empty for now, UI will use them if present
      weakSkills: const [],
      errorAnalytics: const ErrorAnalyticModel(
        carelessPercent: 45.0,
        conceptGapPercent: 38.0,
        timePressurePercent: 17.0,
      ),
    );
  }

  Future<StudyHabitsReport> getStudyHabitsReport(String studentUid) async {
    await Future.delayed(const Duration(milliseconds: 700));
    
    // Generate mock heatmap data for the last 28 days
    final List<HeatmapDay> heatmap = [];
    final now = DateTime.now();
    for (int i = 27; i >= 0; i--) {
      heatmap.add(HeatmapDay(
        date: now.subtract(Duration(days: i)),
        studyMinutes: (i % 7 == 0) ? 0 : 20 + (i % 40), // semi-random data
      ));
    }

    return StudyHabitsReport(
      studentUid: studentUid,
      currentStreakDays: 3,
      longestStreakDays: 7,
      consistencyHeatmap: heatmap,
      correlation: const [
        StudyVsAppCorrelationPoint(dayLabel: 'Mon', studyMinutes: 45, appUsageMinutes: 60),
        StudyVsAppCorrelationPoint(dayLabel: 'Tue', studyMinutes: 50, appUsageMinutes: 55),
        StudyVsAppCorrelationPoint(dayLabel: 'Wed', studyMinutes: 40, appUsageMinutes: 70),
        StudyVsAppCorrelationPoint(dayLabel: 'Thu', studyMinutes: 60, appUsageMinutes: 40),
        StudyVsAppCorrelationPoint(dayLabel: 'Fri', studyMinutes: 30, appUsageMinutes: 90),
        StudyVsAppCorrelationPoint(dayLabel: 'Sat', studyMinutes: 20, appUsageMinutes: 120),
        StudyVsAppCorrelationPoint(dayLabel: 'Sun', studyMinutes: 25, appUsageMinutes: 100),
      ],
    );
  }

  Future<DailyStudentSnapshotModel> getDailySnapshot(String studentUid) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return DailyStudentSnapshotModel(
      studentUid: studentUid,
      quizzesCompletedToday: 3,
      totalStudyTimeToday: const Duration(minutes: 45),
      averageAccuracyToday: 88,
    );
  }

  Future<void> upsertSubjectProgress({
    required String studentUid,
    required String subjectKey,
    required int totalXp,
    required int level,
  }) async {
    await _connector
        .upsertSubjectProgress(
          studentUid: studentUid,
          subjectKey: subjectKey,
          totalXp: totalXp,
          level: level,
        )
        .execute();
  }

  Future<void> upsertSkillProgress({
    required String studentUid,
    required String subjectKey,
    required String skillKey,
    required int correctAnswers,
    required int wrongAnswers,
    required int totalAttempts,
  }) async {}

  Future<AiSummaryModel> getAiSummary(String parentUid) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return AiSummaryModel(
      id: 'mock-ai-summary-1',
      parentUid: parentUid,
      slides: [
        "Ahmed is on a 7-day streak! He passed 14 quizzes today, earning 245 XP.",
        "He's excelling in Fractions but needs more practice with Decimals.",
        "Ahmed earned 15 minutes of playtime today by completing his Science goals.",
      ],
      generatedAt: DateTime.now(),
    );
  }

  Future<List<NotificationModel>> getNotificationsForParent(String parentUid) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return [
      NotificationModel(
        id: 'n1',
        parentUid: parentUid,
        type: NotificationType.screenTimeUnlocked,
        title: 'Screen Time Unlocked',
        subtitle: 'Ahmed earned 15 mins for passing Mathematics.',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        isRead: false,
      ),
      NotificationModel(
        id: 'n2',
        parentUid: parentUid,
        type: NotificationType.needsWork,
        title: 'Needs Work: Fractions',
        subtitle: 'Ahmed struggled with Fractions today. Review recommended.',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        isRead: true,
      ),
      NotificationModel(
        id: 'n3',
        parentUid: parentUid,
        type: NotificationType.systemUpdate,
        title: 'New Feature Available',
        subtitle: 'You can now set custom cooldown periods.',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        isRead: true,
      ),
    ];
  }

  Future<void> markAllNotificationsRead(String parentUid) async {
    await Future.delayed(const Duration(milliseconds: 200));
  }

  Future<UserModel> updateProfile({
    required String parentUid,
    String? newFullName,
    String? newEmail,
    String? currentPassword,
    String? newPassword,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return UserModel(
      uid: parentUid,
      email: newEmail ?? 'parent@example.com',
      fullName: newFullName ?? 'Parent Name',
      role: 'parent',
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    );
  }

  Future<void> deleteParentAccount(String currentPassword) async {
    await Future.delayed(const Duration(seconds: 1));
  }

  Future<StudentModel> updateStudentProfile({
    required String studentUid,
    String? studentEmail,
    String? newFullName,
    String? newEmail,
    String? currentPassword,
    String? newPassword,
    String? newGradeLevel,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return StudentModel(
      uid: studentUid,
      email: newEmail ?? studentEmail ?? 'student@example.com',
      fullName: newFullName ?? 'Student Name',
      username: 'student123',
      gradeLevel: newGradeLevel != null ? int.tryParse(newGradeLevel) ?? 8 : 8,
      totalXp: 450,
      totalCoins: 200,
      isEmailVerified: true,
    );
  }
}
