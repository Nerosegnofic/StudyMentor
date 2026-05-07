// lib/src/data/providers/dataconnect_provider.dart

import '../../../dataconnect_generated/generated.dart';
import '../../domain/models/app_config_model.dart';

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

  // ── CHANGED: added username parameter ─────────────────────────────────────
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
            'username': s.username, // ── ADDED ────────────────────────────────
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

  // ── CHANGED: added username to returned map ───────────────────────────────
  Future<Map<String, dynamic>> getStudentProfile(String uid) async {
    final result = await _connector.getStudentProfile(uid: uid).execute();
    final s = result.data.student;
    if (s == null) throw Exception('Student not found');
    return {
      'uid': s.uid,
      'username': s.username, // ── ADDED ──────────────────────────────────────
      'friend_code': s.friendCode,
      'total_xp': s.totalXp,
      'total_coins': s.totalCoins,
      'grade_level': s.gradeLevel,
      'total_questions_answered': s.totalQuestionsAnswered,
      'current_streak': s.currentStreak,
    };
  }

  Future<void> updateStudentFriendCode(String friendCode) async {
    await _connector.updateStudentFriendCode(friendCode: friendCode).execute();
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

  // ── Leaderboard ───────────────────────────────────────────────────────────

  // ── CHANGED: s.user.fullName → s.username (user block removed from query) ─
  Future<List<Map<String, dynamic>>> getWeeklyLeaderboard() async {
    final result = await _connector.getWeeklyLeaderboard().execute();
    return result.data.students.map((s) {
      final lastActive = s.lastActiveAt != null
          ? DateTime.fromMillisecondsSinceEpoch(
              s.lastActiveAt!.seconds * 1000,
              isUtc: true,
            )
          : null;
      return {
        'uid': s.uid,
        'username': s.username, // ── CHANGED: was s.user.fullName ─────────────
        'weekly_xp': s.weeklyXp ?? 0,
        'total_xp': s.totalXp ?? 0,
        'last_active_at': lastActive,
      };
    }).toList();
  }

  Future<void> updateLastActiveAt() async {
    await _connector.updateLastActiveAt().execute();
  }

  // ── Friends ───────────────────────────────────────────────────────────────

  // ── CHANGED: added username to returned map ───────────────────────────────
  Future<List<Map<String, dynamic>>> getFriendsForStudent(
    String studentUid,
  ) async {
    final result = await _connector
        .getFriendsForStudent(studentUid: studentUid)
        .execute();
    return result.data.friendships.map((f) {
      final lastActive = f.friend.lastActiveAt != null
          ? DateTime.fromMillisecondsSinceEpoch(
              f.friend.lastActiveAt!.seconds * 1000,
              isUtc: true,
            )
          : null;
      return {
        'friendship_id': f.id,
        'friend_uid': f.friendUid,
        'username': f.friend.username, // ── ADDED ────────────────────────────
        'full_name': f.friend.user.fullName,
        'total_xp': f.friend.totalXp ?? 0,
        'weekly_xp': f.friend.weeklyXp ?? 0,
        'last_active_at': lastActive,
      };
    }).toList();
  }

  // ── CHANGED: added username to returned map ───────────────────────────────
  Future<Map<String, dynamic>?> getStudentByFriendCode(
    String friendCode,
  ) async {
    final result = await _connector
        .getStudentByFriendCode(friendCode: friendCode)
        .execute();
    if (result.data.students.isEmpty) return null;
    final s = result.data.students.first;
    return {
      'uid': s.uid,
      'username': s.username, // ── ADDED ──────────────────────────────────────
      'full_name': s.user.fullName,
      'friend_code': s.friendCode,
    };
  }

  Future<List<Map<String, dynamic>>> getSentFriendRequests(
    String fromStudentUid,
  ) async {
    final result = await _connector
        .getSentFriendRequests(fromStudentUid: fromStudentUid)
        .execute();
    return result.data.friendRequests.map((r) {
      final createdAt = DateTime.fromMillisecondsSinceEpoch(
        r.createdAt.seconds * 1000,
        isUtc: true,
      );
      return {
        'id': r.id,
        'to_friend_code': r.toFriendCode,
        'to_student_name': r.toStudentName,
        'status': r.status,
        'created_at': createdAt,
      };
    }).toList();
  }

  Future<void> sendFriendRequest({
    required String fromStudentUid,
    required String toFriendCode,
    required String toStudentUid,
    required String toStudentName,
  }) async {
    await _connector
        .sendFriendRequest(
          fromStudentUid: fromStudentUid,
          toFriendCode: toFriendCode,
          toStudentUid: toStudentUid,
          toStudentName: toStudentName,
        )
        .execute();
  }

  Future<void> createFriendship({
    required String studentUid,
    required String friendUid,
  }) async {
    await _connector
        .createFriendship(studentUid: studentUid, friendUid: friendUid)
        .execute();
  }

  Future<void> removeFriend(String id) async {
    await _connector.removeFriend(id: id).execute();
  }

  // ── Parent: Friend Request Approval ───────────────────────────────────────

  Future<List<Map<String, dynamic>>> getPendingFriendRequestsForParent(
    String parentUid,
  ) async {
    final result = await _connector
        .getPendingFriendRequestsForParent(parentUid: parentUid)
        .execute();
    return result.data.friendRequests.map((r) {
      final createdAt = DateTime.fromMillisecondsSinceEpoch(
        r.createdAt.seconds * 1000,
        isUtc: true,
      );
      return {
        'id': r.id,
        'from_student_uid': r.fromStudentUid,
        'from_student_name': r.fromStudent.user.fullName,
        'to_friend_code': r.toFriendCode,
        'to_student_name': r.toStudentName,
        'to_student_uid': r.toStudentUid,
        'created_at': createdAt,
      };
    }).toList();
  }

  Future<void> updateFriendRequestStatus({
    required String id,
    required String status,
  }) async {
    await _connector
        .updateFriendRequestStatus(id: id, status: status)
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

  // ── Sibling Leaderboard ───────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getSiblingLeaderboard(
    String parentUid,
  ) async {
    final result = await _connector
        .getSiblingLeaderboard(parentUid: parentUid)
        .execute();
    return result.data.students.map((s) {
      final lastActive = s.lastActiveAt != null
          ? DateTime.fromMillisecondsSinceEpoch(
              s.lastActiveAt!.seconds * 1000,
              isUtc: true,
            )
          : null;
      return {
        'uid': s.uid,
        'username': s.username,
        'weekly_xp': s.weeklyXp ?? 0,
        'total_xp': s.totalXp ?? 0,
        'last_active_at': lastActive,
      };
    }).toList();
  }

  // ── Student Account Deletion (parent-side) ────────────────────────────────

  Future<void> deleteStudentAllData(String studentUid) async {
    // Delete in the correct order (dependents before parents).
    await Future.wait([
      _connector
          .deleteAllOwnedItemsForStudent(studentUid: studentUid)
          .execute(),
      _connector.deleteStudentAvatar(studentUid: studentUid).execute(),
      _connector.deleteStudentSettings(studentUid: studentUid).execute(),
      _connector.deleteStudentConfig(studentUid: studentUid).execute(),
      _connector
          .deleteAllAppRulesForStudent(studentUid: studentUid)
          .execute(),
      _connector
          .deleteAllInstalledAppsForStudent(studentUid: studentUid)
          .execute(),
      _connector
          .deleteAllFriendRequestsByStudent(studentUid: studentUid)
          .execute(),
      _connector
          .deleteAllFriendshipsForStudent(studentUid: studentUid)
          .execute(),
    ]);
    // Delete the student and user rows last.
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
}
