// lib/src/data/providers/dataconnect_provider.dart

import '../../../dataconnect_generated/generated.dart';

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

  /// Returns all app rules for [studentUid] as raw maps.
  Future<List<Map<String, dynamic>>> getAppRulesForStudent(
      String studentUid) async {
    final result = await _connector
        .getAppConfigForStudent(studentUid: studentUid)
        .execute();
    return result.data.appRules
        .map((r) => {
              'id': r.id,
              'package_name': r.packageName,
              'app_label': r.appLabel,
              'usage_hours': r.usageHours,
              'usage_minutes': r.usageMinutes,
              'cooldown_hours': r.cooldownHours,
              'cooldown_minutes': r.cooldownMinutes,
            })
        .toList();
  }

  /// Deletes all existing AppRule rows for [studentUid].
  Future<void> deleteAllAppRulesForStudent(String studentUid) async {
    await _connector
        .deleteAllAppRulesForStudent(studentUid: studentUid)
        .execute();
  }

  // ── Installed-App Inventory ───────────────────────────────────────────────
  //
  // NOTE: These methods call generated connector methods that are created when
  // you run:
  //   firebase deploy --only dataconnect
  //   (then re-run the DataConnect SDK generator / flutterfire configure)
  // Until then, the calls below will produce "method not found" compile errors.

  /// Returns all installed-app rows for [studentUid].
  Future<List<Map<String, dynamic>>> getInstalledAppsForStudent(
      String studentUid) async {
    final result = await _connector
        .getInstalledAppsForStudent(studentUid: studentUid)
        .execute();
    return result.data.installedApps
        .map((a) => {
              'package_name': a.packageName,
              'app_label': a.appLabel,
              'is_system_app': a.isSystemApp,
              'icon_base64': a.iconBase64,
            })
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
    await _connector.insertInstalledApp(
      studentUid: studentUid,
      packageName: packageName,
      appLabel: appLabel,
      isSystemApp: isSystemApp,
    ).iconBase64(iconBase64).execute();
  }

  /// Inserts a single AppRule row.
  Future<void> insertAppRule({
    required String studentUid,
    required String packageName,
    required String appLabel,
    required int usageHours,
    required int usageMinutes,
    required int cooldownHours,
    required int cooldownMinutes,
  }) async {
    await _connector
        .insertAppRule(
          studentUid: studentUid,
          packageName: packageName,
          appLabel: appLabel,
          usageHours: usageHours,
          usageMinutes: usageMinutes,
          cooldownHours: cooldownHours,
          cooldownMinutes: cooldownMinutes,
        )
        .execute();
  }
}
