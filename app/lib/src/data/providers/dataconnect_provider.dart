// lib/src/data/providers/dataconnect_provider.dart

import '../../../dataconnect_generated/generated.dart';
import '../../domain/models/app_config_model.dart';
import '../../domain/models/subject_progress_model.dart';
import '../../domain/models/skill_progress_model.dart';
import '../catalog/subject_catalog.dart';

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
            'total_xp': s.totalXp,
            'total_coins': s.totalCoins,
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
        .execute();

    final raw = result.data.studentConfig;
    final config = raw == null
        ? null
        : StudentConfigModel(
            usageHours: raw.usageHours,
            usageMinutes: raw.usageMinutes,
            cooldownHours: raw.cooldownHours,
            cooldownMinutes: raw.cooldownMinutes,
          );

    final rules = result.data.appRules
        .map(
          (r) => {
            'id': r.id,
            'package_name': r.packageName,
            'app_label': r.appLabel,
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
  }) async {
    await _connector
        .insertAppRule(
          studentUid: studentUid,
          packageName: packageName,
          appLabel: appLabel,
        )
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
      'total_xp': s.totalXp,
      'total_coins': s.totalCoins,
      'grade_level': s.gradeLevel,
      'total_questions_answered': s.totalQuestionsAnswered,
      'current_streak': s.currentStreak,
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

  // ── Last Active ───────────────────────────────────────────────────────────

  Future<void> updateLastActiveAt() async {
    await _connector.updateLastActiveAt().execute();
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

  Future<void> updateStudentCoins(int totalCoins) async {
    await _connector.updateStudentCoins(totalCoins: totalCoins).execute();
  }

  Future<void> updateStudentXpAndCoins({
    required int totalXp,
    required int weeklyXp,
    required int totalCoins,
    required int totalQuestionsAnswered,
    required int currentStreak,
  }) async {
    await _connector
        .updateStudentXpAndCoins(
          totalXp: totalXp,
          weeklyXp: weeklyXp,
          totalCoins: totalCoins,
          totalQuestionsAnswered: totalQuestionsAnswered,
          currentStreak: currentStreak,
        )
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
    final subject = SubjectCatalog.byKey(subjectKey);
    if (subject == null) return [];
    return subject.skillKeys
        .map(
          (key) => SkillProgressModel.empty(
            studentUid: studentUid,
            subjectKey: subjectKey,
            skillKey: key,
          ),
        )
        .toList();
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
}
