  // lib/src/data/providers/dataconnect_provider.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_data_connect/firebase_data_connect.dart';
import '../../../dataconnect_generated/generated.dart';
import '../../domain/models/app_config_model.dart';
import '../../domain/models/user_model.dart';
import '../../domain/models/student_model.dart';
import '../../domain/models/quiz_count.dart';
import '../../domain/models/skill_progress_model.dart';
import '../../domain/models/report_models.dart';
import '../../domain/models/subject_summary_model.dart';
import '../../domain/models/quiz_attempt_model.dart';
import '../../domain/models/question_detail_model.dart';
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

    // Seed default local notification preferences for parent
    final parentCategories = [
      ('PARENT_CHILD_PROGRESS', true),
      ('PARENT_STREAK_ALERTS', true),
      ('PARENT_INACTIVITY', true),
      ('PARENT_WEAK_SUBJECT', true),
    ];
    for (final (category, enabled) in parentCategories) {
      try {
        await _connector
            .upsertLocalNotificationPreference(
              userUid: FirebaseAuth.instance.currentUser!.uid,
              category: category,
              enabled: enabled,
            )
            .execute();
      } catch (_) {}
    }
  }

  // Username uniqueness check removed — schema no longer stores usernames.
  Future<void> checkUsernameAvailable(String username) async {}

  Future<void> createStudentProfile({
    required String parentUid,
    required int gradeLevel,
  }) async {
    await _connector
        .insertStudent(parentUid: parentUid)
        .gradeLevel(gradeLevel)
        .execute();

    // Seed default local notification preferences for student
    final studentUid = FirebaseAuth.instance.currentUser!.uid;
    final studentCategories = [
      ('CHILD_STREAK_REMINDER', true, '19:00'),
      ('CHILD_NEAR_MILESTONE', true, null),
      ('CHILD_GARDEN_NUDGE', true, null),
      ('CHILD_MILESTONE_CELEBRATION', true, null),
    ];
    for (final (category, enabled, reminderTime) in studentCategories) {
      try {
        final builder = _connector.upsertLocalNotificationPreference(
          userUid: studentUid,
          category: category,
          enabled: enabled,
        );
        if (reminderTime != null) builder.reminderTime(reminderTime);
        await builder.execute();
      } catch (_) {}
    }
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
            'full_name': s.user.fullName,
            'email': s.user.email,
            'grade_level': s.gradeLevel,
            'is_email_verified': s.user.isEmailVerified,
            'created_at': DateTime.fromMillisecondsSinceEpoch(
              s.user.createdAt.seconds * 1000,
              isUtc: true,
            ).toIso8601String(),
            'last_active_at': s.lastActiveAt == null
                ? null
                : DateTime.fromMillisecondsSinceEpoch(
                    s.lastActiveAt!.seconds * 1000,
                    isUtc: true,
                  ).toIso8601String(),
          },
        )
        .toList();
  }

  /// Stamps the calling student's `lastActiveAt` with the server time.
  ///
  /// Called on quiz completion so the parent's inactivity check (see
  /// [ParentInactivityCheckService]) can detect students who haven't studied
  /// recently. Failures are not retried — the next quiz completion will
  /// stamp it again.
  Future<void> updateStudentLastActiveAt() async {
    await _connector.updateStudentLastActiveAt().execute();
  }

  // getStudentProfile query was removed from generated code after main merge.
  // Callers only need grade_level (int?) which has a null fallback in quiz logic.
  Future<Map<String, dynamic>> getStudentProfile(String uid) async {
    return {'uid': uid, 'grade_level': null};
  }

  Future<String> getParentFullName(String studentUid) async {
    final result = await _connector
        .getStudentWithParent(uid: studentUid)
        .execute();
    final student = result.data.student;
    if (student == null) throw Exception('Student not found');
    return student.parent.user.fullName;
  }

  Future<String> getParentUidForStudent(String studentUid) async {
    final result = await _connector
        .getStudentWithParent(uid: studentUid)
        .execute();
    final student = result.data.student;
    if (student == null) throw Exception('Student not found');
    return student.parent.uid;
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
      _connector
          .deleteLocalNotificationPreferencesForUser(userUid: studentUid)
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
    // insertSupportTicket was removed from the schema — no-op for now.
  }

  // ── Local Notification System ─────────────────────────────────────────────

  Future<void> insertLocalNotificationEvent({
    required String fromStudentUid,
    required String toParentUid,
    required String eventType,
    required String payload,
  }) async {
    await _connector
        .insertLocalNotificationEvent(
          fromStudentUid: fromStudentUid,
          toParentUid: toParentUid,
          eventType: eventType,
          payload: payload,
        )
        .execute();
  }

  Future<void> markLocalNotificationEventsRead(List<String> eventIds) async {
    await _connector
        .markLocalNotificationEventsRead(eventIds: eventIds)
        .execute();
  }

  Future<void> upsertLocalNotificationPreference({
    required String userUid,
    required String category,
    required bool enabled,
    String? reminderTime,
  }) async {
    final builder = _connector.upsertLocalNotificationPreference(
      userUid: userUid,
      category: category,
      enabled: enabled,
    );
    if (reminderTime != null) builder.reminderTime(reminderTime);
    await builder.execute();
  }

  Future<List<Map<String, dynamic>>> getUnreadLocalNotificationEvents(
    String toParentUid,
  ) async {
    final result = await _connector
        .getUnreadLocalNotificationEvents(toParentUid: toParentUid)
        .execute();
    return result.data.localNotificationEvents
        .map(
          (e) => {
            'id': e.id,
            'from_student_uid': e.fromStudentUid,
            'event_type': e.eventType,
            'payload': e.payload,
            'created_at': DateTime.fromMillisecondsSinceEpoch(
              e.createdAt.seconds * 1000,
              isUtc: true,
            ).toIso8601String(),
          },
        )
        .toList();
  }

  Future<List<Map<String, dynamic>>> getLocalNotificationPreferences(
    String userUid,
  ) async {
    final result = await _connector
        .getLocalNotificationPreferences(userUid: userUid)
        .execute();
    return result.data.localNotificationPreferences
        .map(
          (p) => {
            'category': p.category,
            'enabled': p.enabled,
            'reminder_time': p.reminderTime,
          },
        )
        .toList();
  }

  Future<List<SkillProgressModel>> getSkillsForSubject({
    required String studentUid,
    required String subjectKey,
  }) async {

    final def = SubjectMetadataRegistry.getDefinition(subjectKey);
    List<SkillProgressModel> skills = [];

    try {
      final analyticsList = await AiEngineRepository.instance.getSubjectsAnalytics(studentUid: studentUid);
      final keyLower = subjectKey.toLowerCase().trim();
      final nameLower = def.name.toLowerCase().trim();
      final a = analyticsList.firstWhere(
        (element) {
          final name = (element['name'] as String).toLowerCase().trim();
          return name == keyLower || name == nameLower;
        },
        orElse: () => <String, dynamic>{},
      );

      if (a.isNotEmpty) {
        final subjectId = a['subject_id'] as int;
        final masteryTree = await AiEngineRepository.instance.getSubjectMasteryTree(subjectId, studentUid: studentUid);
        final units = masteryTree['units'] as List? ?? [];
        
        for (final u in units) {
          final lessons = u['lessons'] as List? ?? [];
          for (final l in lessons) {
            final skillList = l['skills'] as List? ?? [];
            for (final s in skillList) {
              final skillName = s['name'] as String;
              final mastery = ((s['mastery'] as num? ?? 0.0).toDouble() * 100).round();
              final attempts = s['attempts'] as int? ?? 0;
              
              final correctAnswers = ((mastery / 100) * attempts).round();
              final wrongAnswers = attempts - correctAnswers;

              skills.add(SkillProgressModel(
                studentUid: studentUid,
                subjectKey: subjectKey,
                skillKey: skillName,
                correctAnswers: correctAnswers,
                wrongAnswers: wrongAnswers >= 0 ? wrongAnswers : 0,
                totalAttempts: attempts,
                lastPracticedAt: DateTime.now(),
              ));
            }
          }
        }
      }
    } catch (e) {
      print('Failed to get real skills for subject from AI engine: $e');
    }

    return skills;
  }

  // ── Subjects & Quizzes Mocked for Sprint 2 ────────────────────────────────

  Future<List<SubjectSummaryModel>> getSubjectsByStudent(
    String studentUid,
  ) async {
    List<Map<String, dynamic>> analyticsList = [];
    try {
      analyticsList = await AiEngineRepository.instance.getSubjectsAnalytics(studentUid: studentUid);
    } catch (e) {
      print('Failed to fetch subjects analytics from AI engine: $e');
    }

    return analyticsList.map((a) {
      final name = (a['name'] as String).toLowerCase().trim();
      final def = SubjectMetadataRegistry.getDefinition(name);
      final masteryPercent = ((a['average_mastery'] as num? ?? 0.0).toDouble() * 100).round();
      final skillsCount = a['total_skills'] as int? ?? 0;

      return SubjectSummaryModel(
        subjectKey: def.key,
        subjectId: a['subject_id'] as int? ?? 0,
        colorHex: '#${def.primaryColor.value.toRadixString(16).substring(2).toUpperCase()}',
        skillsCount: skillsCount,
        masteryPercent: masteryPercent,
        quizzesCompleted: 0,
        totalTimeSpent: Duration.zero,
        accuracyPercent: 0,
        isGlobal: a['is_global'] as bool? ?? false,
        isSelected: a['is_selected'] as bool? ?? true,
      );
    }).toList();
  }

  /// The Add-Subjects catalog: real GLOBAL subjects the parent hasn't added for this
  /// student yet, fetched from the AI engine.
  Future<List<SubjectSummaryModel>> getAvailableSubjects(String studentUid) async {
    List<Map<String, dynamic>> available = [];
    try {
      available = await AiEngineRepository.instance.getAvailableGlobalSubjects(studentUid);
    } catch (e) {
      print('Failed to fetch available global subjects from AI engine: $e');
    }

    return available.map((a) {
      final name = (a['name'] as String).toLowerCase().trim();
      final def = SubjectMetadataRegistry.getDefinition(name);
      return SubjectSummaryModel(
        subjectKey: def.key,
        subjectId: a['subject_id'] as int? ?? 0,
        colorHex: '#${def.primaryColor.value.toRadixString(16).substring(2).toUpperCase()}',
        skillsCount: 0,
        masteryPercent: 0,
        quizzesCompleted: 0,
        totalTimeSpent: Duration.zero,
        accuracyPercent: 0,
        isGlobal: true,
        isSelected: false,
      );
    }).toList();
  }

  Future<void> addSubjectsForStudent({
    required String studentUid,
    required List<String> subjectKeys,
  }) async {
    try {
      await AiEngineRepository.instance.ensureSubjects(subjectKeys, studentUid);
    } catch (e) {
      print('Failed to sync subjects to AI engine: $e');
    }
  }

  Future<void> removeSubject({
    required String studentUid,
    required String subjectKey,
  }) async {
    try {
      await AiEngineRepository.instance.deleteSubject(subjectKey, studentUid);
    } catch (e) {
      print('AI engine subject delete failed: $e');
      rethrow;
    }
  }

  Future<void> setSubjectSelection({
    required String studentUid,
    required int subjectId,
    required bool isSelected,
  }) async {
    try {
      await AiEngineRepository.instance.setSubjectSelection(
        subjectId: subjectId,
        studentUid: studentUid,
        isSelected: isSelected,
      );
    } catch (e) {
      print('AI engine subject selection update failed: $e');
      rethrow;
    }
  }

  /// Remove a GLOBAL subject from a child: wipes the child's progress and returns it to
  /// the Add-Subjects catalog (the shared subject is preserved).
  Future<void> removeStudentSubjectData({
    required String studentUid,
    required int subjectId,
  }) async {
    try {
      await AiEngineRepository.instance.removeStudentSubjectData(subjectId, studentUid);
    } catch (e) {
      print('AI engine remove student subject data failed: $e');
      rethrow;
    }
  }

  Future<SubjectSummaryModel> getSubjectOverview(String studentUid, String subjectKey) async {
    final def = SubjectMetadataRegistry.getDefinition(subjectKey);
    final colorHex = '#${def.primaryColor.value.toRadixString(16).substring(2).toUpperCase()}';

    int skillsCount = 0;
    int masteryPercent = 0;
    int quizzesCompleted = 0;
    Duration totalTimeSpent = Duration.zero;
    double accuracyPercent = 0.0;

    try {
      final analyticsList = await AiEngineRepository.instance.getSubjectsAnalytics(studentUid: studentUid);
      final keyLower = subjectKey.toLowerCase().trim();
      final nameLower = def.name.toLowerCase().trim();
      final a = analyticsList.firstWhere(
        (element) {
          final name = (element['name'] as String).toLowerCase().trim();
          return name == keyLower || name == nameLower;
        },
        orElse: () => <String, dynamic>{},
      );

      if (a.isNotEmpty) {
        skillsCount = a['total_skills'] as int? ?? 0;
        masteryPercent = ((a['average_mastery'] as num? ?? 0.0).toDouble() * 100).round();
        final subjectId = a['subject_id'] as int;

        final history = await AiEngineRepository.instance.getSubjectQuizHistory(subjectId, page: 1, pageSize: 50, studentUid: studentUid);
        final sessions = history['sessions'] as List? ?? [];
        quizzesCompleted = history['total'] as int? ?? sessions.length;

        if (sessions.isNotEmpty) {
          double totalScore = 0;
          int sessionsWithScore = 0;
          int totalDurationSeconds = 0;

          for (final s in sessions) {
            final score = s['score'] as num?;
            if (score != null) {
              totalScore += score.toDouble();
              sessionsWithScore++;
            }
            final startStr = s['start_time'] as String?;
            final endStr = s['end_time'] as String?;
            if (startStr != null && endStr != null) {
              try {
                final start = DateTime.parse(startStr);
                final end = DateTime.parse(endStr);
                totalDurationSeconds += end.difference(start).inSeconds;
              } catch (_) {}
            }
          }

          if (sessionsWithScore > 0) {
            accuracyPercent = double.parse((totalScore / sessionsWithScore).toStringAsFixed(1));
          }
          totalTimeSpent = Duration(seconds: totalDurationSeconds);
        }
      }
    } catch (e) {
      print('Failed to get real subject overview from AI engine: $e');
    }

    return SubjectSummaryModel(
      subjectKey: subjectKey,
      colorHex: colorHex,
      skillsCount: skillsCount,
      masteryPercent: masteryPercent,
      quizzesCompleted: quizzesCompleted,
      totalTimeSpent: totalTimeSpent,
      accuracyPercent: accuracyPercent,
    );
  }

  Future<List<QuizAttemptModel>> getRecentQuizzes(
    String studentUid,
    String subjectKey, {
    int limit = 10,
  }) async {
    try {
      final def = SubjectMetadataRegistry.getDefinition(subjectKey);
      final keyLower = subjectKey.toLowerCase().trim();
      final nameLower = def.name.toLowerCase().trim();

      final analyticsList = await AiEngineRepository.instance
          .getSubjectsAnalytics(studentUid: studentUid);
      final a = analyticsList.firstWhere(
        (e) {
          final name = (e['name'] as String).toLowerCase().trim();
          return name == keyLower || name == nameLower;
        },
        orElse: () => <String, dynamic>{},
      );

      if (a.isEmpty) return [];

      final subjectId = a['subject_id'] as int;
      final history = await AiEngineRepository.instance.getSubjectQuizHistory(
        subjectId,
        page: 1,
        pageSize: limit,
        studentUid: studentUid,
      );

      final sessions = history['sessions'] as List? ?? [];
      return sessions.asMap().entries.map((entry) {
        final idx = entry.key;
        final s = entry.value as Map<String, dynamic>;

        final sessionId = s['session_id'] as String? ?? 'session_$idx';
        final startStr = s['start_time'] as String?;
        final endStr = s['end_time'] as String?;

        var attemptedAt = DateTime.now().subtract(Duration(days: idx));
        var duration = Duration.zero;
        if (startStr != null) {
          try { attemptedAt = DateTime.parse(startStr); } catch (_) {}
        }
        if (startStr != null && endStr != null) {
          try {
            final start = DateTime.parse(startStr);
            final end = DateTime.parse(endStr);
            duration = end.difference(start);
          } catch (_) {}
        }

        final totalQuestions = (s['total_questions'] as int?) ?? 5;
        // score is stored as 0–100 percentage (not 0–1 ratio)
        final score = (s['score'] as num?)?.toDouble() ?? 0.0;
        final correctAnswers = (s['correct_answers'] as int?) ??
            ((score / 100.0) * totalQuestions).round();
        final passed = (s['passed'] as bool?) ?? (score >= 60);
        final skillTag = (s['skill_tag'] as String?) ?? subjectKey;
        final correctAnswerNumbers =
            (s['correct_answer_numbers'] as List<dynamic>?)
                ?.map((e) => e as int)
                .toList() ??
            [];

        return QuizAttemptModel(
          id: sessionId,
          studentUid: studentUid,
          subjectKey: subjectKey,
          skillTag: skillTag,
          attemptedAt: attemptedAt,
          correctAnswers: correctAnswers,
          totalQuestions: totalQuestions,
          duration: duration,
          passed: passed,
          correctAnswerNumbers: correctAnswerNumbers,
        );
      }).toList();
    } catch (e) {
      print('Failed to load quiz history from AI engine: $e');
      return [];
    }
  }

  Future<List<QuestionDetailModel>> getSessionQuestions(String quizAttemptId, {String? studentUid}) async {
    try {
      final data = await AiEngineRepository.instance
          .getSessionQuestions(quizAttemptId, studentUid: studentUid);
      final questions = (data['questions'] as List<dynamic>?) ?? [];
      return questions.map((q) {
        final m = q as Map<String, dynamic>;
        return QuestionDetailModel(
          quizAttemptId: quizAttemptId,
          questionNumber: m['question_number'] as int,
          isCorrect: m['is_correct'] as bool? ?? false,
          questionText: m['question_text'] as String,
          options: (m['options'] as List<dynamic>).cast<String>(),
          selectedAnswer: m['selected_answer'] as String? ?? '',
          correctAnswer: m['correct_answer'] as String,
        );
      }).toList();
    } catch (e) {
      print('Failed to load session questions: $e');
      rethrow;
    }
  }

  Future<QuestionDetailModel> getQuestionDetail(
    String quizAttemptId,
    int questionNumber,
  ) async {
    final all = await getSessionQuestions(quizAttemptId);
    return all.firstWhere(
      (q) => q.questionNumber == questionNumber,
      orElse: () => throw Exception('Question $questionNumber not found in session $quizAttemptId'),
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
        SubjectTimeAllocation(
          subjectKey: 'math',
          percentage: 45.0,
          colorHex: '#2E7D32',
        ),
        SubjectTimeAllocation(
          subjectKey: 'science',
          percentage: 30.0,
          colorHex: '#AD1457',
        ),
        SubjectTimeAllocation(
          subjectKey: 'english',
          percentage: 25.0,
          colorHex: '#6A1B9A',
        ),
      ],
      aiInsightText:
          "Ahmed is showing great progress in Mathematics, improving his accuracy by 5% this week. He is still struggling slightly with fractions, but his consistency is excellent. Keep encouraging daily practice!",
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

  Future<void> upsertSkillProgress({
    required String studentUid,
    required String subjectKey,
    required String skillKey,
    required int correctAnswers,
    required int wrongAnswers,
    required int totalAttempts,
  }) async {}

  Future<List<NotificationModel>> getNotificationsForParent(
    String parentUid,
  ) async {
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

  Future<List<NotificationModel>> getNotificationsForStudent(
    String studentUid,
  ) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return [
      NotificationModel(
        id: 's1',
        parentUid: '',
        studentUid: studentUid,
        type: NotificationType.streakAchieved,
        title: '7-Day Streak! 🔥',
        subtitle: 'You studied 7 days in a row. Keep the fire going!',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        isRead: false,
      ),
      NotificationModel(
        id: 's2',
        parentUid: '',
        studentUid: studentUid,
        type: NotificationType.needsWork,
        title: 'Review: Fractions',
        subtitle: 'A few fractions questions tripped you up. Try a review quiz!',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        isRead: false,
      ),
      NotificationModel(
        id: 's3',
        parentUid: '',
        studentUid: studentUid,
        type: NotificationType.systemUpdate,
        title: 'New Avatar Items',
        subtitle: 'Fresh items just landed in the shop. Go check them out!',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
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
      gradeLevel: newGradeLevel != null ? int.tryParse(newGradeLevel) ?? 8 : 8,
      totalXp: 450,
      totalCoins: 200,
      isEmailVerified: true,
    );
  }
}
