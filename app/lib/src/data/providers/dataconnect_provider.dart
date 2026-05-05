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
}
