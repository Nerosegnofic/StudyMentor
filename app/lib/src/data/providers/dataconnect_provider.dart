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

  Future<void> createStudentProfile({
    required String parentUid,
    required int gradeLevel,
  }) async {
    await _connector
        .insertStudent(parentUid: parentUid)
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

  /// Returns the global student config and all app rules for [studentUid].
  /// The config is null if the parent hasn't saved one yet — callers should
  /// fall back to [StudentConfigModel] defaults in that case.
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
            'icon_base64': r.iconBase64,
          },
        )
        .toList();

    return (config: config, rules: rules);
  }

  /// Deletes all existing AppRule rows for [studentUid].
  Future<void> deleteAllAppRulesForStudent(String studentUid) async {
    await _connector
        .deleteAllAppRulesForStudent(studentUid: studentUid)
        .execute();
  }

  /// Inserts a single AppRule row (no time fields).
  Future<void> insertAppRule({
    required String studentUid,
    required String packageName,
    required String appLabel,
    String? iconBase64,
  }) async {
    await _connector
        .insertAppRule(
          studentUid: studentUid,
          packageName: packageName,
          appLabel: appLabel,
        )
        .iconBase64(iconBase64)
        .execute();
  }

  /// Upserts the global usage/cooldown config for [studentUid].
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

  /// Returns all installed-app rows for [studentUid].
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
            'icon_base64': a.iconBase64,
          },
        )
        .toList();
  }

  /// Deletes all installed-app rows for [studentUid].
  Future<void> deleteAllInstalledAppsForStudent(String studentUid) async {
    await _connector
        .deleteAllInstalledAppsForStudent(studentUid: studentUid)
        .execute();
  }

  /// Inserts a single installed-app row.
  Future<void> insertInstalledApp({
    required String studentUid,
    required String packageName,
    required String appLabel,
    required bool isSystemApp,
    String? iconBase64,
  }) async {
    await _connector
        .insertInstalledApp(
          studentUid: studentUid,
          packageName: packageName,
          appLabel: appLabel,
          isSystemApp: isSystemApp,
        )
        .iconBase64(iconBase64)
        .execute();
  }

  // ── Student Profile ───────────────────────────────────────────────────────

  /// Returns profile data for [uid]: friendCode, totalXp, totalCoins, gradeLevel,
  /// totalQuestionsAnswered, currentStreak.
  Future<Map<String, dynamic>> getStudentProfile(String uid) async {
    final result = await _connector.getStudentProfile(uid: uid).execute();
    final s = result.data.student;
    if (s == null) throw Exception('Student not found');
    return {
      'uid': s.uid,
      'friend_code': s.friendCode,
      'total_xp': s.totalXp,
      'total_coins': s.totalCoins,
      'grade_level': s.gradeLevel,
      'total_questions_answered': s.totalQuestionsAnswered,
      'current_streak': s.currentStreak,
    };
  }

  /// Sets (or updates) the friend code on the currently-authenticated student.
  Future<void> updateStudentFriendCode(String friendCode) async {
    await _connector
        .updateStudentFriendCode(friendCode: friendCode)
        .execute();
  }

  // ── Student Settings ──────────────────────────────────────────────────────

  /// Returns the stored settings for [studentUid], or null if never saved.
  Future<Map<String, dynamic>?> getStudentSettings(String studentUid) async {
    final result =
        await _connector.getStudentSettings(studentUid: studentUid).execute();
    final s = result.data.studentSettings;
    if (s == null) return null;
    return {
      'notifications_enabled': s.notificationsEnabled,
      'sound_effects_enabled': s.soundEffectsEnabled,
      'background_music_enabled': s.backgroundMusicEnabled,
    };
  }

  /// Upserts the app preferences for [studentUid].
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

  /// Returns all students sorted by weeklyXp DESC for the global leaderboard.
  Future<List<Map<String, dynamic>>> getWeeklyLeaderboard() async {
    final result = await _connector.getWeeklyLeaderboard().execute();
    return result.data.students.map((s) {
      final lastActive = s.lastActiveAt != null
          ? DateTime.fromMillisecondsSinceEpoch(s.lastActiveAt!.seconds * 1000, isUtc: true)
          : null;
      return {
        'uid': s.uid,
        'full_name': s.user.fullName,
        'weekly_xp': s.weeklyXp ?? 0,
        'total_xp': s.totalXp ?? 0,
        'last_active_at': lastActive,
      };
    }).toList();
  }

  /// Stamps the current student's lastActiveAt to now (heartbeat).
  Future<void> updateLastActiveAt() async {
    await _connector.updateLastActiveAt().execute();
  }

  // ── Friends ───────────────────────────────────────────────────────────────

  /// Returns all accepted friends for [studentUid] with profile info.
  Future<List<Map<String, dynamic>>> getFriendsForStudent(String studentUid) async {
    final result = await _connector.getFriendsForStudent(studentUid: studentUid).execute();
    return result.data.friendships.map((f) {
      final lastActive = f.friend.lastActiveAt != null
          ? DateTime.fromMillisecondsSinceEpoch(f.friend.lastActiveAt!.seconds * 1000, isUtc: true)
          : null;
      return {
        'friendship_id': f.id,
        'friend_uid': f.friendUid,
        'full_name': f.friend.user.fullName,
        'total_xp': f.friend.totalXp ?? 0,
        'weekly_xp': f.friend.weeklyXp ?? 0,
        'last_active_at': lastActive,
      };
    }).toList();
  }

  /// Looks up a student by their friend code. Returns null if not found.
  Future<Map<String, dynamic>?> getStudentByFriendCode(String friendCode) async {
    final result = await _connector.getStudentByFriendCode(friendCode: friendCode).execute();
    if (result.data.students.isEmpty) return null;
    final s = result.data.students.first;
    return {
      'uid': s.uid,
      'full_name': s.user.fullName,
      'friend_code': s.friendCode,
    };
  }

  /// Returns all pending friend requests sent by [fromStudentUid].
  Future<List<Map<String, dynamic>>> getSentFriendRequests(String fromStudentUid) async {
    final result = await _connector.getSentFriendRequests(fromStudentUid: fromStudentUid).execute();
    return result.data.friendRequests.map((r) {
      final createdAt = DateTime.fromMillisecondsSinceEpoch(r.createdAt.seconds * 1000, isUtc: true);
      return {
        'id': r.id,
        'to_friend_code': r.toFriendCode,
        'to_student_name': r.toStudentName,
        'status': r.status,
        'created_at': createdAt,
      };
    }).toList();
  }

  /// Sends a friend request.
  Future<void> sendFriendRequest({
    required String fromStudentUid,
    required String toFriendCode,
    required String toStudentUid,
    required String toStudentName,
  }) async {
    await _connector.sendFriendRequest(
      fromStudentUid: fromStudentUid,
      toFriendCode: toFriendCode,
      toStudentUid: toStudentUid,
      toStudentName: toStudentName,
    ).execute();
  }

  /// Creates one directional friendship row. Call twice for mutual friendship.
  Future<void> createFriendship({
    required String studentUid,
    required String friendUid,
  }) async {
    await _connector.createFriendship(studentUid: studentUid, friendUid: friendUid).execute();
  }

  /// Removes a friendship by its ID.
  Future<void> removeFriend(String id) async {
    await _connector.removeFriend(id: id).execute();
  }

  // ── Parent: Friend Request Approval ───────────────────────────────────────

  /// Returns all pending friend requests for all students belonging to [parentUid].
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

  /// Updates the status of a friend request (e.g., 'accepted' or 'rejected').
  Future<void> updateFriendRequestStatus({
    required String id,
    required String status,
  }) async {
    await _connector
        .updateFriendRequestStatus(id: id, status: status)
        .execute();
  }

  // ── Support Tickets ───────────────────────────────────────────────────────

  /// Inserts a support ticket from the Help Center.
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
