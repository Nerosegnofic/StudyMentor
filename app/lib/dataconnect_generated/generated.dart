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

part 'update_student_friend_code.dart';

part 'upsert_student_settings.dart';

part 'insert_support_ticket.dart';

part 'upsert_student_config.dart';

part 'get_user_by_uid.dart';

part 'get_students_by_parent.dart';

part 'get_student_with_parent.dart';

part 'get_installed_apps_for_student.dart';

part 'insert_installed_app.dart';

part 'delete_all_installed_apps_for_student.dart';

part 'get_student_profile.dart';

part 'get_student_settings.dart';

part 'get_app_config_for_student.dart';



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
  
  
  UpsertCurrentUserVariablesBuilder upsertCurrentUser ({required String email, required Role role, }) {
    return UpsertCurrentUserVariablesBuilder(dataConnect, email: email,role: role,);
  }
  
  
  DeleteUserVariablesBuilder deleteUser () {
    return DeleteUserVariablesBuilder(dataConnect, );
  }
  
  
  InsertParentVariablesBuilder insertParent () {
    return InsertParentVariablesBuilder(dataConnect, );
  }
  
  
  InsertStudentVariablesBuilder insertStudent ({required String parentUid, }) {
    return InsertStudentVariablesBuilder(dataConnect, parentUid: parentUid,);
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
  
  
  UpdateStudentFriendCodeVariablesBuilder updateStudentFriendCode ({required String friendCode, }) {
    return UpdateStudentFriendCodeVariablesBuilder(dataConnect, friendCode: friendCode,);
  }
  
  
  UpsertStudentSettingsVariablesBuilder upsertStudentSettings ({required String studentUid, required bool notificationsEnabled, required bool soundEffectsEnabled, required bool backgroundMusicEnabled, }) {
    return UpsertStudentSettingsVariablesBuilder(dataConnect, studentUid: studentUid,notificationsEnabled: notificationsEnabled,soundEffectsEnabled: soundEffectsEnabled,backgroundMusicEnabled: backgroundMusicEnabled,);
  }
  
  
  InsertSupportTicketVariablesBuilder insertSupportTicket ({required String userId, required String userName, required String issueType, required String message, }) {
    return InsertSupportTicketVariablesBuilder(dataConnect, userId: userId,userName: userName,issueType: issueType,message: message,);
  }
  
  
  UpsertStudentConfigVariablesBuilder upsertStudentConfig ({required String studentUid, required int usageHours, required int usageMinutes, required int cooldownHours, required int cooldownMinutes, }) {
    return UpsertStudentConfigVariablesBuilder(dataConnect, studentUid: studentUid,usageHours: usageHours,usageMinutes: usageMinutes,cooldownHours: cooldownHours,cooldownMinutes: cooldownMinutes,);
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
  
  
  GetStudentSettingsVariablesBuilder getStudentSettings ({required String studentUid, }) {
    return GetStudentSettingsVariablesBuilder(dataConnect, studentUid: studentUid,);
  }
  
  
  GetAppConfigForStudentVariablesBuilder getAppConfigForStudent ({required String studentUid, }) {
    return GetAppConfigForStudentVariablesBuilder(dataConnect, studentUid: studentUid,);
  }
  

  static ConnectorConfig connectorConfig = ConnectorConfig(
    'us-east1',
    'example',
    'studymentor',
  );

  ExampleConnector({required this.dataConnect});
  static ExampleConnector get instance {
    
    return ExampleConnector(
        dataConnect: FirebaseDataConnect.instanceFor(
            connectorConfig: connectorConfig,
            
            sdkType: CallerSDKType.generated));
  }

  FirebaseDataConnect dataConnect;
}
