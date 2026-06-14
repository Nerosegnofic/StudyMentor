library dataconnect_generated;
import 'package:firebase_data_connect/firebase_data_connect.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

part 'insert_user.dart';

part 'upsert_current_user.dart';

part 'delete_user.dart';

part 'insert_parent.dart';

part 'insert_student.dart';

part 'set_user_inactive.dart';

part 'mark_email_verified.dart';

part 'insert_app_rule.dart';

part 'delete_all_app_rules_for_student.dart';

part 'upsert_student_settings.dart';

part 'insert_support_ticket.dart';

part 'insert_student_owned_item.dart';

part 'upsert_student_avatar.dart';

part 'delete_all_owned_items_for_student.dart';

part 'delete_student_avatar.dart';

part 'delete_student_settings.dart';

part 'delete_student_config.dart';

part 'delete_student_record.dart';

part 'delete_user_record.dart';

part 'update_student_full_name.dart';

part 'delete_parent_record.dart';

part 'upsert_student_config.dart';

part 'upsert_subject_progress.dart';

part 'delete_subject_progress.dart';

part 'insert_local_notification_event.dart';

part 'mark_local_notification_events_read.dart';

part 'upsert_local_notification_preference.dart';

part 'delete_local_notification_preferences_for_user.dart';

part 'get_user_by_uid.dart';

part 'get_students_by_parent.dart';

part 'get_student_with_parent.dart';

part 'get_installed_apps_for_student.dart';

part 'insert_installed_app.dart';

part 'delete_all_installed_apps_for_student.dart';

part 'get_student_profile.dart';

part 'get_student_by_username.dart';

part 'get_student_settings.dart';

part 'get_student_owned_items.dart';

part 'get_student_avatar.dart';

part 'get_app_config_for_student.dart';

part 'get_all_subject_progress.dart';

part 'get_unread_local_notification_events.dart';

part 'get_local_notification_preferences.dart';



  enum Role {
    
      Parent,
    
      Student,
    
  }
  
  String roleSerializer(EnumValue<Role> e) {
    return e.stringValue;
  }
  EnumValue<Role> roleDeserializer(dynamic data) {
    switch (data) {
      
      case 'Parent':
        return const Known(Role.Parent);
      
      case 'Student':
        return const Known(Role.Student);
      
      default:
        return Unknown(data);
    }
  }
  



String enumSerializer(Enum e) {
  return e.name;
}



/// A sealed class representing either a known enum value or an unknown string value.
@immutable
sealed class EnumValue<T extends Enum> {
  const EnumValue();

  

  /// The string representation of the value.
  String get stringValue;
  @override
  String toString() {
    return "EnumValue($stringValue)";
  }
}

/// Represents a known, valid enum value.
class Known<T extends Enum> extends EnumValue<T> {
  /// The actual enum value.
  final T value;

  const Known(this.value);

  @override
  String get stringValue => value.name;

  @override
  String toString() {
    return "Known($stringValue)";
  }
}
/// Represents an unknown or unrecognized enum value.
class Unknown extends EnumValue<Never> {
  /// The raw string value that couldn't be mapped to a known enum.
  @override
  final String stringValue;

  const Unknown(this.stringValue);
  @override
  String toString() {
    return "Unknown($stringValue)";
  }
}

class ExampleConnector {
  
  
  InsertUserVariablesBuilder insertUser ({required String email, required String fullName, required Role role, }) {
    return InsertUserVariablesBuilder(dataConnect, email: email,fullName: fullName,role: role,);
  }
  
  
  UpsertCurrentUserVariablesBuilder upsertCurrentUser ({required Role role, }) {
    return UpsertCurrentUserVariablesBuilder(dataConnect, role: role,);
  }
  
  
  DeleteUserVariablesBuilder deleteUser () {
    return DeleteUserVariablesBuilder(dataConnect, );
  }
  
  
  InsertParentVariablesBuilder insertParent () {
    return InsertParentVariablesBuilder(dataConnect, );
  }
  
  
  InsertStudentVariablesBuilder insertStudent ({required String parentUid, required String username, }) {
    return InsertStudentVariablesBuilder(dataConnect, parentUid: parentUid,username: username,);
  }
  
  
  SetUserInactiveVariablesBuilder setUserInactive () {
    return SetUserInactiveVariablesBuilder(dataConnect, );
  }
  
  
  MarkEmailVerifiedVariablesBuilder markEmailVerified () {
    return MarkEmailVerifiedVariablesBuilder(dataConnect, );
  }
  
  
  InsertAppRuleVariablesBuilder insertAppRule ({required String studentUid, required String packageName, required String appLabel, }) {
    return InsertAppRuleVariablesBuilder(dataConnect, studentUid: studentUid,packageName: packageName,appLabel: appLabel,);
  }
  
  
  DeleteAllAppRulesForStudentVariablesBuilder deleteAllAppRulesForStudent ({required String studentUid, }) {
    return DeleteAllAppRulesForStudentVariablesBuilder(dataConnect, studentUid: studentUid,);
  }
  
  
  UpsertStudentSettingsVariablesBuilder upsertStudentSettings ({required String studentUid, required bool notificationsEnabled, required bool soundEffectsEnabled, required bool backgroundMusicEnabled, }) {
    return UpsertStudentSettingsVariablesBuilder(dataConnect, studentUid: studentUid,notificationsEnabled: notificationsEnabled,soundEffectsEnabled: soundEffectsEnabled,backgroundMusicEnabled: backgroundMusicEnabled,);
  }
  
  
  InsertSupportTicketVariablesBuilder insertSupportTicket ({required String userId, required String userName, required String issueType, required String message, }) {
    return InsertSupportTicketVariablesBuilder(dataConnect, userId: userId,userName: userName,issueType: issueType,message: message,);
  }
  
  
  InsertStudentOwnedItemVariablesBuilder insertStudentOwnedItem ({required String studentUid, required String itemId, }) {
    return InsertStudentOwnedItemVariablesBuilder(dataConnect, studentUid: studentUid,itemId: itemId,);
  }
  
  
  UpsertStudentAvatarVariablesBuilder upsertStudentAvatar ({required String studentUid, required String gender, required String skinTone, }) {
    return UpsertStudentAvatarVariablesBuilder(dataConnect, studentUid: studentUid,gender: gender,skinTone: skinTone,);
  }
  
  
  DeleteAllOwnedItemsForStudentVariablesBuilder deleteAllOwnedItemsForStudent ({required String studentUid, }) {
    return DeleteAllOwnedItemsForStudentVariablesBuilder(dataConnect, studentUid: studentUid,);
  }
  
  
  DeleteStudentAvatarVariablesBuilder deleteStudentAvatar ({required String studentUid, }) {
    return DeleteStudentAvatarVariablesBuilder(dataConnect, studentUid: studentUid,);
  }
  
  
  DeleteStudentSettingsVariablesBuilder deleteStudentSettings ({required String studentUid, }) {
    return DeleteStudentSettingsVariablesBuilder(dataConnect, studentUid: studentUid,);
  }
  
  
  DeleteStudentConfigVariablesBuilder deleteStudentConfig ({required String studentUid, }) {
    return DeleteStudentConfigVariablesBuilder(dataConnect, studentUid: studentUid,);
  }
  
  
  DeleteStudentRecordVariablesBuilder deleteStudentRecord ({required String uid, }) {
    return DeleteStudentRecordVariablesBuilder(dataConnect, uid: uid,);
  }
  
  
  DeleteUserRecordVariablesBuilder deleteUserRecord ({required String uid, }) {
    return DeleteUserRecordVariablesBuilder(dataConnect, uid: uid,);
  }
  
  
  UpdateStudentFullNameVariablesBuilder updateStudentFullName ({required String uid, required String fullName, }) {
    return UpdateStudentFullNameVariablesBuilder(dataConnect, uid: uid,fullName: fullName,);
  }
  
  
  DeleteParentRecordVariablesBuilder deleteParentRecord () {
    return DeleteParentRecordVariablesBuilder(dataConnect, );
  }
  
  
  UpsertStudentConfigVariablesBuilder upsertStudentConfig ({required String studentUid, required int usageHours, required int usageMinutes, required int cooldownHours, required int cooldownMinutes, required String quizCount, }) {
    return UpsertStudentConfigVariablesBuilder(dataConnect, studentUid: studentUid,usageHours: usageHours,usageMinutes: usageMinutes,cooldownHours: cooldownHours,cooldownMinutes: cooldownMinutes,quizCount: quizCount,);
  }
  
  
  UpsertSubjectProgressVariablesBuilder upsertSubjectProgress ({required String studentUid, required String subjectKey, required int totalXp, required int level, }) {
    return UpsertSubjectProgressVariablesBuilder(dataConnect, studentUid: studentUid,subjectKey: subjectKey,totalXp: totalXp,level: level,);
  }
  
  
  DeleteSubjectProgressVariablesBuilder deleteSubjectProgress ({required String studentUid, required String subjectKey, }) {
    return DeleteSubjectProgressVariablesBuilder(dataConnect, studentUid: studentUid,subjectKey: subjectKey,);
  }
  
  
  InsertLocalNotificationEventVariablesBuilder insertLocalNotificationEvent ({required String fromStudentUid, required String toParentUid, required String eventType, required String payload, }) {
    return InsertLocalNotificationEventVariablesBuilder(dataConnect, fromStudentUid: fromStudentUid,toParentUid: toParentUid,eventType: eventType,payload: payload,);
  }
  
  
  MarkLocalNotificationEventsReadVariablesBuilder markLocalNotificationEventsRead ({required String toParentUid, }) {
    return MarkLocalNotificationEventsReadVariablesBuilder(dataConnect, toParentUid: toParentUid,);
  }
  
  
  UpsertLocalNotificationPreferenceVariablesBuilder upsertLocalNotificationPreference ({required String userUid, required String category, required bool enabled, }) {
    return UpsertLocalNotificationPreferenceVariablesBuilder(dataConnect, userUid: userUid,category: category,enabled: enabled,);
  }
  
  
  DeleteLocalNotificationPreferencesForUserVariablesBuilder deleteLocalNotificationPreferencesForUser ({required String userUid, }) {
    return DeleteLocalNotificationPreferencesForUserVariablesBuilder(dataConnect, userUid: userUid,);
  }
  
  
  GetUserByUidVariablesBuilder getUserByUid ({required String uid, }) {
    return GetUserByUidVariablesBuilder(dataConnect, uid: uid,);
  }
  
  
  GetStudentsByParentVariablesBuilder getStudentsByParent ({required String parentUid, }) {
    return GetStudentsByParentVariablesBuilder(dataConnect, parentUid: parentUid,);
  }
  
  
  GetStudentWithParentVariablesBuilder getStudentWithParent ({required String uid, }) {
    return GetStudentWithParentVariablesBuilder(dataConnect, uid: uid,);
  }
  
  
  GetInstalledAppsForStudentVariablesBuilder getInstalledAppsForStudent ({required String studentUid, }) {
    return GetInstalledAppsForStudentVariablesBuilder(dataConnect, studentUid: studentUid,);
  }
  
  
  InsertInstalledAppVariablesBuilder insertInstalledApp ({required String studentUid, required String packageName, required String appLabel, required bool isSystemApp, }) {
    return InsertInstalledAppVariablesBuilder(dataConnect, studentUid: studentUid,packageName: packageName,appLabel: appLabel,isSystemApp: isSystemApp,);
  }
  
  
  DeleteAllInstalledAppsForStudentVariablesBuilder deleteAllInstalledAppsForStudent ({required String studentUid, }) {
    return DeleteAllInstalledAppsForStudentVariablesBuilder(dataConnect, studentUid: studentUid,);
  }
  
  
  GetStudentProfileVariablesBuilder getStudentProfile ({required String uid, }) {
    return GetStudentProfileVariablesBuilder(dataConnect, uid: uid,);
  }
  
  
  GetStudentByUsernameVariablesBuilder getStudentByUsername ({required String username, }) {
    return GetStudentByUsernameVariablesBuilder(dataConnect, username: username,);
  }
  
  
  GetStudentSettingsVariablesBuilder getStudentSettings ({required String studentUid, }) {
    return GetStudentSettingsVariablesBuilder(dataConnect, studentUid: studentUid,);
  }
  
  
  GetStudentOwnedItemsVariablesBuilder getStudentOwnedItems ({required String studentUid, }) {
    return GetStudentOwnedItemsVariablesBuilder(dataConnect, studentUid: studentUid,);
  }
  
  
  GetStudentAvatarVariablesBuilder getStudentAvatar ({required String studentUid, }) {
    return GetStudentAvatarVariablesBuilder(dataConnect, studentUid: studentUid,);
  }
  
  
  GetAppConfigForStudentVariablesBuilder getAppConfigForStudent ({required String studentUid, }) {
    return GetAppConfigForStudentVariablesBuilder(dataConnect, studentUid: studentUid,);
  }
  
  
  GetAllSubjectProgressVariablesBuilder getAllSubjectProgress ({required String studentUid, }) {
    return GetAllSubjectProgressVariablesBuilder(dataConnect, studentUid: studentUid,);
  }
  
  
  GetUnreadLocalNotificationEventsVariablesBuilder getUnreadLocalNotificationEvents ({required String toParentUid, }) {
    return GetUnreadLocalNotificationEventsVariablesBuilder(dataConnect, toParentUid: toParentUid,);
  }
  
  
  GetLocalNotificationPreferencesVariablesBuilder getLocalNotificationPreferences ({required String userUid, }) {
    return GetLocalNotificationPreferencesVariablesBuilder(dataConnect, userUid: userUid,);
  }
  

  static ConnectorConfig connectorConfig = ConnectorConfig(
    'me-west1',
    'example',
    'studymentor-2026-service',
  );

  ExampleConnector({required this.dataConnect});
  static ExampleConnector get instance {
    
    CacheSettings cacheSettings = CacheSettings(
      maxAge: Duration(milliseconds:0),
      storage: CacheStorage.persistent,
    );
    
    return ExampleConnector(
        dataConnect: FirebaseDataConnect.instanceFor(
            connectorConfig: connectorConfig,
            
            cacheSettings: cacheSettings,
            
            sdkType: CallerSDKType.generated));
  }

  FirebaseDataConnect dataConnect;
}
